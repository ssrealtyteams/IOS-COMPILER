import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sales_crm_dialer/domain/entities/lead.dart';
import 'package:sales_crm_dialer/core/router/app_router.dart';
import 'alarm_sound_service.dart';
import 'notification_service.dart';

class ScheduledAlarmItem {
  final String leadId;
  final String leadJson;
  final int scheduledEpoch;
  bool triggered;

  ScheduledAlarmItem({
    required this.leadId,
    required this.leadJson,
    required this.scheduledEpoch,
    this.triggered = false,
  });

  Map<String, dynamic> toJson() => {
        'leadId': leadId,
        'leadJson': leadJson,
        'scheduledEpoch': scheduledEpoch,
        'triggered': triggered,
      };

  factory ScheduledAlarmItem.fromJson(Map<String, dynamic> json) =>
      ScheduledAlarmItem(
        leadId: json['leadId'] as String,
        leadJson: json['leadJson'] as String,
        scheduledEpoch: json['scheduledEpoch'] as int,
        triggered: json['triggered'] as bool? ?? false,
      );
}

class FollowupAlarmWatcher {
  static const String _storageKey = 'crm_scheduled_followup_alarms';
  static List<ScheduledAlarmItem> _alarms = [];
  static Timer? _watchTimer;
  static bool _isChecking = false;

  /// Initialize watcher and start periodic heartbeat check
  static Future<void> init() async {
    await _loadAlarms();
    _watchTimer?.cancel();
    _watchTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      checkAlarms();
    });
  }

  static Future<void> _loadAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final List<dynamic> decoded = jsonDecode(raw);
        _alarms = decoded.map((e) => ScheduledAlarmItem.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading saved alarms: $e');
    }
  }

  static Future<void> _saveAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_alarms.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Error saving alarms: $e');
    }
  }

  /// Register a scheduled follow-up alarm in India timezone
  static Future<void> registerAlarm({
    required Lead lead,
    required DateTime scheduledTime,
  }) async {
    final tzTime = NotificationService.toIndiaTZDateTime(scheduledTime);
    final item = ScheduledAlarmItem(
      leadId: lead.id,
      leadJson: jsonEncode(lead.toJson()),
      scheduledEpoch: tzTime.millisecondsSinceEpoch,
      triggered: false,
    );

    // Remove any existing alarm for same lead
    _alarms.removeWhere((a) => a.leadId == lead.id);
    _alarms.add(item);
    await _saveAlarms();
    debugPrint('🔔 [FollowupAlarmWatcher] Registered: ${lead.fullName} at $tzTime (Epoch: ${tzTime.millisecondsSinceEpoch})');
  }

  /// Cancel an alarm by lead ID
  static Future<void> cancelAlarm(String leadId) async {
    _alarms.removeWhere((a) => a.leadId == leadId);
    await _saveAlarms();
  }

  /// Clear all alarms
  static Future<void> clearAll() async {
    _alarms.clear();
    await _saveAlarms();
  }

  /// Heartbeat check if any scheduled alarm is due right now
  static Future<void> checkAlarms() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      bool stateChanged = false;

      for (final alarm in _alarms) {
        // If alarm timestamp has arrived and not yet triggered
        if (now >= alarm.scheduledEpoch && !alarm.triggered) {
          // If within 60 minutes window
          if (now - alarm.scheduledEpoch < 60 * 60 * 1000) {
            alarm.triggered = true;
            stateChanged = true;
            debugPrint('⏰ [FollowupAlarmWatcher] TRIGGERING IN-APP ALARM for ${alarm.leadId}');
            AppRouter.router.push('/alarm', extra: alarm.leadJson);
            AlarmSoundService.startRinging();
          } else {
            alarm.triggered = true;
            stateChanged = true;
          }
        }
      }

      // Cleanup old triggered alarms older than 24 hours
      _alarms.removeWhere(
          (a) => a.triggered && (now - a.scheduledEpoch > 86400000));

      if (stateChanged) {
        await _saveAlarms();
      }
    } catch (e) {
      debugPrint('Error in checkAlarms: $e');
    } finally {
      _isChecking = false;
    }
  }
}
