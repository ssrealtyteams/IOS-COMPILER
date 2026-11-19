import 'package:equatable/equatable.dart';

enum CallType { outgoing, incoming, missed }
enum CallStatus { dialing, connected, ended, rejected, busy, missed, notReachable }

enum CallDisposition {
  connected,
  notConnected,
  busy,
  ringing,
  switchedOff,
  notReachable,
  wrongNumber,
  interested,
  notInterested,
  callback,
  hotLead,
  warmLead,
  coldLead,
  visitScheduled,
  visitDone,
  followup,
  closed,
  lost;

  String get displayName => switch (this) {
        CallDisposition.connected => 'Connected',
        CallDisposition.notConnected => 'Not Connected',
        CallDisposition.busy => 'Busy',
        CallDisposition.ringing => 'Ringing',
        CallDisposition.switchedOff => 'Switched Off',
        CallDisposition.notReachable => 'Not Reachable',
        CallDisposition.wrongNumber => 'Wrong Number',
        CallDisposition.interested => 'Interested',
        CallDisposition.notInterested => 'Not Interested',
        CallDisposition.callback => 'Call Back',
        CallDisposition.hotLead => 'Hot Lead',
        CallDisposition.warmLead => 'Warm Lead',
        CallDisposition.coldLead => 'Cold Lead',
        CallDisposition.visitScheduled => 'Visit Scheduled',
        CallDisposition.visitDone => 'Visit Done',
        CallDisposition.followup => 'Follow Up',
        CallDisposition.closed => 'Booking Done',
        CallDisposition.lost => 'Lost',
      };

  String get apiValue => switch (this) {
        CallDisposition.connected => 'connected',
        CallDisposition.notConnected => 'not_connected',
        CallDisposition.busy => 'busy',
        CallDisposition.ringing => 'ringing',
        CallDisposition.switchedOff => 'switched_off',
        CallDisposition.notReachable => 'not_reachable',
        CallDisposition.wrongNumber => 'wrong_number',
        CallDisposition.interested => 'interested',
        CallDisposition.notInterested => 'not_interested',
        CallDisposition.callback => 'callback',
        CallDisposition.hotLead => 'hot_lead',
        CallDisposition.warmLead => 'warm_lead',
        CallDisposition.coldLead => 'cold_lead',
        CallDisposition.visitScheduled => 'visit_scheduled',
        CallDisposition.visitDone => 'visit_done',
        CallDisposition.followup => 'followup',
        CallDisposition.closed => 'closed',
        CallDisposition.lost => 'lost',
      };

  bool get isPositive => [
        CallDisposition.connected,
        CallDisposition.interested,
        CallDisposition.callback,
        CallDisposition.hotLead,
        CallDisposition.warmLead,
        CallDisposition.visitScheduled,
        CallDisposition.visitDone,
        CallDisposition.followup,
        CallDisposition.closed,
      ].contains(this);

  bool get requiresFollowup => [
        CallDisposition.interested,
        CallDisposition.notInterested,
        CallDisposition.callback,
        CallDisposition.hotLead,
        CallDisposition.warmLead,
        CallDisposition.coldLead,
        CallDisposition.followup,
      ].contains(this);

  static CallDisposition fromApi(String value) => CallDisposition.values
      .firstWhere((e) => e.apiValue == value, orElse: () => CallDisposition.connected);
}

class Call extends Equatable {
  const Call({
    required this.id,
    required this.type,
    required this.status,
    required this.phoneNumber,
    required this.durationSeconds,
    required this.startedAt,
    this.leadId,
    this.leadName,
    this.agentId,
    this.connectedAt,
    this.endedAt,
    this.disposition,
    this.remarks,
    this.recordingPath,
    this.recordingUrl,
    this.isSynced = false,
  });

  final String id;
  final CallType type;
  final CallStatus status;
  final String phoneNumber;
  final int durationSeconds;
  final DateTime startedAt;
  final String? leadId;
  final String? leadName;
  final String? agentId;
  final DateTime? connectedAt;
  final DateTime? endedAt;
  final CallDisposition? disposition;
  final String? remarks;
  final String? recordingPath;
  final String? recordingUrl;
  final bool isSynced;

  String get durationDisplay {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  Call copyWith({
    String? id,
    CallType? type,
    CallStatus? status,
    String? phoneNumber,
    int? durationSeconds,
    DateTime? startedAt,
    String? leadId,
    String? leadName,
    String? agentId,
    DateTime? connectedAt,
    DateTime? endedAt,
    CallDisposition? disposition,
    String? remarks,
    String? recordingPath,
    String? recordingUrl,
    bool? isSynced,
  }) {
    return Call(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      startedAt: startedAt ?? this.startedAt,
      leadId: leadId ?? this.leadId,
      leadName: leadName ?? this.leadName,
      agentId: agentId ?? this.agentId,
      connectedAt: connectedAt ?? this.connectedAt,
      endedAt: endedAt ?? this.endedAt,
      disposition: disposition ?? this.disposition,
      remarks: remarks ?? this.remarks,
      recordingPath: recordingPath ?? this.recordingPath,
      recordingUrl: recordingUrl ?? this.recordingUrl,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  List<Object?> get props => [id, type, status, phoneNumber, durationSeconds, startedAt, recordingUrl];
}
