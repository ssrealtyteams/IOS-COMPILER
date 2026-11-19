import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../error/result.dart';

class CallEvent {
  const CallEvent({
    required this.type,
    this.data,
    this.durationSeconds,
    this.recordingPath,
    this.timestamp,
  });

  final String type;
  final String? data;
  final int? durationSeconds;
  final String? recordingPath;
  final int? timestamp;

  factory CallEvent.fromMap(Map<dynamic, dynamic> map) => CallEvent(
        type: (map['type'] ?? map['eventType'] ?? '') as String,
        data: (map['data'] ?? map['phoneNumber']) as String?,
        durationSeconds: (map['durationSeconds'] ?? map['duration'] as num?)?.toInt(),
        recordingPath: (map['recordingPath'] ?? map['audioPath']) as String?,
        timestamp: map['timestamp'] as int?,
      );
}

class CallChannel {
  static const _methodChannel = MethodChannel(ChannelNames.callMethod);
  static const _eventChannel = EventChannel(ChannelNames.callEvents);

  static Stream<CallEvent>? _callEventStream;

  /// Initiate a call via native Kotlin
  static Future<Result<void, AppError>> initiateCall(String phoneNumber) async {
    if (kIsWeb) return Result.failure(AppError.local('Web cellular calling not supported'));
    try {
      await _methodChannel.invokeMethod('initiateCall', {
        'phoneNumber': phoneNumber,
      });
      return Result.success(null);
    } on PlatformException catch (e) {
      return Result.failure(AppError.local(e.message ?? 'Failed to initiate call'));
    }
  }

  /// Hang up / cut active carrier phone call via native layer
  static Future<bool> endCall() async {
    if (kIsWeb) return false;
    try {
      final res = await _methodChannel.invokeMethod<bool>('endCall');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Answer / Accept incoming carrier phone call via native layer
  static Future<bool> answerCall() async {
    if (kIsWeb) return false;
    try {
      final res = await _methodChannel.invokeMethod<bool>('answerCall');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Reject / Decline incoming carrier phone call via native layer
  static Future<bool> rejectCall() async {
    if (kIsWeb) return false;
    try {
      final res = await _methodChannel.invokeMethod<bool>('rejectCall');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Turn speakerphone on / off
  static Future<bool> setSpeakerphoneOn(bool enabled) async {
    if (kIsWeb) return false;
    try {
      final res = await _methodChannel.invokeMethod<bool>('setSpeakerphoneOn', {'enabled': enabled});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Turn microphone mute on / off
  static Future<bool> setMicrophoneMute(bool enabled) async {
    if (kIsWeb) return false;
    try {
      final res = await _methodChannel.invokeMethod<bool>('setMicrophoneMute', {'enabled': enabled});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Check if the app is currently set as the default phone app
  static Future<bool> isDefaultDialer() async {
    if (kIsWeb) return false;
    try {
      final res = await _methodChannel.invokeMethod<bool>('isDefaultDialer');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Request the user to set Sales CRM as their default phone app
  static Future<bool> requestDefaultDialer() async {
    if (kIsWeb) return false;
    try {
      final res = await _methodChannel.invokeMethod<bool>('requestDefaultDialer');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Play in-call DTMF digit (1-9, *, #)
  static Future<bool> sendDtmf(String digit) async {
    if (kIsWeb) return false;
    try {
      final res = await _methodChannel.invokeMethod<bool>('sendDtmf', {'digit': digit});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Check and request call permissions
  static Future<Result<bool, AppError>> checkPermissions() async {
    if (kIsWeb) return Result.success(true);
    try {
      final granted = await _methodChannel.invokeMethod<bool>('checkPermissions');
      return Result.success(granted ?? false);
    } on PlatformException catch (e) {
      return Result.failure(AppError.local(e.message ?? 'Permission check failed'));
    }
  }

  /// Get last call log entry directly from Android system
  static Future<Map<String, dynamic>> getLastCallLog([String? phoneNumber]) async {
    if (kIsWeb) return {};
    try {
      final result = await _methodChannel.invokeMethod<Map>('getLastCallLog', {
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
      });
      return Map<String, dynamic>.from(result ?? {});
    } catch (_) {
      return {};
    }
  }

  /// Start manual in-app voice recording via native layer
  static Future<String?> startVoiceRecording([String? phoneNumber]) async {
    if (kIsWeb) return null;
    try {
      final path = await _methodChannel.invokeMethod<String>('startVoiceRecording', {
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
      });
      return path;
    } catch (_) {
      return null;
    }
  }

  /// Stop manual voice recording and get local file path
  static Future<String?> stopVoiceRecording() async {
    if (kIsWeb) return null;
    try {
      final path = await _methodChannel.invokeMethod<String>('stopVoiceRecording');
      return path;
    } catch (_) {
      return null;
    }
  }

  /// Get current recording file path
  static Future<String?> getRecordingPath() async {
    if (kIsWeb) return null;
    try {
      final path = await _methodChannel.invokeMethod<String>('getRecordingPath');
      return path;
    } catch (_) {
      return null;
    }
  }

  /// Get SIM card information
  static Future<Map<String, dynamic>> getSimInfo() async {
    if (kIsWeb) return {};
    try {
      final result = await _methodChannel.invokeMethod<Map>('getSimInfo');
      return Map<String, dynamic>.from(result ?? {});
    } catch (_) {
      return {};
    }
  }

  /// Stream of call state events from Kotlin
  static Stream<CallEvent> get callEvents {
    if (kIsWeb) return const Stream.empty();
    _callEventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => CallEvent.fromMap(event as Map))
        .asBroadcastStream();
    return _callEventStream!;
  }

  /// Start foreground service for call monitoring
  static Future<void> startCallMonitoring() async {
    if (kIsWeb) return;
    try {
      await _methodChannel.invokeMethod('startCallMonitoring');
    } catch (_) {}
  }

  /// Stop foreground service
  static Future<void> stopCallMonitoring() async {
    if (kIsWeb) return;
    try {
      await _methodChannel.invokeMethod('stopCallMonitoring');
    } catch (_) {}
  }
}
