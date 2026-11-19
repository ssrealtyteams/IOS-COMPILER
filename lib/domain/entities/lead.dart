import 'package:characters/characters.dart';
import 'package:equatable/equatable.dart';

// ─── Lead Status Enum ──────────────────────────────────────────────────────────
enum LeadStatus {
  newLead,
  contacted,
  interested,
  hot,
  warm,
  cold,
  visitScheduled,
  visitDone,
  negotiation,
  closedWon,
  closedLost,
  invalid,
  notConnected,
  missedCall;

  String get displayName => switch (this) {
        LeadStatus.newLead => 'New Lead',
        LeadStatus.contacted => 'Contacted',
        LeadStatus.interested => 'Interested',
        LeadStatus.hot => 'Hot Lead',
        LeadStatus.warm => 'Call Back',
        LeadStatus.cold => 'Not Interested',
        LeadStatus.visitScheduled => 'Visit Scheduled',
        LeadStatus.visitDone => 'Visit Done',
        LeadStatus.negotiation => 'In Negotiation',
        LeadStatus.closedWon => 'Booking Done',
        LeadStatus.closedLost => 'Closed Lost',
        LeadStatus.invalid => 'Invalid',
        LeadStatus.notConnected => 'Not Connected',
        LeadStatus.missedCall => 'Missed Call',
      };

  String get apiValue => switch (this) {
        LeadStatus.newLead => 'new',
        LeadStatus.contacted => 'contacted',
        LeadStatus.interested => 'interested',
        LeadStatus.hot => 'hot',
        LeadStatus.warm => 'warm',
        LeadStatus.cold => 'cold',
        LeadStatus.visitScheduled => 'visit_scheduled',
        LeadStatus.visitDone => 'visit_done',
        LeadStatus.negotiation => 'negotiation',
        LeadStatus.closedWon => 'closed_won',
        LeadStatus.closedLost => 'closed_lost',
        LeadStatus.invalid => 'invalid',
        LeadStatus.notConnected => 'not_connected',
        LeadStatus.missedCall => 'missed_call',
      };

  static LeadStatus fromApi(String value) => switch (value) {
        'new' || 'newLead' => LeadStatus.newLead,
        'contacted' => LeadStatus.contacted,
        'interested' || 'qualified' => LeadStatus.interested,
        'hot' => LeadStatus.hot,
        'warm' || 'followUp' || 'follow_up' => LeadStatus.warm,
        'cold' => LeadStatus.cold,
        'visit_scheduled' => LeadStatus.visitScheduled,
        'visit_done' || 'visitCompleted' => LeadStatus.visitDone,
        'negotiation' => LeadStatus.negotiation,
        'closed_won' => LeadStatus.closedWon,
        'closed_lost' || 'lost' => LeadStatus.closedLost,
        'invalid' => LeadStatus.invalid,
        'not_connected' || 'unreachable' => LeadStatus.notConnected,
        'missed_call' || 'attempted' => LeadStatus.missedCall,
        _ => LeadStatus.newLead,
      };
}

enum LeadPriority {
  high,
  medium,
  low;

  String get displayName => switch (this) {
        LeadPriority.high => 'High',
        LeadPriority.medium => 'Medium',
        LeadPriority.low => 'Low',
      };

  static LeadPriority fromApi(String value) => switch (value) {
        'high' => LeadPriority.high,
        'low' => LeadPriority.low,
        _ => LeadPriority.medium,
      };
}

// ─── Lead Entity ─────────────────────────────────────────────────────────────
class Lead extends Equatable {
  const Lead({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.status,
    required this.priority,
    required this.source,
    required this.createdAt,
    this.email,
    this.alternatePhone,
    this.projectId,
    this.projectName,
    this.budgetMin,
    this.budgetMax,
    this.location,
    this.propertyType,
    this.unitType,
    this.formattedDate,
    this.formattedTime,
    this.leadAge,
    this.fullPropertyTitle,
    this.assignedToId,
    this.assignedToName,
    this.lastActivityAt,
    this.tags = const [],
  });

  final String id;
  final String fullName;
  final String phone;
  final LeadStatus status;
  final LeadPriority priority;
  final String source;
  final DateTime createdAt;
  final String? email;
  final String? alternatePhone;
  final String? projectId;
  final String? projectName;
  final double? budgetMin;
  final double? budgetMax;
  final String? location;
  final String? propertyType;
  final String? unitType;
  final String? formattedDate;
  final String? formattedTime;
  final String? leadAge;
  final String? fullPropertyTitle;
  final String? assignedToId;
  final String? assignedToName;
  final DateTime? lastActivityAt;
  final List<String> tags;

  String get initials {
    final clean = fullName.trim();
    if (clean.isEmpty) return 'L';
    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) {
      final w1 = words[0].characters.firstOrNull;
      final w2 = words[1].characters.firstOrNull;
      if (w1 != null && w2 != null) {
        return '$w1$w2'.toUpperCase();
      }
    }
    return clean.characters.first.toUpperCase();
  }

  String get timeAgoDisplay {
    if (leadAge != null && leadAge!.isNotEmpty) {
      return leadAge!;
    }
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  String get incomingDateTimeDisplay {
    final dt = createdAt;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final m = months[dt.month - 1];
    final yr = (dt.year % 100).toString().padLeft(2, '0');
    final hr = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $m $yr, ${hr.toString().padLeft(2, '0')}:$min $ampm';
  }

  Lead copyWith({
    String? id,
    String? fullName,
    String? phone,
    LeadStatus? status,
    LeadPriority? priority,
    String? source,
    DateTime? createdAt,
    String? email,
    String? alternatePhone,
    String? projectId,
    String? projectName,
    double? budgetMin,
    double? budgetMax,
    String? location,
    String? propertyType,
    String? unitType,
    String? formattedDate,
    String? formattedTime,
    String? leadAge,
    String? fullPropertyTitle,
    String? assignedToId,
    String? assignedToName,
    DateTime? lastActivityAt,
    List<String>? tags,
  }) {
    return Lead(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      email: email ?? this.email,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      location: location ?? this.location,
      propertyType: propertyType ?? this.propertyType,
      unitType: unitType ?? this.unitType,
      formattedDate: formattedDate ?? this.formattedDate,
      formattedTime: formattedTime ?? this.formattedTime,
      leadAge: leadAge ?? this.leadAge,
      fullPropertyTitle: fullPropertyTitle ?? this.fullPropertyTitle,
      assignedToId: assignedToId ?? this.assignedToId,
      assignedToName: assignedToName ?? this.assignedToName,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        phone,
        status,
        priority,
        lastActivityAt,
        tags,
      ];
      
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'status': status.apiValue,
      'priority': priority.name,
      'source': source,
      'createdAt': createdAt.toIso8601String(),
      'email': email,
      'alternatePhone': alternatePhone,
      'projectId': projectId,
      'projectName': projectName,
      'budgetMin': budgetMin,
      'budgetMax': budgetMax,
      'location': location,
      'propertyType': propertyType,
      'unitType': unitType,
      'formattedDate': formattedDate,
      'formattedTime': formattedTime,
      'leadAge': leadAge,
      'fullPropertyTitle': fullPropertyTitle,
      'assignedToId': assignedToId,
      'assignedToName': assignedToName,
      'lastActivityAt': lastActivityAt?.toIso8601String(),
      'tags': tags,
    };
  }

  factory Lead.fromJson(Map<String, dynamic> json) {
    DateTime createdParsed = DateTime.now();
    try {
      if (json['createdAt'] != null) {
        createdParsed = DateTime.parse(json['createdAt'] as String);
      }
    } catch (_) {}

    return Lead(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      fullName: json['fullName'] as String? ?? 'Website Lead',
      phone: json['phone'] as String? ?? '',
      status: LeadStatus.fromApi((json['status'] as String?) ?? 'new'),
      priority: LeadPriority.fromApi((json['priority'] as String?) ?? 'medium'),
      source: json['source'] as String? ?? 'Website',
      createdAt: createdParsed,
      email: json['email'] as String?,
      alternatePhone: json['alternatePhone'] as String?,
      projectId: json['projectId'] as String?,
      projectName: json['projectName'] as String?,
      budgetMin: (json['budgetMin'] as num?)?.toDouble(),
      budgetMax: (json['budgetMax'] as num?)?.toDouble(),
      location: json['location'] as String?,
      propertyType: json['propertyType'] as String?,
      unitType: (json['unitType'] ?? json['propertyType']) as String?,
      formattedDate: json['formattedDate'] as String?,
      formattedTime: json['formattedTime'] as String?,
      leadAge: json['leadAge'] as String?,
      fullPropertyTitle: json['fullPropertyTitle'] as String?,
      assignedToId: json['assignedToId'] as String?,
      assignedToName: json['assignedToName'] as String?,
      lastActivityAt: json['lastActivityAt'] != null ? DateTime.tryParse(json['lastActivityAt'] as String) : null,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
    );
  }
}
