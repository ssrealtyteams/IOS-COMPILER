abstract class AppConstants {
  static const appName = 'Sales CRM Dialer';
  static const appVersion = '1.0.0';
  static const maxSessionCount = 2;
  static const callDispositionDelaySeconds = 2;
  static const syncRetryLimit = 3;
  static const paginationLimit = 20;
  static const searchDebounceMs = 300;
  static const offlineSyncIntervalMinutes = 5;
}

abstract class StorageKeys {
  static const accessToken = 'access_token';
  static const refreshToken = 'refresh_token';
  static const userId = 'user_id';
  static const orgId = 'org_id';
  static const deviceId = 'device_id';
  static const fcmToken = 'fcm_token';
  static const userProfile = 'user_profile';
  static const rememberMe = 'remember_me';
  static const lastSyncAt = 'last_sync_at';
  static const biometricEnabled = 'biometric_enabled';
}

abstract class ChannelNames {
  static const callMethod = 'com.salescrm.dialer/call';
  static const callEvents = 'com.salescrm.dialer/call_events';
  static const contactsMethod = 'com.salescrm.dialer/contacts';
}

abstract class CallEventTypes {
  static const dialing = 'CALL_DIALING';
  static const ringing = 'CALL_RINGING';
  static const started = 'CALL_STARTED';
  static const connected = 'CALL_CONNECTED';
  static const ended = 'CALL_ENDED';
  static const missed = 'CALL_MISSED';
  static const rejected = 'CALL_REJECTED';
}

abstract class NotificationTypes {
  static const followupReminder = 'followup_reminder';
  static const missedFollowup = 'missed_followup';
  static const leadAssigned = 'lead_assigned';
  static const visitReminder = 'visit_reminder';
  static const callDisposition = 'call_disposition';
}

abstract class ActivityActions {
  static const callMade = 'call_made';
  static const callReceived = 'call_received';
  static const callMissed = 'call_missed';
  static const dispositionSaved = 'disposition_saved';
  static const noteSaved = 'note_saved';
  static const followupScheduled = 'followup_scheduled';
  static const followupCompleted = 'followup_completed';
  static const visitScheduled = 'visit_scheduled';
  static const visitCompleted = 'visit_done';
  static const statusChanged = 'status_changed';
  static const detailsShared = 'details_shared';
  static const leadAssigned = 'lead_assigned';
}
