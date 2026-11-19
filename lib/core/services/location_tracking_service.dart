import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../../ui/features/auth/data/sources/local/local_auth_source_impl.dart';

enum AgentTrackingStatus {
  inOffice,
  onFieldVisit,
  offDuty,
}

class LocationTrackingService {
  LocationTrackingService._();
  static final LocationTrackingService instance = LocationTrackingService._();

  // Office Configuration: Plot No-2, Dalmia Farm, Jonapur, New Delhi 110047
  static const double officeLatitude = 28.4624272;
  static const double officeLongitude = 77.1515298;
  static const double geofenceRadiusMeters = 200.0;

  // Working Hours (10:00 AM to 07:00 PM)
  static const int shiftStartHour = 10;
  static const int shiftEndHour = 19;

  final Dio _dio = Dio();
  Timer? _periodicTimer;
  StreamSubscription<Position>? _positionStreamSub;
  bool _isTracking = false;

  AgentTrackingStatus _currentStatus = AgentTrackingStatus.offDuty;
  double _lastDistanceMeters = 0.0;
  Position? _lastPosition;

  AgentTrackingStatus get currentStatus => _currentStatus;
  double get lastDistanceMeters => _lastDistanceMeters;
  Position? get lastPosition => _lastPosition;
  bool get isTracking => _isTracking;

  final ValueNotifier<AgentTrackingStatus> statusNotifier =
      ValueNotifier<AgentTrackingStatus>(AgentTrackingStatus.offDuty);

  /// Initializes permissions and starts periodic tracking
  Future<void> startTracking() async {
    if (_isTracking) return;

    try {
      final currentUser = await LocalAuthSourceImpl().getCurrentUser();
      if (currentUser != null && currentUser.isExecutive) {
        debugPrint('👑 [LocationTracking] Executive/Director account (${currentUser.fullName}) - GPS tracking completely disabled.');
        return;
      }
    } catch (_) {}

    final hasPermission = await _requestLocationPermission();
    if (!hasPermission) {
      debugPrint('🚨 [LocationTracking] Location permission not granted');
      return;
    }

    _isTracking = true;
    debugPrint('📍 [LocationTracking] Service started for Office (Jonapur)');

    // 1. Initial Immediate Fix
    await _captureAndSyncLocation();

    // 2. Periodic Timer (Every 2 minutes)
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _captureAndSyncLocation();
    });

    // 3. Movement-based triggers (every 50 meters)
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50,
    );
    _positionStreamSub?.cancel();
    _positionStreamSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (position) {
        _processPosition(position);
      },
      onError: (e) {
        debugPrint('⚠️ [LocationTracking] Position stream error: $e');
      },
    );
  }

  /// Stops tracking (e.g. on user logout)
  void stopTracking() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _positionStreamSub?.cancel();
    _positionStreamSub = null;
    _isTracking = false;
    _currentStatus = AgentTrackingStatus.offDuty;
    statusNotifier.value = AgentTrackingStatus.offDuty;
    debugPrint('🛑 [LocationTracking] Service stopped');
  }

  /// Checks if current local time is within shift (10:00 AM - 07:00 PM)
  bool isWithinShiftHours() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final timeInMinutes = hour * 60 + minute;

    // 10:00 AM = 600 mins, 7:00 PM = 1140 mins
    return timeInMinutes >= (shiftStartHour * 60) && timeInMinutes <= (shiftEndHour * 60);
  }

  /// Captures single GPS position and syncs to backend
  Future<void> _captureAndSyncLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      await _processPosition(position);
    } catch (e) {
      debugPrint('⚠️ [LocationTracking] Error getting current position: $e');
    }
  }

  /// Processes position, evaluates geofence, and transmits ping
  Future<void> _processPosition(Position position) async {
    _lastPosition = position;

    final distance = Geolocator.distanceBetween(
      officeLatitude,
      officeLongitude,
      position.latitude,
      position.longitude,
    );
    _lastDistanceMeters = distance;

    if (distance <= geofenceRadiusMeters) {
      _currentStatus = AgentTrackingStatus.inOffice;
    } else {
      _currentStatus = AgentTrackingStatus.onFieldVisit;
    }

    statusNotifier.value = _currentStatus;
    debugPrint(
      '📍 [LocationTracking] Fix: (${position.latitude}, ${position.longitude}) | '
      'Dist to Jonapur Office: ${distance.toStringAsFixed(1)}m | '
      'Status: ${_currentStatus.name.toUpperCase()}',
    );

    // Sync to backend
    await _sendPingToBackend(position, distance, _currentStatus);
  }

  static final Map<String, Map<String, dynamic>> _latestAgentTelemetry = {};

  static Map<String, dynamic>? getLatestTelemetryForAgent(String agentName, String? employeeId) {
    final cleanName = agentName.trim().toLowerCase();
    final cleanEmp = employeeId?.trim().toLowerCase();

    for (final entry in _latestAgentTelemetry.entries) {
      final key = entry.key.toLowerCase();
      if (key.contains(cleanName) || (cleanEmp != null && cleanEmp.isNotEmpty && key.contains(cleanEmp))) {
        return entry.value;
      }
    }
    return null;
  }

  /// Sends location ping to backend
  Future<void> _sendPingToBackend(
    Position position,
    double distanceMeters,
    AgentTrackingStatus status,
  ) async {
    final user = await LocalAuthSourceImpl().getCurrentUser();
    if (user == null) {
      debugPrint('⚠️ [LocationTracking] No logged-in user, skipping sync');
      return;
    }

    final payload = {
      'agentId': user.id,
      'agentName': user.fullName,
      'employeeId': user.employeeId ?? '',
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'speed': position.speed,
      'distanceFromOfficeMeters': distanceMeters.round(),
      'status': status == AgentTrackingStatus.inOffice
          ? 'IN_OFFICE'
          : status == AgentTrackingStatus.onFieldVisit
              ? 'ON_FIELD_VISIT'
              : 'OFF_DUTY',
      'timestamp': DateTime.now().toIso8601String(),
    };

    _latestAgentTelemetry[user.id] = payload;
    _latestAgentTelemetry[user.fullName] = payload;
    if (user.employeeId != null && user.employeeId!.isNotEmpty) {
      _latestAgentTelemetry[user.employeeId!] = payload;
    }

    final endpoints = [
      'https://ssrealty.org/api/mobile/tracking/ping',
      if (ApiConstants.baseUrl != 'https://ssrealty.org/api/mobile')
        '${ApiConstants.baseUrl}/tracking/ping',
    ];

    for (final url in endpoints) {
      try {
        final response = await _dio.post(
          url,
          data: payload,
          options: Options(
            sendTimeout: const Duration(seconds: 4),
            receiveTimeout: const Duration(seconds: 4),
          ),
        );
        if (response.statusCode == 200) {
          debugPrint('✅ [LocationTracking] Ping synced successfully to $url');
          break;
        }
      } catch (_) {
        // Try next fallback endpoint
      }
    }
  }

  /// Requests runtime GPS and Background Location permissions
  Future<bool> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('🚨 Location services are disabled.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('🚨 Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('🚨 Location permissions are permanently denied.');
      return false;
    }

    return true;
  }
}
