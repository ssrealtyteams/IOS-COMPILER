import 'package:intl/intl.dart';

class AdminOverviewStats {
  final int totalTelecallers;
  final int onlineTelecallers;
  final int totalScreenTimeMinutes;
  final int assignedLeads;
  final int notInterestedLeads;
  final int visitScheduledLeads;
  final int visitDoneLeads;
  final int bookedLeads;
  final double totalBookingsAmount;
  final bool isAutoDistributionActive;

  const AdminOverviewStats({
    this.totalTelecallers = 0,
    this.onlineTelecallers = 0,
    this.totalScreenTimeMinutes = 0,
    this.assignedLeads = 0,
    this.notInterestedLeads = 0,
    this.visitScheduledLeads = 0,
    this.visitDoneLeads = 0,
    this.bookedLeads = 0,
    this.totalBookingsAmount = 0.0,
    this.isAutoDistributionActive = true,
  });

  AdminOverviewStats copyWith({
    int? totalTelecallers,
    int? onlineTelecallers,
    int? totalScreenTimeMinutes,
    int? assignedLeads,
    int? notInterestedLeads,
    int? visitScheduledLeads,
    int? visitDoneLeads,
    int? bookedLeads,
    double? totalBookingsAmount,
    bool? isAutoDistributionActive,
  }) {
    return AdminOverviewStats(
      totalTelecallers: totalTelecallers ?? this.totalTelecallers,
      onlineTelecallers: onlineTelecallers ?? this.onlineTelecallers,
      totalScreenTimeMinutes: totalScreenTimeMinutes ?? this.totalScreenTimeMinutes,
      assignedLeads: assignedLeads ?? this.assignedLeads,
      notInterestedLeads: notInterestedLeads ?? this.notInterestedLeads,
      visitScheduledLeads: visitScheduledLeads ?? this.visitScheduledLeads,
      visitDoneLeads: visitDoneLeads ?? this.visitDoneLeads,
      bookedLeads: bookedLeads ?? this.bookedLeads,
      totalBookingsAmount: totalBookingsAmount ?? this.totalBookingsAmount,
      isAutoDistributionActive: isAutoDistributionActive ?? this.isAutoDistributionActive,
    );
  }

  factory AdminOverviewStats.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val, [int fallback = 0]) {
      if (val == null) return fallback;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? fallback;
    }

    double parseDouble(dynamic val, [double fallback = 0.0]) {
      if (val == null) return fallback;
      if (val is double) return val;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? fallback;
    }

    final masterAssign = json['masterAutoAssign'];
    final bool isAutoDist = json['isAutoDistributionActive'] as bool? ??
        (masterAssign is Map ? (masterAssign['enabled'] as bool? ?? false) : null) ??
        (json['autoDistribution'] as bool? ?? false);

    return AdminOverviewStats(
      totalTelecallers: parseInt(json['totalTelecallers'] ?? json['totalAgents'] ?? json['telecallersCount'] ?? json['total_agents'] ?? json['total_telecallers'], 0),
      onlineTelecallers: parseInt(json['onlineTelecallers'] ?? json['onlineCount'] ?? json['online_agents'] ?? json['active_agents'], 0),
      totalScreenTimeMinutes: parseInt(json['totalScreenTimeMinutes'] ?? json['cumulativeScreenTime'] ?? json['total_screen_time'] ?? (json['totalActiveSeconds'] != null ? (parseInt(json['totalActiveSeconds']) ~/ 60) : null), 0),
      assignedLeads: parseInt(json['assignedLeads'] ?? json['totalAssigned'] ?? json['assigned_leads'] ?? json['assigned'] ?? json['total_leads'], 0),
      notInterestedLeads: parseInt(json['notInterestedLeads'] ?? json['totalNotInterested'] ?? json['not_interested_leads'] ?? json['notInterested'] ?? json['not_interested'], 0),
      visitScheduledLeads: parseInt(json['visitScheduledLeads'] ?? json['totalVisitScheduled'] ?? json['visit_scheduled_leads'] ?? json['visitScheduled'] ?? json['site_visits_scheduled'], 0),
      visitDoneLeads: parseInt(json['visitDoneLeads'] ?? json['totalVisitDone'] ?? json['visit_done_leads'] ?? json['visitDone'] ?? json['site_visits_done'], 0),
      bookedLeads: parseInt(json['bookedLeads'] ?? json['totalBooked'] ?? json['booked_leads'] ?? json['booked'] ?? json['bookingDone'] ?? json['bookings'], 0),
      totalBookingsAmount: parseDouble(json['totalBookingsAmount'] ?? json['bookingAmount'] ?? json['total_booking_amount'], 0.0),
      isAutoDistributionActive: isAutoDist,
    );
  }

  String get screenTimeFormatted {
    final hours = totalScreenTimeMinutes ~/ 60;
    final minutes = totalScreenTimeMinutes % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}

class TelecallerOverview {
  final String id;
  final String name;
  final String employeeId;
  final String email;
  final String phone;
  final String? avatarUrl;
  final bool isOnline;
  final bool isQueueActive; // true = active in queue, false = on leave
  final String? firstPunchIn;
  final String? lastActive;
  final int screenTimeMinutes;
  final int assignedLeads;
  final int notInterestedLeads;
  final int visitScheduledLeads;
  final int visitDoneLeads;
  final int bookedLeads;
  final int totalCalls;
  final int connectedCalls;

  const TelecallerOverview({
    required this.id,
    required this.name,
    required this.employeeId,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.isOnline = false,
    this.isQueueActive = true,
    this.firstPunchIn,
    this.lastActive,
    this.screenTimeMinutes = 0,
    this.assignedLeads = 0,
    this.notInterestedLeads = 0,
    this.visitScheduledLeads = 0,
    this.visitDoneLeads = 0,
    this.bookedLeads = 0,
    this.totalCalls = 0,
    this.connectedCalls = 0,
  });

  TelecallerOverview copyWith({
    bool? isQueueActive,
    bool? isOnline,
    String? firstPunchIn,
    String? lastActive,
    int? screenTimeMinutes,
    int? assignedLeads,
    int? notInterestedLeads,
    int? visitScheduledLeads,
    int? visitDoneLeads,
    int? bookedLeads,
    int? totalCalls,
    int? connectedCalls,
  }) {
    return TelecallerOverview(
      id: id,
      name: name,
      employeeId: employeeId,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      isQueueActive: isQueueActive ?? this.isQueueActive,
      firstPunchIn: formatPunchTime(firstPunchIn) ?? this.firstPunchIn,
      lastActive: lastActive ?? this.lastActive,
      screenTimeMinutes: screenTimeMinutes ?? this.screenTimeMinutes,
      assignedLeads: assignedLeads ?? this.assignedLeads,
      notInterestedLeads: notInterestedLeads ?? this.notInterestedLeads,
      visitScheduledLeads: visitScheduledLeads ?? this.visitScheduledLeads,
      visitDoneLeads: visitDoneLeads ?? this.visitDoneLeads,
      bookedLeads: bookedLeads ?? this.bookedLeads,
      totalCalls: totalCalls ?? this.totalCalls,
      connectedCalls: connectedCalls ?? this.connectedCalls,
    );
  }

  /// Robust punch-in time parser converting raw ISO strings (e.g. 2026-09-02T15:51:37.611Z) or 24-hr strings to clean 12-hour AM/PM format.
  static String? formatPunchTime(String? punch) {
    if (punch == null || punch.trim().isEmpty) return null;
    final trimmed = punch.trim();
    try {
      final dt = DateTime.tryParse(trimmed);
      if (dt != null) {
        return DateFormat('hh:mm a').format(dt.toLocal());
      }
    } catch (_) {}
    if (RegExp(r'^\d{1,2}:\d{2}(:\d{2})?$').hasMatch(trimmed)) {
      try {
        final parts = trimmed.split(':');
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final dt = DateTime(2026, 1, 1, h, m);
        return DateFormat('hh:mm a').format(dt);
      } catch (_) {}
    }
    return trimmed;
  }

  factory TelecallerOverview.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    return TelecallerOverview(
      id: json['id']?.toString() ?? json['agentId']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? json['fullName'] as String? ?? 'Agent',
      employeeId: json['employeeId'] as String? ?? json['employee_id'] as String? ?? 'SSR---',
      email: json['email'] as String? ?? json['username'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar'] as String?,
      isOnline: json['isOnline'] as bool? ?? json['online'] as bool? ?? false,
      isQueueActive: json['isQueueActive'] as bool? ?? json['isReceivingLeads'] as bool? ?? json['queueActive'] as bool? ?? !(json['onLeave'] == true),
      firstPunchIn: formatPunchTime(json['firstPunchIn'] as String? ?? json['punchIn'] as String?),
      lastActive: json['lastActive'] as String? ?? json['lastActiveFormatted'] as String? ?? json['lastSeen'] as String?,
      screenTimeMinutes: parseInt(json['screenTimeMinutes'] ?? json['screenTime'] ?? (json['todayActiveSeconds'] != null ? (parseInt(json['todayActiveSeconds']) ~/ 60) : null) ?? json['screen_time']),
      assignedLeads: parseInt(json['assignedLeads'] ?? json['assigned'] ?? json['assigned_leads'] ?? json['total_leads'] ?? json['totalLeads'] ?? json['leads']),
      notInterestedLeads: parseInt(json['notInterestedLeads'] ?? json['notInterested'] ?? json['not_interested'] ?? json['rejected']),
      visitScheduledLeads: parseInt(json['visitScheduledLeads'] ?? json['visitScheduled'] ?? json['visit_scheduled'] ?? json['site_visits_scheduled']),
      visitDoneLeads: parseInt(json['visitDoneLeads'] ?? json['visitDone'] ?? json['visit_done'] ?? json['site_visits_done']),
      bookedLeads: parseInt(json['bookedLeads'] ?? json['booked'] ?? json['bookingDone'] ?? json['booked_leads'] ?? json['bookings'] ?? json['closed']),
      totalCalls: parseInt(json['totalCalls'] ?? json['callsToday'] ?? json['calls'] ?? json['total_calls'] ?? json['callsMade'] ?? json['calls_made']),
      connectedCalls: parseInt(json['connectedCalls'] ?? json['connected'] ?? json['connected_calls'] ?? json['callsConnected'] ?? json['calls_connected']),
    );
  }

  String get screenTimeFormatted {
    final hours = screenTimeMinutes ~/ 60;
    final minutes = screenTimeMinutes % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}

class AgentRadarLocation {
  final String id;
  final String name;
  final String employeeId;
  final String phone;
  final String status; // 'inOffice', 'onFieldVisit', 'offDuty'
  final double distanceMeters;
  final String address;
  final double latitude;
  final double longitude;
  final DateTime? lastUpdated;
  final int? batteryPercent;
  final String? punchInTime;
  final bool isPunchedIn;
  final String screenTimeText;
  final String geofenceLocation;
  final String? lastSignalFormatted;

  const AgentRadarLocation({
    required this.id,
    required this.name,
    required this.employeeId,
    required this.phone,
    required this.status,
    required this.distanceMeters,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.lastUpdated,
    this.batteryPercent,
    this.punchInTime,
    this.isPunchedIn = true,
    this.screenTimeText = '0m',
    this.geofenceLocation = 'Inside Jonapur Head Office (Dalmia Farm)',
    this.lastSignalFormatted,
  });

  AgentRadarLocation copyWith({
    String? id,
    String? name,
    String? employeeId,
    String? phone,
    String? status,
    double? distanceMeters,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? lastUpdated,
    int? batteryPercent,
    String? punchInTime,
    bool? isPunchedIn,
    String? screenTimeText,
    String? geofenceLocation,
    String? lastSignalFormatted,
  }) {
    return AgentRadarLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      employeeId: employeeId ?? this.employeeId,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      punchInTime: punchInTime ?? this.punchInTime,
      isPunchedIn: isPunchedIn ?? this.isPunchedIn,
      screenTimeText: screenTimeText ?? this.screenTimeText,
      geofenceLocation: geofenceLocation ?? this.geofenceLocation,
      lastSignalFormatted: lastSignalFormatted ?? this.lastSignalFormatted,
    );
  }

  factory AgentRadarLocation.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] as String? ?? json['lastLocationStatus'] as String? ?? 'offDuty').toLowerCase();
    String mappedStatus;
    if (rawStatus == 'inoffice' || rawStatus == 'in_office') {
      mappedStatus = 'inOffice';
    } else if (rawStatus == 'field' || rawStatus == 'onfieldvisit' || rawStatus == 'on_field_visit') {
      mappedStatus = 'onFieldVisit';
    } else {
      mappedStatus = 'offDuty';
    }

    final double distMeters = (json['distanceMeters'] as num?)?.toDouble() ??
        ((json['lastDistanceKm'] as num?) != null ? (json['lastDistanceKm'] as num).toDouble() * 1000 : null) ??
        (json['distance'] as num?)?.toDouble() ??
        0.0;

    return AgentRadarLocation(
      id: json['id'] as String? ?? json['agentId'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? json['fullName'] as String? ?? 'Agent',
      employeeId: json['employeeId'] as String? ?? json['employee_id'] as String? ?? 'SSR---',
      phone: json['phone'] as String? ?? '',
      status: mappedStatus,
      distanceMeters: distMeters,
      address: json['address'] as String? ?? json['lastLocationAddress'] as String? ?? 'Jonapur Head Office, New Delhi',
      latitude: (json['latitude'] as num?)?.toDouble() ?? (json['lat'] as num?)?.toDouble() ?? 28.4624272,
      longitude: (json['longitude'] as num?)?.toDouble() ?? (json['lng'] as num?)?.toDouble() ?? 77.1515298,
      lastUpdated: json['lastUpdated'] != null ? DateTime.tryParse(json['lastUpdated'].toString()) : null,
      batteryPercent: json['batteryPercent'] as int? ?? json['battery'] as int? ?? 100,
      punchInTime: TelecallerOverview.formatPunchTime(json['punchInTime'] as String? ?? json['punchIn'] as String? ?? json['firstPunchIn'] as String?),
      isPunchedIn: json['isPunchedIn'] as bool? ?? json['punchedIn'] as bool? ?? (json['punchInTime'] != null || json['punchIn'] != null),
      screenTimeText: json['screenTimeText'] as String? ?? json['todayActiveFormatted'] as String? ?? json['screenTime'] as String? ?? '0m',
      geofenceLocation: json['geofenceLocation'] as String? ?? json['lastLocationAddress'] as String? ?? 'Jonapur Head Office (Dalmia Farm)',
      lastSignalFormatted: json['lastSignalFormatted'] as String? ?? json['lastActiveFormatted'] as String? ?? json['lastSignal'] as String?,
    );
  }

  String get distanceFormatted {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
  }

  String get estimatedTravelTime {
    if (!isOnline) return 'Off-Duty';
    if (isInOffice) return 'At Base';
    final km = distanceMeters / 1000.0;
    final mins = (km * 2.4 + 2).round();
    if (mins < 60) return '~$mins mins';
    final hrs = mins ~/ 60;
    final remMins = mins % 60;
    return '~$hrs h $remMins m';
  }

  bool get isOnline => isPunchedIn && status.toLowerCase() != 'offduty' && status.toLowerCase() != 'punchedout';
  bool get isInOffice => isOnline && (status.toLowerCase() == 'inoffice' || distanceMeters <= 200);
}

class AgentGpsWaypoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String address;
  final double speedKmh;
  final int batteryPercent;
  final String activityTag; // 'Punch-In', 'Site Visit', 'Client Meeting', 'Transit', 'In-Office'
  final double distanceFromOfficeMeters;
  final int stayDurationMinutes; // > 5 mins = idle halt stay
  final DateTime? departureTime;

  const AgentGpsWaypoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.address,
    this.speedKmh = 0.0,
    this.batteryPercent = 100,
    this.activityTag = 'Transit',
    this.distanceFromOfficeMeters = 0.0,
    this.stayDurationMinutes = 0,
    this.departureTime,
  });

  bool get isHalt => stayDurationMinutes >= 5;

  String get stayDurationFormatted {
    if (stayDurationMinutes < 60) return '$stayDurationMinutes mins';
    final hrs = stayDurationMinutes ~/ 60;
    final mins = stayDurationMinutes % 60;
    if (mins == 0) return '$hrs hrs';
    return '$hrs h $mins m';
  }

  factory AgentGpsWaypoint.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    final ts = json['timestamp'] != null
        ? (DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now())
        : DateTime.now();

    final dep = json['departureTime'] != null
        ? DateTime.tryParse(json['departureTime'].toString())
        : null;

    final stay = parseInt(json['stayDurationMinutes'] ?? json['stayDuration'] ?? json['idleMinutes'] ?? json['durationMinutes']);

    return AgentGpsWaypoint(
      latitude: (json['latitude'] as num?)?.toDouble() ?? (json['lat'] as num?)?.toDouble() ?? 28.4624272,
      longitude: (json['longitude'] as num?)?.toDouble() ?? (json['lng'] as num?)?.toDouble() ?? 77.1515298,
      timestamp: ts,
      departureTime: dep,
      address: json['address'] as String? ?? 'Jonapur Office, New Delhi',
      speedKmh: (json['speedKmh'] as num?)?.toDouble() ?? (json['speed'] as num?)?.toDouble() ?? 0.0,
      batteryPercent: parseInt(json['batteryPercent'] ?? json['battery'] ?? 100),
      activityTag: json['activityTag'] as String? ?? json['activity'] as String? ?? 'Transit',
      distanceFromOfficeMeters: (json['distanceFromOfficeMeters'] as num?)?.toDouble() ??
          (json['distance'] as num?)?.toDouble() ??
          0.0,
      stayDurationMinutes: stay,
    );
  }

  String get timeFormatted {
    final hr = timestamp.hour > 12 ? timestamp.hour - 12 : (timestamp.hour == 0 ? 12 : timestamp.hour);
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    final min = timestamp.minute.toString().padLeft(2, '0');
    return '$hr:$min $period';
  }

  String get haltIntervalFormatted {
    if (departureTime != null) {
      final depHr = departureTime!.hour > 12 ? departureTime!.hour - 12 : (departureTime!.hour == 0 ? 12 : departureTime!.hour);
      final depPeriod = departureTime!.hour >= 12 ? 'PM' : 'AM';
      final depMin = departureTime!.minute.toString().padLeft(2, '0');
      return '$timeFormatted - $depHr:$depMin $depPeriod';
    }
    if (stayDurationMinutes > 0) {
      final dep = timestamp.add(Duration(minutes: stayDurationMinutes));
      final depHr = dep.hour > 12 ? dep.hour - 12 : (dep.hour == 0 ? 12 : dep.hour);
      final depPeriod = dep.hour >= 12 ? 'PM' : 'AM';
      final depMin = dep.minute.toString().padLeft(2, '0');
      return '$timeFormatted - $depHr:$depMin $depPeriod';
    }
    return timeFormatted;
  }
}

class AgentGpsRouteHistory {
  final String agentId;
  final String agentName;
  final String employeeId;
  final String phone;
  final String status;
  final String? punchInTime;
  final String punchInAddress;
  final double punchInLat;
  final double punchInLng;
  final double currentLat;
  final double currentLng;
  final String currentAddress;
  final double distanceFromOfficeMeters;
  final String estimatedTimeToOffice;
  final double totalDistanceTravelledKm;
  final int batteryPercent;
  final List<AgentGpsWaypoint> waypoints;
  final double officeLat;
  final double officeLng;

  const AgentGpsRouteHistory({
    required this.agentId,
    required this.agentName,
    required this.employeeId,
    required this.phone,
    required this.status,
    this.punchInTime,
    this.punchInAddress = 'Jonapur Head Office (Dalmia Farm)',
    this.punchInLat = 28.4624272,
    this.punchInLng = 77.1515298,
    this.currentLat = 28.4624272,
    this.currentLng = 77.1515298,
    this.currentAddress = 'Jonapur Head Office, New Delhi',
    this.distanceFromOfficeMeters = 0.0,
    this.estimatedTimeToOffice = 'At Office',
    this.totalDistanceTravelledKm = 0.0,
    this.batteryPercent = 100,
    this.waypoints = const [],
    this.officeLat = 28.4624272,
    this.officeLng = 77.1515298,
  });

  factory AgentGpsRouteHistory.fromJson(Map<String, dynamic> json) {
    final rawWaypoints = (json['waypoints'] ?? json['trail'] ?? json['points'] ?? []) as List;
    final parsedWaypoints = rawWaypoints
        .map((w) => AgentGpsWaypoint.fromJson(Map<String, dynamic>.from(w)))
        .toList();

    return AgentGpsRouteHistory(
      agentId: json['agentId'] as String? ?? json['id'] as String? ?? '',
      agentName: json['agentName'] as String? ?? json['name'] as String? ?? 'Agent',
      employeeId: json['employeeId'] as String? ?? 'SSR---',
      phone: json['phone'] as String? ?? '',
      status: json['status'] as String? ?? 'inOffice',
      punchInTime: json['punchInTime'] as String?,
      punchInAddress: json['punchInAddress'] as String? ?? 'Jonapur Head Office (Dalmia Farm)',
      punchInLat: (json['punchInLat'] as num?)?.toDouble() ?? 28.4624272,
      punchInLng: (json['punchInLng'] as num?)?.toDouble() ?? 77.1515298,
      currentLat: (json['currentLat'] as num?)?.toDouble() ?? (json['latitude'] as num?)?.toDouble() ?? 28.4624272,
      currentLng: (json['currentLng'] as num?)?.toDouble() ?? (json['longitude'] as num?)?.toDouble() ?? 77.1515298,
      currentAddress: json['currentAddress'] as String? ?? json['address'] as String? ?? 'Jonapur Head Office',
      distanceFromOfficeMeters: (json['distanceFromOfficeMeters'] as num?)?.toDouble() ?? 0.0,
      estimatedTimeToOffice: json['estimatedTimeToOffice'] as String? ?? 'At Office',
      totalDistanceTravelledKm: (json['totalDistanceTravelledKm'] as num?)?.toDouble() ?? 0.0,
      batteryPercent: json['batteryPercent'] as int? ?? 100,
      waypoints: parsedWaypoints,
      officeLat: (json['officeLat'] as num?)?.toDouble() ?? 28.4624272,
      officeLng: (json['officeLng'] as num?)?.toDouble() ?? 77.1515298,
    );
  }

  String get distanceFormatted {
    if (distanceFromOfficeMeters < 1000) {
      return '${distanceFromOfficeMeters.toStringAsFixed(0)} m';
    }
    return '${(distanceFromOfficeMeters / 1000).toStringAsFixed(2)} km';
  }

  bool get isPunchedIn => punchInTime != null && punchInTime!.isNotEmpty && status.toLowerCase() != 'offduty' && status.toLowerCase() != 'punchedout';
  bool get isOnline => isPunchedIn;
  bool get isInOffice => isOnline && (status.toLowerCase() == 'inoffice' || distanceFromOfficeMeters <= 200);
}

class AgentDailyWorkReport {
  final DateTime date;
  final String? punchInTime;
  final String? punchOutTime;
  final String totalWorkHours;
  final int screenTimeMinutes;
  final int totalCalls;
  final int connectedCalls;
  final int talkTimeMinutes;
  final int visitsScheduled;
  final int visitsDone;
  final int bookingsCount;
  final double bookingsRevenue;
  final String attendanceStatus; // 'Present', 'Late In', 'Absent', 'Week Off'
  final String gpsTrailSummary;
  final bool isWithinOffice;

  const AgentDailyWorkReport({
    required this.date,
    this.punchInTime,
    this.punchOutTime,
    this.totalWorkHours = '0h 0m',
    this.screenTimeMinutes = 0,
    this.totalCalls = 0,
    this.connectedCalls = 0,
    this.talkTimeMinutes = 0,
    this.visitsScheduled = 0,
    this.visitsDone = 0,
    this.bookingsCount = 0,
    this.bookingsRevenue = 0.0,
    this.attendanceStatus = 'Present',
    this.gpsTrailSummary = 'Jonapur Head Office',
    this.isWithinOffice = true,
  });

  factory AgentDailyWorkReport.fromJson(Map<String, dynamic> json) {
    return AgentDailyWorkReport(
      date: json['date'] != null
          ? (DateTime.tryParse(json['date'].toString()) ?? DateTime.now())
          : DateTime.now(),
      punchInTime: json['punchInTime'] as String?,
      punchOutTime: json['punchOutTime'] as String?,
      totalWorkHours: json['totalWorkHours'] as String? ?? '8h 30m',
      screenTimeMinutes: json['screenTimeMinutes'] as int? ?? 0,
      totalCalls: json['totalCalls'] as int? ?? 0,
      connectedCalls: json['connectedCalls'] as int? ?? 0,
      talkTimeMinutes: json['talkTimeMinutes'] as int? ?? 0,
      visitsScheduled: json['visitsScheduled'] as int? ?? 0,
      visitsDone: json['visitsDone'] as int? ?? 0,
      bookingsCount: json['bookingsCount'] as int? ?? 0,
      bookingsRevenue: (json['bookingsRevenue'] as num?)?.toDouble() ?? 0.0,
      attendanceStatus: json['attendanceStatus'] as String? ?? 'Present',
      gpsTrailSummary: json['gpsTrailSummary'] as String? ?? 'Jonapur Head Office',
      isWithinOffice: json['isWithinOffice'] as bool? ?? true,
    );
  }
}

class AgentCallLog {
  final String id;
  final String customerName;
  final String customerPhone;
  final DateTime callTime;
  final int durationSeconds;
  final String disposition;
  final String? notes;
  final String? recordingUrl;

  const AgentCallLog({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.callTime,
    required this.durationSeconds,
    required this.disposition,
    this.notes,
    this.recordingUrl,
  });

  factory AgentCallLog.fromJson(Map<String, dynamic> json) {
    return AgentCallLog(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      customerName: json['customerName'] as String? ?? json['clientName'] as String? ?? 'Client',
      customerPhone: json['customerPhone'] as String? ?? json['phone'] as String? ?? '',
      callTime: json['callTime'] != null
          ? (DateTime.tryParse(json['callTime'].toString()) ?? DateTime.now())
          : DateTime.now(),
      durationSeconds: json['durationSeconds'] as int? ?? json['duration'] as int? ?? 0,
      disposition: json['disposition'] as String? ?? 'Connected',
      notes: json['notes'] as String? ?? json['remarks'] as String?,
      recordingUrl: json['recordingUrl'] as String?,
    );
  }

  String get durationFormatted {
    final m = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class AgentDrilldownData {
  final TelecallerOverview agent;
  final List<AgentCallLog> callLogs;
  final AgentGpsRouteHistory? routeHistory;
  final List<AgentDailyWorkReport> dailyWorkReports;
  final String? firstPunchIn;
  final String? lastPunchOut;
  final int todayCalls;
  final int todayConnected;
  final int totalDurationSeconds;

  const AgentDrilldownData({
    required this.agent,
    required this.callLogs,
    this.routeHistory,
    this.dailyWorkReports = const [],
    this.firstPunchIn,
    this.lastPunchOut,
    this.todayCalls = 0,
    this.todayConnected = 0,
    this.totalDurationSeconds = 0,
  });
}

class CustomerBreakdownItem {
  final String id;
  final String customerName;
  final String customerPhone;
  final String? projectName;
  final String? budget;
  final DateTime timestamp;
  final String? notes;
  final String status; // 'visit_scheduled', 'visit_done', 'booking_done'
  final String? recordingUrl;

  const CustomerBreakdownItem({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    this.projectName,
    this.budget,
    required this.timestamp,
    this.notes,
    required this.status,
    this.recordingUrl,
  });

  factory CustomerBreakdownItem.fromJson(Map<String, dynamic> json) {
    return CustomerBreakdownItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      customerName: json['customerName'] as String? ?? json['name'] as String? ?? json['fullName'] as String? ?? 'Customer',
      customerPhone: json['customerPhone'] as String? ?? json['phone'] as String? ?? '',
      projectName: json['projectName'] as String? ?? json['project'] as String? ?? json['propertyType'] as String?,
      budget: json['budget']?.toString() ?? json['budgetRange'] as String?,
      timestamp: json['timestamp'] != null
          ? (DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now())
          : (json['date'] != null ? (DateTime.tryParse(json['date'].toString()) ?? DateTime.now()) : DateTime.now()),
      notes: json['notes'] as String? ?? json['remarks'] as String? ?? json['dispositionNotes'] as String?,
      status: json['status'] as String? ?? 'visit_scheduled',
      recordingUrl: json['recordingUrl'] as String?,
    );
  }

  CustomerBreakdownItem copyWithStatus(String newStatus) {
    return CustomerBreakdownItem(
      id: id,
      customerName: customerName,
      customerPhone: customerPhone,
      projectName: projectName,
      budget: budget,
      timestamp: timestamp,
      notes: notes,
      status: newStatus,
      recordingUrl: recordingUrl,
    );
  }

  String get formattedDate {
    final hr = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final ampm = timestamp.hour >= 12 ? 'PM' : 'AM';
    final min = timestamp.minute.toString().padLeft(2, '0');
    return '${timestamp.day} ${_monthName(timestamp.month)} ${timestamp.year}, $hr:$min $ampm';
  }

  static String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }
}

class AgentCustomerBreakdown {
  final TelecallerOverview agent;
  final List<CustomerBreakdownItem> visitScheduled;
  final List<CustomerBreakdownItem> visitDone;
  final List<CustomerBreakdownItem> bookingDone;
  final List<AgentCallLog> allCallLogs;

  const AgentCustomerBreakdown({
    required this.agent,
    this.visitScheduled = const [],
    this.visitDone = const [],
    this.bookingDone = const [],
    this.allCallLogs = const [],
  });
}

