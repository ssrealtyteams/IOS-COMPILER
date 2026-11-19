import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/result.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/location_tracking_service.dart';
import '../../../../core/services/attendance_record_service.dart';
import '../../../../domain/entities/user.dart';
import '../../auth/data/sources/local/local_auth_source_impl.dart';

class DashboardStats {
  const DashboardStats({
    required this.totalCalls,
    required this.connectedCalls,
    required this.missedCalls,
    required this.interestedLeads,
    required this.hotLeads,
    required this.pendingFollowups,
    required this.completedFollowups,
    required this.scheduledVisits,
    required this.completedVisits,
    required this.conversions,
    required this.manualCalls,
    required this.uniqueCalls,
    required this.totalBookingAmount,
    this.callsChart = const [],
  });

  final int totalCalls;
  final int connectedCalls;
  final int missedCalls;
  final int interestedLeads;
  final int hotLeads;
  final int pendingFollowups;
  final int completedFollowups;
  final int scheduledVisits;
  final int completedVisits;
  final int conversions;
  final int manualCalls;
  final int uniqueCalls;
  final double totalBookingAmount;
  final List<DailyCallData> callsChart;

  DashboardStats copyWith({
    int? totalCalls,
    int? connectedCalls,
    int? missedCalls,
    int? interestedLeads,
    int? hotLeads,
    int? pendingFollowups,
    int? completedFollowups,
    int? scheduledVisits,
    int? completedVisits,
    int? conversions,
    int? manualCalls,
    int? uniqueCalls,
    double? totalBookingAmount,
    List<DailyCallData>? callsChart,
  }) {
    return DashboardStats(
      totalCalls: totalCalls ?? this.totalCalls,
      connectedCalls: connectedCalls ?? this.connectedCalls,
      missedCalls: missedCalls ?? this.missedCalls,
      interestedLeads: interestedLeads ?? this.interestedLeads,
      hotLeads: hotLeads ?? this.hotLeads,
      pendingFollowups: pendingFollowups ?? this.pendingFollowups,
      completedFollowups: completedFollowups ?? this.completedFollowups,
      scheduledVisits: scheduledVisits ?? this.scheduledVisits,
      completedVisits: completedVisits ?? this.completedVisits,
      conversions: conversions ?? this.conversions,
      manualCalls: manualCalls ?? this.manualCalls,
      uniqueCalls: uniqueCalls ?? this.uniqueCalls,
      totalBookingAmount: totalBookingAmount ?? this.totalBookingAmount,
      callsChart: callsChart ?? this.callsChart,
    );
  }

  static const DashboardStats empty = DashboardStats(
    totalCalls: 0,
    connectedCalls: 0,
    missedCalls: 0,
    interestedLeads: 0,
    hotLeads: 0,
    pendingFollowups: 0,
    completedFollowups: 0,
    scheduledVisits: 0,
    completedVisits: 0,
    conversions: 0,
    manualCalls: 0,
    uniqueCalls: 0,
    totalBookingAmount: 0.0,
    callsChart: [
      DailyCallData(date: 'Mon', total: 0, connected: 0),
      DailyCallData(date: 'Tue', total: 0, connected: 0),
      DailyCallData(date: 'Wed', total: 0, connected: 0),
      DailyCallData(date: 'Thu', total: 0, connected: 0),
      DailyCallData(date: 'Fri', total: 0, connected: 0),
      DailyCallData(date: 'Sat', total: 0, connected: 0),
      DailyCallData(date: 'Sun', total: 0, connected: 0),
    ],
  );
}

class DailyCallData {
  const DailyCallData({
    required this.date,
    required this.total,
    required this.connected,
  });

  final String date;
  final int total;
  final int connected;
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.agentName,
    required this.calls,
    required this.bookings,
    required this.totalBookingAmount,
    this.employeeId,
    this.avatarUrl,
  });

  final int rank;
  final String agentName;
  final int calls;
  final int bookings;
  final double totalBookingAmount;
  final String? employeeId;
  final String? avatarUrl;
}

class BookingItemData {
  final String projectName;
  final String location;
  final String unitType;
  final String amount;
  final String downpayment;
  final String clientName;
  final String phone;
  final String date;

  const BookingItemData({
    required this.projectName,
    required this.location,
    required this.unitType,
    required this.amount,
    required this.downpayment,
    required this.clientName,
    required this.phone,
    required this.date,
  });
}

enum DashboardPeriod { today, week, month }

@injectable
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel() {
    _loadLocalAttendanceState();
  }

  static const _kPunchInKey = 'attendance_is_punched_in';
  static const _kPunchInDateKey = 'attendance_last_punch_date';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  static const List<LeaderboardEntry> initialTeamLeaderboard = [];

  ViewState _state = const ViewState.initial();
  ViewState get state => _state;

  DashboardStats _stats = DashboardStats.empty;
  DashboardStats get stats => _stats;

  List<LeaderboardEntry> _leaderboard = [];
  List<LeaderboardEntry> get leaderboard => _leaderboard;

  List<BookingItemData> _bookings = [];
  List<BookingItemData> get bookings => _bookings;

  DashboardPeriod _period = DashboardPeriod.today;
  DashboardPeriod get period => _period;

  String _agentName = 'Agent';
  String get agentName => _agentName;

  String _agentId = 'SSR001';
  String get agentId => _agentId;

  String? _rawUserId;

  // ─── Attendance & Geofence State ───────────────────────────────────────────
  static bool _globalIsPunchedIn = false;
  bool get isPunchedIn => isExecutive || _globalIsPunchedIn;

  String? _attendanceError;
  String? get attendanceError => _attendanceError;

  bool _isPunchingIn = false;
  bool get isPunchingIn => _isPunchingIn;

  bool _isPunchingOut = false;
  bool get isPunchingOut => _isPunchingOut;

  bool _isSyncingStatus = false;
  bool get isSyncingStatus => _isSyncingStatus;

  double _officeLat = 28.4624272;
  double get officeLat => _officeLat;

  double _officeLng = 77.1515298;
  double get officeLng => _officeLng;

  double _allowedRadiusInMeters = 200.0;
  double get allowedRadiusInMeters => _allowedRadiusInMeters;

  String _officeAddress = 'Dalmia farm, Plot no-2, Jona Pur, Jaunapur, New Delhi, Delhi 110047';
  String get officeAddress => _officeAddress;

  bool _isGeofenceRequired = false;
  bool get isGeofenceRequired => _isGeofenceRequired;

  bool _geofenceEnabled = false;
  bool get geofenceEnabled => _geofenceEnabled;

  bool _isAgentRemoteExempted = false;
  bool get isAgentRemoteExempted => _isAgentRemoteExempted;

  double? _lastMeasuredDistance;
  double? get lastMeasuredDistance => _lastMeasuredDistance;

  List<String> _getEndpoints(String path) {
    return [
      'https://ssrealty.org/api/mobile$path',
      if (ApiConstants.baseUrl != 'https://ssrealty.org/api/mobile')
        '${ApiConstants.baseUrl}$path',
      'http://10.246.64.152:3000/api/mobile$path',
    ];
  }

  bool _isExecutive = false;
  bool get isExecutive =>
      _isExecutive ||
      LocalAuthSourceImpl.isDirectorOrExecutive ||
      (LocalAuthSourceImpl.inMemoryCachedUser?.isExecutive ?? false) ||
      (LocalAuthSourceImpl.inMemoryCachedUser?.email?.toLowerCase() == 'info@ssrealty.org') ||
      (LocalAuthSourceImpl.inMemoryCachedUser?.employeeId?.toUpperCase() == 'SSR000');

  void setUser(User user) {
    _agentName = user.fullName;
    _agentId = user.employeeId ?? user.id;
    _rawUserId = user.id;
    _isExecutive = user.isExecutive || user.isDirector || (user.email?.toLowerCase() == 'info@ssrealty.org') || (user.employeeId?.toUpperCase() == 'SSR000');
    if (_isExecutive) {
      _isAgentRemoteExempted = true;
      _isGeofenceRequired = false;
      _globalIsPunchedIn = true;
    } else {
      _isAgentRemoteExempted = true; // Allow punch in from anywhere (office or outside)
      _isGeofenceRequired = false;
      _loadLocalAttendanceState();
    }
    notifyListeners();
  }

  Future<void> _loadLocalAttendanceState() async {
    try {
      final user = await LocalAuthSourceImpl().getCurrentUser();
      if (user != null) {
        _agentName = user.fullName;
        _agentId = user.employeeId ?? user.id;
        _rawUserId = user.id;
        _isExecutive = user.isExecutive || user.isDirector || (user.email?.toLowerCase() == 'info@ssrealty.org') || (user.employeeId?.toUpperCase() == 'SSR000');
        if (_isExecutive) {
          _isAgentRemoteExempted = true;
          _isGeofenceRequired = false;
          _globalIsPunchedIn = true;
          notifyListeners();
          return;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final userKey = 'attendance_is_punched_in_${_rawUserId ?? _agentId}_$todayStr';
      final savedPunchedIn = prefs.getBool(userKey) ?? false;

      _globalIsPunchedIn = savedPunchedIn;
      _isAgentRemoteExempted = true;
      _isGeofenceRequired = false;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveLocalAttendanceState(bool punchedIn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final userKey = 'attendance_is_punched_in_${_rawUserId ?? _agentId}_$todayStr';
      await prefs.setBool(userKey, punchedIn);
      await prefs.setBool(_kPunchInKey, punchedIn);
      if (punchedIn) {
        await prefs.setString(_kPunchInDateKey, todayStr);
        AttendanceRecordService.recordPunchIn(
          agentId: _rawUserId ?? _agentId,
          employeeId: _agentId,
          date: DateTime.now(),
        );
      } else {
        await prefs.remove(_kPunchInDateKey);
        await prefs.remove(userKey);
      }
    } catch (_) {}
  }

  Future<void> fetchAttendanceStatus() async {
    if (isExecutive) {
      _globalIsPunchedIn = true;
      _isAgentRemoteExempted = true;
      _isGeofenceRequired = false;
      notifyListeners();
      return;
    }

    _isSyncingStatus = true;

    try {
      final user = await LocalAuthSourceImpl().getCurrentUser();
      final token = await LocalAuthSourceImpl().getAccessToken();
      if (user != null) {
        _agentName = user.fullName;
        _agentId = user.employeeId ?? user.id;
        _rawUserId = user.id;
        if (user.isExecutive || user.isDirector || (user.email?.toLowerCase() == 'info@ssrealty.org') || (user.employeeId?.toUpperCase() == 'SSR000')) {
          _isExecutive = true;
          _isAgentRemoteExempted = true;
          _isGeofenceRequired = false;
          _globalIsPunchedIn = true;
          notifyListeners();
          return;
        }
        if (user.isRemoteAllowed) {
          _isAgentRemoteExempted = true;
          _isGeofenceRequired = false;
        }
      }

      final queryAgentId = _rawUserId ?? user?.id ?? _agentId;

      for (final base in _getEndpoints('/attendance/status')) {
        final url = '$base?agentId=$queryAgentId';
        try {
          final options = Options(
            headers: {
              if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            sendTimeout: const Duration(seconds: 4),
            receiveTimeout: const Duration(seconds: 4),
          );
          final response = await _dio.get(url, options: options);
          if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
            final data = response.data;
            final isServerPunchedIn = data['isPunchedIn'] == true;
            // If server confirmed punched in or local punch-in is not yet set, update state
            if (isServerPunchedIn) {
              _globalIsPunchedIn = true;
              await _saveLocalAttendanceState(true);
            }

            final policy = (data['geofencePolicy'] ?? data['policy']) as Map<String, dynamic>?;

            final isRemote = (policy != null && (
                  policy['isAgentRemoteExempted'] == true ||
                  policy['isRemoteAllowed'] == true ||
                  policy['allowRemotePunchIn'] == true ||
                  policy['remotePunchInAllowed'] == true ||
                  policy['allowRemote'] == true ||
                  policy['isRemote'] == true
                )) ||
                data['isRemoteAllowed'] == true ||
                data['allowRemotePunchIn'] == true ||
                data['remotePunchInAllowed'] == true ||
                data['isAgentRemoteExempted'] == true ||
                data['isRemote'] == true ||
                (user != null && user.isRemoteAllowed) ||
                (data['user'] is Map && (
                  data['user']['isRemoteAllowed'] == true ||
                  data['user']['allowRemotePunchIn'] == true ||
                  data['user']['isAgentRemoteExempted'] == true ||
                  data['user']['isRemote'] == true
                ));

            final isGeofenceOn = policy != null
                ? (policy['geofenceEnabled'] == true || policy['isGeofenceEnabled'] == true)
                : (data['geofenceEnabled'] == true);

            _isAgentRemoteExempted = isRemote;
            _geofenceEnabled = isGeofenceOn;

            // If super-admin permitted remote punch-in OR company geofence is disabled -> NO office restriction!
            if (isRemote || !isGeofenceOn) {
              _isGeofenceRequired = false;
            } else if (policy != null && policy['isGeofenceRequired'] != null) {
              _isGeofenceRequired = policy['isGeofenceRequired'] == true;
            } else {
              _isGeofenceRequired = isGeofenceOn && !isRemote;
            }

            if (policy != null) {
              if (policy['officeLat'] != null) _officeLat = (policy['officeLat'] as num).toDouble();
              if (policy['officeLng'] != null) _officeLng = (policy['officeLng'] as num).toDouble();
              if (policy['geofenceRadiusMeters'] != null) {
                _allowedRadiusInMeters = (policy['geofenceRadiusMeters'] as num).toDouble();
              }
              if (policy['officeAddress'] != null) {
                _officeAddress = policy['officeAddress'].toString();
              }
            }

            debugPrint('✅ [Attendance] Status Synced: isPunchedIn=$_globalIsPunchedIn, isGeofenceRequired=$_isGeofenceRequired, isAgentRemoteExempted=$_isAgentRemoteExempted');
            break;
          }
        } catch (e) {
          debugPrint('⚠️ [Attendance] Status fetch attempt failed on $url: $e');
        }
      }
    } catch (e) {
      debugPrint('⚠️ [Attendance] General status sync error: $e');
    } finally {
      _isSyncingStatus = false;
      notifyListeners();
    }
  }

  Future<void> punchIn() async {
    if (_isPunchingIn) return;
    _isPunchingIn = true;
    _attendanceError = null;
    notifyListeners();

    try {
      // 1. Instant GPS location (last-known or quick 800ms fix)
      Position? position;
      double? distance;

      try {
        position = await Geolocator.getLastKnownPosition();
        if (position == null) {
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (serviceEnabled) {
            LocationPermission permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
              position = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.low,
                timeLimit: const Duration(milliseconds: 1000),
              );
            }
          }
        }

        if (position != null) {
          distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            _officeLat,
            _officeLng,
          );
          _lastMeasuredDistance = distance;
        }
      } catch (e) {
        debugPrint('Quick GPS notice: $e');
      }

      // 2. Geofence Verification ONLY IF Strict Office Geofence is Required AND NOT Remote Exempted
      if (_isGeofenceRequired && !_isAgentRemoteExempted && !kIsWeb) {
        if (position == null) {
          _attendanceError = 'Please turn on GPS/Location on your device to verify office presence.';
          _isPunchingIn = false;
          notifyListeners();
          return;
        }

        if (distance != null && distance > _allowedRadiusInMeters) {
          final distKm = (distance / 1000).toStringAsFixed(2);
          _attendanceError = 'You are currently ${distKm} km away from Jonapur Office. Punch-In requires you to be within ${_allowedRadiusInMeters.round()}m of the office.';
          _isPunchingIn = false;
          notifyListeners();
          return;
        }
      }

      // 3. INSTANT OPTIMISTIC PUNCH IN (< 50ms UI response)
      _globalIsPunchedIn = true;
      _attendanceError = null;
      _isPunchingIn = false;
      notifyListeners();
      await _saveLocalAttendanceState(true);
      LocationTrackingService.instance.startTracking();

      // 4. Background Sync to Cloud Server (Non-blocking)
      _syncPunchInToServer(position);
    } catch (e) {
      _globalIsPunchedIn = true;
      _attendanceError = null;
      _isPunchingIn = false;
      await _saveLocalAttendanceState(true);
      notifyListeners();
    }
  }

  void _syncPunchInToServer(Position? position) async {
    try {
      final user = await LocalAuthSourceImpl().getCurrentUser();
      final token = await LocalAuthSourceImpl().getAccessToken();
      final queryAgentId = _rawUserId ?? user?.id ?? _agentId;

      final payload = {
        'agentId': queryAgentId,
        'latitude': position?.latitude,
        'longitude': position?.longitude,
        'accuracy': position?.accuracy,
        'deviceId': 'Android_Mobile',
        'deviceModel': 'Mobile App',
        'isRemote': _isAgentRemoteExempted || !_isGeofenceRequired,
        'address': position != null ? '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}' : 'Mobile Location',
      };

      for (final url in _getEndpoints('/attendance/punch-in')) {
        try {
          final options = Options(
            headers: {
              if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            sendTimeout: const Duration(seconds: 3),
            receiveTimeout: const Duration(seconds: 3),
          );
          final response = await _dio.post(url, data: payload, options: options);
          if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
            debugPrint('✅ [PunchIn] Successfully recorded on server: $url');
            loadStats();
            break;
          }
        } catch (e) {
          debugPrint('⚠️ [PunchIn] Attempt failed on $url: $e');
        }
      }
    } catch (_) {}
  }

  Future<void> punchOut({bool auto = false}) async {
    // 1. INSTANT OPTIMISTIC PUNCH OUT (< 10ms UI response)
    _globalIsPunchedIn = false;
    _attendanceError = null;
    _isPunchingOut = false;
    notifyListeners();
    await _saveLocalAttendanceState(false);
    LocationTrackingService.instance.stopTracking();

    // 2. Background Sync to Cloud Server
    _syncPunchOutToServer();
  }

  void _syncPunchOutToServer() async {
    try {
      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      final user = await LocalAuthSourceImpl().getCurrentUser();
      final token = await LocalAuthSourceImpl().getAccessToken();
      final queryAgentId = _rawUserId ?? user?.id ?? _agentId;

      final payload = {
        'agentId': queryAgentId,
        'latitude': position?.latitude,
        'longitude': position?.longitude,
      };

      for (final url in _getEndpoints('/attendance/punch-out')) {
        try {
          final options = Options(
            headers: {
              if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            sendTimeout: const Duration(seconds: 3),
            receiveTimeout: const Duration(seconds: 3),
          );
          final response = await _dio.post(url, data: payload, options: options);
          if (response.statusCode == 200) {
            debugPrint('✅ [PunchOut] Synced with server: $url');
            break;
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  void clearAttendanceError() {
    _attendanceError = null;
    notifyListeners();
  }

  static final Set<String> _globalDialedNumbers = {};
  static const _kLocalBookingsCountKey = 'cached_local_bookings_count';
  static const _kLocalBookingsRevenueKey = 'cached_local_bookings_revenue';

  void recordCall({required String phoneNumber, bool isConnected = false, bool isManual = false}) {
    final isNewUnique = _globalDialedNumbers.add(phoneNumber);
    _stats = _stats.copyWith(
      totalCalls: _stats.totalCalls + 1,
      connectedCalls: isConnected ? _stats.connectedCalls + 1 : _stats.connectedCalls,
      missedCalls: !isConnected ? _stats.missedCalls + 1 : _stats.missedCalls,
      uniqueCalls: isNewUnique ? _stats.uniqueCalls + 1 : _stats.uniqueCalls,
      manualCalls: isManual ? _stats.manualCalls + 1 : _stats.manualCalls,
    );
    notifyListeners();
    loadStats();
  }

  /// Records a deal closed from the post-call disposition sheet (Booking Done)
  void recordBooking({
    required String clientName,
    required String phone,
    required String dealAmountDisplay,
    required double dealAmountInCr,
    String projectName = 'SS Realty Project',
    String unitType = 'Apartment',
  }) {
    // 1. Update stats
    final updatedConversions = _stats.conversions + 1;
    final updatedBookingAmount = _stats.totalBookingAmount + dealAmountInCr;

    _stats = _stats.copyWith(
      conversions: updatedConversions,
      totalBookingAmount: updatedBookingAmount,
    );

    // 2. Add to bookings list
    final newBooking = BookingItemData(
      projectName: projectName.isNotEmpty ? projectName : 'SS Realty Project',
      location: 'Chattarpur, Delhi NCR',
      unitType: unitType.isNotEmpty ? unitType : 'Apartment',
      amount: dealAmountDisplay,
      downpayment: 'Deal Confirmed',
      clientName: clientName.isNotEmpty ? clientName : 'Client',
      phone: phone,
      date: 'Today, ${_formatTime(DateTime.now())}',
    );
    _bookings = [newBooking, ..._bookings];

    // 3. Update current user's entry in leaderboard
    final currentAgentName = _agentName;
    final idx = _leaderboard.indexWhere((e) =>
        e.agentName.toLowerCase() == currentAgentName.toLowerCase() ||
        (e.employeeId != null && e.employeeId == _agentId));

    if (idx != -1) {
      final existing = _leaderboard[idx];
      _leaderboard[idx] = LeaderboardEntry(
        rank: existing.rank,
        agentName: existing.agentName,
        employeeId: existing.employeeId,
        avatarUrl: existing.avatarUrl,
        calls: existing.calls > 0 ? existing.calls : _stats.totalCalls,
        bookings: existing.bookings + 1,
        totalBookingAmount: existing.totalBookingAmount + dealAmountInCr,
      );
    } else {
      _leaderboard.add(
        LeaderboardEntry(
          rank: 1,
          agentName: currentAgentName,
          employeeId: _agentId,
          calls: _stats.totalCalls > 0 ? _stats.totalCalls : 1,
          bookings: 1,
          totalBookingAmount: dealAmountInCr,
        ),
      );
    }

    _recalculateLeaderboard();
    notifyListeners();
    _saveLocalBookings();
  }

  void _recalculateLeaderboard() {
    // 1. Strict filtering: Only agents with active bookings or >0 amount appear
    final validEntries = _leaderboard.where((e) {
      final isDirector = e.employeeId == 'SSR000' || e.agentName.toLowerCase().contains('yogesh');
      final hasBookings = e.bookings > 0 || e.totalBookingAmount > 0;
      return !isDirector && hasBookings;
    }).toList();

    // 2. Sort descending: Highest booking value takes #1 top rank
    validEntries.sort((a, b) {
      final cmpAmount = b.totalBookingAmount.compareTo(a.totalBookingAmount);
      if (cmpAmount != 0) return cmpAmount;
      final cmpBookings = b.bookings.compareTo(a.bookings);
      if (cmpBookings != 0) return cmpBookings;
      return b.calls.compareTo(a.calls);
    });

    // 3. Dynamically re-assign sequence ranks (#1, #2, #3...)
    _leaderboard = validEntries.asMap().entries.map((item) {
      final idx = item.key;
      final entry = item.value;
      return LeaderboardEntry(
        rank: idx + 1,
        agentName: entry.agentName,
        employeeId: entry.employeeId,
        avatarUrl: entry.avatarUrl,
        calls: entry.calls,
        bookings: entry.bookings,
        totalBookingAmount: entry.totalBookingAmount,
      );
    }).toList();
  }

  static String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  Future<void> _saveLocalBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kLocalBookingsCountKey, _stats.conversions);
      await prefs.setDouble(_kLocalBookingsRevenueKey, _stats.totalBookingAmount);
    } catch (_) {}
  }

  Future<void> init({String? agentName, String? agentId}) async {
    try {
      final user = await LocalAuthSourceImpl().getCurrentUser();
      if (user != null) {
        _rawUserId = user.id;
        String resolvedName = user.fullName.trim();
        if (resolvedName.isEmpty && user.email != null) {
          resolvedName = user.email!.split('@')[0];
        }
        _agentName = resolvedName.isNotEmpty ? resolvedName : 'Agent';
        _agentId = user.employeeId ?? user.id;
      } else {
        _agentName = agentName ?? 'Agent';
        _agentId = agentId ?? 'SSR001';
      }
    } catch (_) {
      _agentName = agentName ?? 'Agent';
      _agentId = agentId ?? 'SSR001';
    }

    await fetchAttendanceStatus();
    await loadStats();
  }

  Future<void> loadStats() async {
    _setState(const ViewState.loading());

    final user = await LocalAuthSourceImpl().getCurrentUser();
    final token = await LocalAuthSourceImpl().getAccessToken();
    final queryAgentId = _rawUserId ?? user?.id ?? _agentId;
    final periodParam = _period == DashboardPeriod.today
        ? 'today'
        : _period == DashboardPeriod.week
            ? 'week'
            : 'month';

    final urls = _getEndpoints('/dashboard?period=$periodParam&agentId=$queryAgentId');

    for (final url in urls) {
      try {
        final options = Options(
          headers: {
            if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
        );
        final fullUrl = (_rawUserId != null && _rawUserId!.isNotEmpty)
            ? '$url&agentId=$_rawUserId'
            : url;
        final response = await _dio.get(fullUrl, options: options);
        if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
          final data = response.data['data'];
          final s = data['stats'];

          List<DailyCallData> chartList = [];
          if (s['callsChart'] != null && s['callsChart'] is List) {
            chartList = (s['callsChart'] as List).map((c) {
              return DailyCallData(
                date: c['date']?.toString() ?? '',
                total: (c['total'] as num?)?.toInt() ?? 0,
                connected: (c['connected'] as num?)?.toInt() ?? 0,
              );
            }).toList();
          }

          final prefs = await SharedPreferences.getInstance();
          final localSavedBookings = prefs.getInt(_kLocalBookingsCountKey) ?? 0;
          final localSavedRevenue = prefs.getDouble(_kLocalBookingsRevenueKey) ?? 0.0;

          final serverConversions = (s['conversions'] as num?)?.toInt() ?? 0;
          final serverRevenue = (s['totalBookingAmount'] as num?)?.toDouble() ?? 0.0;

          final finalConversions = serverConversions > localSavedBookings ? serverConversions : localSavedBookings;
          final finalRevenue = serverRevenue > localSavedRevenue ? serverRevenue : localSavedRevenue;

          _stats = DashboardStats(
            totalCalls: (s['totalCalls'] as num?)?.toInt() ?? 0,
            connectedCalls: (s['connectedCalls'] as num?)?.toInt() ?? 0,
            missedCalls: (s['missedCalls'] as num?)?.toInt() ?? 0,
            interestedLeads: (s['interestedLeads'] as num?)?.toInt() ?? 0,
            hotLeads: 0,
            pendingFollowups: (s['pendingFollowups'] as num?)?.toInt() ?? 0,
            completedFollowups: (s['completedFollowups'] as num?)?.toInt() ?? 0,
            scheduledVisits: (s['scheduledVisits'] as num?)?.toInt() ?? 0,
            completedVisits: (s['completedVisits'] as num?)?.toInt() ?? 0,
            conversions: finalConversions,
            manualCalls: (s['manualCalls'] as num?)?.toInt() ?? 0,
            uniqueCalls: (s['uniqueCalls'] as num?)?.toInt() ?? 0,
            totalBookingAmount: finalRevenue,
            callsChart: chartList.isNotEmpty ? chartList : _stats.callsChart,
          );

          if (data['bookings'] != null && data['bookings'] is List) {
            final serverBookings = (data['bookings'] as List).map((b) {
              return BookingItemData(
                projectName: b['projectName']?.toString() ?? 'SS Realty Project',
                location: b['location']?.toString() ?? 'Chattarpur, Delhi NCR',
                unitType: b['unitType']?.toString() ?? '3BHK',
                amount: b['amount']?.toString() ?? '₹ 0',
                downpayment: b['downpayment']?.toString() ?? '₹ 0',
                clientName: b['clientName']?.toString() ?? 'Client',
                phone: b['phone']?.toString() ?? '',
                date: b['date']?.toString() ?? 'Recent',
              );
            }).toList();
            // Merge with local newly closed bookings
            final existingPhones = serverBookings.map((b) => b.phone).toSet();
            final localOnly = _bookings.where((b) => !existingPhones.contains(b.phone)).toList();
            _bookings = [...localOnly, ...serverBookings];
          }

          if (data['leaderboard'] != null && data['leaderboard'] is List && (data['leaderboard'] as List).isNotEmpty) {
            _leaderboard = (data['leaderboard'] as List).map((lb) {
              return LeaderboardEntry(
                rank: (lb['rank'] as num?)?.toInt() ?? 1,
                agentName: lb['agentName']?.toString() ?? 'Agent',
                employeeId: lb['employeeId']?.toString(),
                calls: (lb['calls'] as num?)?.toInt() ?? 0,
                bookings: (lb['bookings'] as num?)?.toInt() ?? 0,
                totalBookingAmount: (lb['totalBookingAmount'] as num?)?.toDouble() ?? 0.0,
              );
            }).toList();
          }

          // If local agent has bookings, ensure leaderboard reflects it
          if (finalConversions > 0 || finalRevenue > 0) {
            final currentAgentName = _agentName;
            final idx = _leaderboard.indexWhere((e) =>
                e.agentName.toLowerCase() == currentAgentName.toLowerCase() ||
                (e.employeeId != null && e.employeeId == _agentId));
            if (idx != -1) {
              final existing = _leaderboard[idx];
              if (existing.bookings < finalConversions || existing.totalBookingAmount < finalRevenue) {
                _leaderboard[idx] = LeaderboardEntry(
                  rank: existing.rank,
                  agentName: existing.agentName,
                  employeeId: existing.employeeId,
                  avatarUrl: existing.avatarUrl,
                  calls: existing.calls > 0 ? existing.calls : _stats.totalCalls,
                  bookings: finalConversions > existing.bookings ? finalConversions : existing.bookings,
                  totalBookingAmount: finalRevenue > existing.totalBookingAmount ? finalRevenue : existing.totalBookingAmount,
                );
              }
            } else {
              _leaderboard.add(
                LeaderboardEntry(
                  rank: 1,
                  agentName: currentAgentName,
                  employeeId: _agentId,
                  calls: _stats.totalCalls > 0 ? _stats.totalCalls : 1,
                  bookings: finalConversions,
                  totalBookingAmount: finalRevenue,
                ),
              );
            }
          }

          _recalculateLeaderboard();

          debugPrint('✅ [Dashboard] Real Stats Synced from $url (Total Bookings: ${_stats.conversions}, Amount: ${_stats.totalBookingAmount} Cr)');
          break;
        }
      } catch (e) {
        debugPrint('⚠️ [Dashboard] Failed to fetch from $url: $e');
      }
    }

    _setState(const ViewState.success());
  }

  void setPeriod(DashboardPeriod period) {
    _period = period;
    loadStats();
  }

  void _setState(ViewState state) {
    _state = state;
    notifyListeners();
  }
}
