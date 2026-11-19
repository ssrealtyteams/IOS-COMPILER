import 'package:equatable/equatable.dart';

enum FollowupStatus { pending, completed, missed, cancelled, rescheduled }
enum FollowupPriority { high, medium, low }
enum FollowupType { call, meeting, siteVisit, whatsapp, email }

class Followup extends Equatable {
  const Followup({
    required this.id,
    required this.leadId,
    this.leadName = 'Client',
    this.agentId,
    required this.scheduledAt,
    this.priority = FollowupPriority.medium,
    this.status = FollowupStatus.pending,
    this.type = FollowupType.call,
    this.callId,
    this.notes,
    this.completedAt,
    this.createdAt,
  });

  final String id;
  final String leadId;
  final String leadName;
  final String? agentId;
  final DateTime scheduledAt;
  final FollowupPriority priority;
  final FollowupStatus status;
  final FollowupType type;
  final String? callId;
  final String? notes;
  final DateTime? completedAt;
  final DateTime? createdAt;

  bool get isOverdue =>
      status == FollowupStatus.pending && scheduledAt.isBefore(DateTime.now());

  bool get isToday {
    final now = DateTime.now();
    return scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;
  }

  Followup copyWith({
    String? id,
    String? leadId,
    String? leadName,
    String? agentId,
    DateTime? scheduledAt,
    FollowupPriority? priority,
    FollowupStatus? status,
    FollowupType? type,
    String? callId,
    String? notes,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return Followup(
      id: id ?? this.id,
      leadId: leadId ?? this.leadId,
      leadName: leadName ?? this.leadName,
      agentId: agentId ?? this.agentId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      type: type ?? this.type,
      callId: callId ?? this.callId,
      notes: notes ?? this.notes,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, leadId, scheduledAt, status, type];
}

// ─── Activity (Timeline) ─────────────────────────────────────────────────────
class Activity extends Equatable {
  const Activity({
    required this.id,
    required this.action,
    required this.actorName,
    required this.createdAt,
    this.leadId,
    this.metadata = const {},
  });

  final String id;
  final String action;
  final String actorName;
  final DateTime createdAt;
  final String? leadId;
  final Map<String, dynamic> metadata;

  @override
  List<Object?> get props => [id, action, createdAt];
}
