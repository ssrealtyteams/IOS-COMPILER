import 'package:equatable/equatable.dart';

enum VisitStatus { scheduled, completed, cancelled, missed }

class Visit extends Equatable {
  final String id;
  final String leadId;
  final String leadName;
  final String? leadPhone;
  final String? projectId;
  final String? projectName;
  final String? agentId;
  final DateTime scheduledAt;
  final VisitStatus status;
  final String? notes;
  final String? siteLocation;
  final String? locationCheckIn;
  final DateTime? completedAt;
  final DateTime? createdAt;

  const Visit({
    required this.id,
    required this.leadId,
    this.leadName = 'Client',
    this.leadPhone,
    this.projectId,
    this.projectName,
    this.agentId,
    required this.scheduledAt,
    this.status = VisitStatus.scheduled,
    this.notes,
    this.siteLocation,
    this.locationCheckIn,
    this.completedAt,
    this.createdAt,
  });

  Visit copyWith({
    String? id,
    String? leadId,
    String? leadName,
    String? leadPhone,
    String? projectId,
    String? projectName,
    String? agentId,
    DateTime? scheduledAt,
    VisitStatus? status,
    String? notes,
    String? siteLocation,
    String? locationCheckIn,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return Visit(
      id: id ?? this.id,
      leadId: leadId ?? this.leadId,
      leadName: leadName ?? this.leadName,
      leadPhone: leadPhone ?? this.leadPhone,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      agentId: agentId ?? this.agentId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      siteLocation: siteLocation ?? this.siteLocation,
      locationCheckIn: locationCheckIn ?? this.locationCheckIn,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, leadId, leadName, scheduledAt, status];
}
