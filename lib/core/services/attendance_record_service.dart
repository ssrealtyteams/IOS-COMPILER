import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/remote_lead_repository.dart';

/// Centralized service to track and evaluate actual agent attendance dates.
/// Solves phantom/mock attendance marking by checking verified punch-in records
/// and live CRM activity timestamps.
class AttendanceRecordService {
  static final Set<String> _inMemoryPunches = {};
  static bool _isLoaded = false;

  /// Load cached punch dates from SharedPreferences into memory
  static Future<void> init() async {
    if (_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final all = prefs.getStringList('all_attendance_punched_keys') ?? [];
      _inMemoryPunches.addAll(all);
      _isLoaded = true;
    } catch (_) {}
  }

  /// Format date as YYYY-MM-DD
  static String dateToKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Records a verified punch-in for an agent
  static Future<void> recordPunchIn({
    required String agentId,
    required String employeeId,
    DateTime? date,
  }) async {
    final d = date ?? DateTime.now();
    final dateStr = dateToKey(d);

    bool added = false;
    for (final id in [agentId, employeeId]) {
      final clean = id.trim().toLowerCase();
      if (clean.isNotEmpty) {
        final key = '${clean}_$dateStr';
        if (_inMemoryPunches.add(key)) {
          added = true;
        }
      }
    }

    if (added) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('all_attendance_punched_keys', _inMemoryPunches.toList());
      } catch (_) {}
    }
  }

  /// Checks if an agent has a recorded punch on a specific date
  static bool hasPunchRecord({
    required String agentId,
    required String employeeId,
    required DateTime date,
  }) {
    final dateStr = dateToKey(date);
    for (final id in [agentId, employeeId]) {
      final clean = id.trim().toLowerCase();
      if (clean.isNotEmpty) {
        final key = '${clean}_$dateStr';
        if (_inMemoryPunches.contains(key)) return true;
      }
    }
    return false;
  }

  /// Checks if an agent was present on a given date.
  /// - Sundays: Always weekOff (false).
  /// - Future: Always false.
  /// - Today: Present if isOnline, has firstPunchIn, has calls, or has CRM activities.
  /// - Past: Present ONLY if verified punch record exists or CRM activity exists on that date.
  static bool isAgentPresentOnDate({
    required String agentId,
    required String employeeId,
    required String agentName,
    required DateTime date,
    bool isOnlineToday = false,
    String? firstPunchInToday,
    int callsToday = 0,
  }) {
    // Sundays are weekly off
    if (date.weekday == DateTime.sunday) return false;

    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final isFuture = date.isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59));

    if (isFuture) return false;

    if (isToday) {
      final hasPunch = firstPunchInToday != null && firstPunchInToday.trim().isNotEmpty;
      final acts = RemoteLeadRepository.getActivitiesForAgent(agentName, employeeId);
      final hasActsToday = acts.any((a) => a.date.year == now.year && a.date.month == now.month && a.date.day == now.day);
      final isPresent = isOnlineToday || hasPunch || callsToday > 0 || hasActsToday || hasPunchRecord(agentId: agentId, employeeId: employeeId, date: date);

      // Cache today's punch-in if present
      if (isPresent) {
        recordPunchIn(agentId: agentId, employeeId: employeeId, date: date);
      }
      return isPresent;
    }

    // Past date:
    // 1. Check if verified punch record exists for that past day
    if (hasPunchRecord(agentId: agentId, employeeId: employeeId, date: date)) {
      return true;
    }

    // 2. Check if agent had any CRM call / visit activities on that past day
    final acts = RemoteLeadRepository.getActivitiesForAgent(agentName, employeeId);
    final hasActsOnDate = acts.any((a) =>
      a.date.year == date.year && a.date.month == date.month && a.date.day == date.day
    );
    if (hasActsOnDate) {
      recordPunchIn(agentId: agentId, employeeId: employeeId, date: date);
      return true;
    }

    return false;
  }
}
