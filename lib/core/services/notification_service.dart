import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sales_crm_dialer/domain/entities/lead.dart';
import 'package:sales_crm_dialer/core/router/app_router.dart';
import 'alarm_sound_service.dart';
import 'followup_alarm_watcher.dart';
import 'package:logger/logger.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  static final Logger _logger = Logger();
  static const String channelId = 'followup_alarm_channel_v8';
  static const String channelName = 'Follow-up Call Back Alarms';
  static const String channelDescription =
      'Loud ringing alarms with Call Now, Snooze, and Silence actions for scheduled follow-ups';

  static const String newLeadsChannelId = 'new_leads_channel_v1';
  static const String newLeadsChannelName = 'New Assigned Leads';
  static const String newLeadsChannelDescription =
      'Instant heads-up notifications when a new customer lead is assigned';

  static const String infoChannelId = 'followup_info_channel';
  static const String infoChannelName = 'Follow-up Status';

  /// Returns the Asia/Kolkata (IST UTC+05:30) timezone location
  static tz.Location get indiaLocation {
    try {
      return tz.getLocation('Asia/Kolkata');
    } catch (_) {
      return tz.local;
    }
  }

  /// Converts any DateTime into exact Asia/Kolkata (IST) TZDateTime
  static tz.TZDateTime toIndiaTZDateTime(DateTime dt) {
    final loc = indiaLocation;
    return tz.TZDateTime(
      loc,
      dt.year,
      dt.month,
      dt.day,
      dt.hour,
      dt.minute,
      0,
    );
  }

  static Future<void> init() async {
    tz.initializeTimeZones();

    // 1. Explicitly configure India Timezone (Asia/Kolkata)
    try {
      final kolkata = tz.getLocation('Asia/Kolkata');
      tz.setLocalLocation(kolkata);
      _logger.i('✅ Timezone initialized to Asia/Kolkata (IST UTC+05:30)');
    } catch (e) {
      _logger.w('Timezone init fallback: $e');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onNotificationResponse,
    );

    // 2. Configure Android Notification Channels
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      try {
        await androidPlugin.requestNotificationsPermission();
      } catch (e) {
        _logger.w('Notification permission request error: $e');
      }

      try {
        await androidPlugin.requestExactAlarmsPermission();
      } catch (e) {
        _logger.w('Exact alarm permission request error: $e');
      }

      final alarmChannel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('alarm_sound'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(
            [0, 1000, 500, 1000, 500, 1000, 500, 1000]),
        enableLights: true,
      );

      final newLeadsChannel = AndroidNotificationChannel(
        newLeadsChannelId,
        newLeadsChannelName,
        description: newLeadsChannelDescription,
        importance: Importance.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('alarm_sound'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
        enableLights: true,
      );

      const infoChannel = AndroidNotificationChannel(
        infoChannelId,
        infoChannelName,
        description: 'Informational follow-up notifications',
        importance: Importance.defaultImportance,
      );

      await androidPlugin.createNotificationChannel(alarmChannel);
      await androidPlugin.createNotificationChannel(newLeadsChannel);
      await androidPlugin.createNotificationChannel(infoChannel);
    }

    // Initialize in-app audio player and alarm watcher
    await AlarmSoundService.init();
    await FollowupAlarmWatcher.init();
  }

  @pragma('vm:entry-point')
  static Future<void> _onNotificationResponse(NotificationResponse response) async {
    final actionId = response.actionId;
    final payload = response.payload;
    _logger.i('Notification response: actionId=$actionId, payload=$payload');

    if (actionId == 'action_call_now' || actionId == 'action_lead_call_now') {
      // User tapped Call Now action button
      if (payload != null && payload.isNotEmpty) {
        try {
          final lead = Lead.fromJson(jsonDecode(payload));
          await AlarmSoundService.stopRinging();
          AppRouter.callVm.initiateCall(lead: lead);
        } catch (e) {
          _logger.e('Error handling action_call_now: $e');
        }
      }
      return;
    }

    if (actionId == 'action_lead_whatsapp') {
      // User tapped WhatsApp action button
      if (payload != null && payload.isNotEmpty) {
        try {
          final lead = Lead.fromJson(jsonDecode(payload));
          final cleanPhone = lead.phone.replaceAll(RegExp(r'[^0-9]'), '');
          final target = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
          final url = Uri.parse('https://wa.me/$target');
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          _logger.e('Error opening WhatsApp from notification: $e');
        }
      }
      return;
    }

    if (actionId == 'action_lead_view') {
      // User tapped View Lead action
      try {
        AppRouter.router.go('/leads/new');
      } catch (e) {
        _logger.e('Error navigating to new leads: $e');
      }
      return;
    }

    if (actionId == 'action_snooze') {
      // User tapped Snooze (10 Min)
      await AlarmSoundService.stopRinging();
      if (payload != null && payload.isNotEmpty) {
        try {
          final lead = Lead.fromJson(jsonDecode(payload));
          final snoozeTime = DateTime.now().add(const Duration(minutes: 10));
          await scheduleFollowupAlarm(lead, snoozeTime);
          await showSnoozeNotification(lead, snoozeTime);
        } catch (e) {
          _logger.e('Error snoozing alarm: $e');
        }
      }
      return;
    }

    if (actionId == 'action_silence') {
      // User tapped Silence
      await AlarmSoundService.stopRinging();
      return;
    }

    // Default: Check if payload is lead or alarm
    if (payload != null && payload.isNotEmpty) {
      try {
        final decoded = jsonDecode(payload) as Map<String, dynamic>;
        if (decoded.containsKey('status') && decoded['status'] == 'NEW_LEAD') {
          // Open New Leads screen
          AppRouter.router.go('/leads/new');
          return;
        }
      } catch (_) {}

      _logger.i('Notification opened: pushing /alarm screen');
      AppRouter.router.push('/alarm', extra: payload);
      AlarmSoundService.startRinging();
    }
  }

  /// Triggers a real-time heads-up notification when a new lead is assigned
  static Future<void> showNewLeadNotification(Lead lead) async {
    try {
      final leadJson = jsonEncode(lead.toJson());
      final notificationId = (lead.id.hashCode & 0x7FFFFFFF);

      final androidDetails = AndroidNotificationDetails(
        newLeadsChannelId,
        newLeadsChannelName,
        channelDescription: newLeadsChannelDescription,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('alarm_sound'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.call,
        autoCancel: true,
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'action_lead_call_now',
            '📞 Call Now',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          const AndroidNotificationAction(
            'action_lead_whatsapp',
            '💬 WhatsApp',
            showsUserInterface: false,
            cancelNotification: true,
          ),
          const AndroidNotificationAction(
            'action_lead_view',
            '📋 View Lead',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      );

      final platformDetails = NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.show(
        id: notificationId,
        title: '🔥 New Lead Assigned: ${lead.fullName}',
        body: '📞 ${lead.phone} • ${lead.projectName ?? 'New Inquiry'} — Tap to view',
        notificationDetails: platformDetails,
        payload: leadJson,
      );

      _logger.i('🔥 Real-time notification shown for new lead: ${lead.fullName} (${lead.phone})');
    } catch (e) {
      _logger.e('Failed to show new lead notification: $e');
    }
  }

  /// Shows confirmation notification when alarm is snoozed
  static Future<void> showSnoozeNotification(
      Lead lead, DateTime snoozeTime) async {
    final timeStr = DateFormat('hh:mm a').format(snoozeTime);
    const androidDetails = AndroidNotificationDetails(
      infoChannelId,
      infoChannelName,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      autoCancel: true,
    );
    const platformDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
      id: (lead.id.hashCode & 0x7FFFFFFF) + 1,
      title: '⏰ Alarm Snoozed: ${lead.fullName}',
      body: 'Reminder rescheduled for $timeStr',
      notificationDetails: platformDetails,
    );
  }

  /// Schedules a full-screen ringing alarm with interactive Call Now, Snooze, and Silence actions
  static Future<void> scheduleFollowupAlarm(
      Lead lead, DateTime scheduledTime) async {
    try {
      final leadJson = jsonEncode(lead.toJson());
      final timeStr = DateFormat('d MMM, hh:mm a').format(scheduledTime);

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('alarm_sound'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(
            [0, 1000, 500, 1000, 500, 1000, 500, 1000]),
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.alarm,
        ongoing: true,
        autoCancel: true,
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'action_call_now',
            '📞 Call Now',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          const AndroidNotificationAction(
            'action_snooze',
            '⏰ Snooze (10 Min)',
            showsUserInterface: false,
            cancelNotification: true,
          ),
          const AndroidNotificationAction(
            'action_silence',
            '🔕 Silence / Dismiss',
            showsUserInterface: false,
            cancelNotification: true,
          ),
        ],
      );

      final platformDetails = NotificationDetails(android: androidDetails);

      // Exact India Timezone (Asia/Kolkata) conversion
      final scheduledDate = toIndiaTZDateTime(scheduledTime);
      var targetSchedule = scheduledDate;
      final nowTz = tz.TZDateTime.now(indiaLocation);

      if (targetSchedule.isBefore(nowTz)) {
        targetSchedule = nowTz.add(const Duration(seconds: 3));
      }

      final notificationId = (lead.id.hashCode & 0x7FFFFFFF);
      bool scheduled = false;

      // 1. Try alarmClock mode
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id: notificationId,
          title: '⏰ Call Back: ${lead.fullName}',
          body: 'Scheduled for $timeStr — Tap Call Now or Snooze below',
          scheduledDate: targetSchedule,
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          payload: leadJson,
        );
        scheduled = true;
      } catch (e) {
        _logger.w('alarmClock schedule failed: $e, falling back to exactAllowWhileIdle');
      }

      // 2. Try exactAllowWhileIdle mode
      if (!scheduled) {
        try {
          await flutterLocalNotificationsPlugin.zonedSchedule(
            id: notificationId,
            title: '⏰ Call Back: ${lead.fullName}',
            body: 'Scheduled for $timeStr — Tap Call Now or Snooze below',
            scheduledDate: targetSchedule,
            notificationDetails: platformDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: leadJson,
          );
          scheduled = true;
        } catch (e) {
          _logger.w('exactAllowWhileIdle schedule failed: $e, falling back to inexact');
        }
      }

      // 3. Fallback to inexact mode
      if (!scheduled) {
        try {
          await flutterLocalNotificationsPlugin.zonedSchedule(
            id: notificationId,
            title: '⏰ Call Back: ${lead.fullName}',
            body: 'Scheduled for $timeStr — Tap Call Now or Snooze below',
            scheduledDate: targetSchedule,
            notificationDetails: platformDetails,
            androidScheduleMode: AndroidScheduleMode.inexact,
            payload: leadJson,
          );
          scheduled = true;
        } catch (e) {
          _logger.e('inexact schedule failed: $e');
        }
      }

      // Register in in-app failsafe watcher
      await FollowupAlarmWatcher.registerAlarm(
        lead: lead,
        scheduledTime: scheduledTime,
      );

      _logger.i('✅ Alarm scheduled for ${lead.fullName} at $targetSchedule (IST: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(targetSchedule)})');
    } catch (e) {
      _logger.e('❌ Failed to schedule alarm: $e');
    }
  }

  static Future<void> cancelAlarm(Lead lead) async {
    try {
      final notificationId = (lead.id.hashCode & 0x7FFFFFFF);
      await flutterLocalNotificationsPlugin.cancel(id: notificationId);
      await FollowupAlarmWatcher.cancelAlarm(lead.id);
      _logger.i('🔕 Alarm cancelled for ${lead.fullName}');
    } catch (e) {
      _logger.e('Failed to cancel alarm: $e');
    }
  }

  static Future<void> cancelAllAlarms() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      await FollowupAlarmWatcher.clearAll();
      _logger.i('🔕 All alarms cancelled');
    } catch (e) {
      _logger.e('Failed to cancel all alarms: $e');
    }
  }
}
