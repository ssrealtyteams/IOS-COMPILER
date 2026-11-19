import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../../../../domain/entities/followup.dart';
import '../../../../core/error/result.dart';

@injectable
class FollowupViewModel extends ChangeNotifier {
  ViewState _state = const ViewState.initial();
  ViewState get state => _state;

  List<Followup> _pendingFollowups = [];
  List<Followup> get pendingFollowups => _pendingFollowups;

  List<Followup> _completedFollowups = [];
  List<Followup> get completedFollowups => _completedFollowups;

  Future<void> loadFollowups() async {
    _state = const ViewState.loading();
    notifyListeners();

    // Mock API delay
    await Future.delayed(const Duration(milliseconds: 600));

    final now = DateTime.now();
    _pendingFollowups = [
      Followup(
        id: 'f1',
        leadId: 'lead-1',
        agentId: 'user-1',
        scheduledAt: now.add(const Duration(hours: 2)),
        type: FollowupType.call,
        priority: FollowupPriority.high,
        status: FollowupStatus.pending,
        notes: 'Check if they liked the Sunset Towers brochure',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Followup(
        id: 'f2',
        leadId: 'lead-2',
        agentId: 'user-1',
        scheduledAt: now.add(const Duration(days: 1)),
        type: FollowupType.meeting,
        priority: FollowupPriority.medium,
        status: FollowupStatus.pending,
        notes: 'Site visit discussion',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];

    _completedFollowups = [
      Followup(
        id: 'f3',
        leadId: 'lead-3',
        agentId: 'user-1',
        scheduledAt: now.subtract(const Duration(hours: 5)),
        completedAt: now.subtract(const Duration(hours: 4)),
        type: FollowupType.whatsapp,
        priority: FollowupPriority.low,
        status: FollowupStatus.completed,
        notes: 'Sent pricing details',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];

    _state = const ViewState.success();
    notifyListeners();
  }

  Future<void> completeFollowup(String id, String completionNotes) async {
    final index = _pendingFollowups.indexWhere((f) => f.id == id);
    if (index == -1) return;

    final followup = _pendingFollowups[index];
    final completed = followup.copyWith(
      status: FollowupStatus.completed,
      completedAt: DateTime.now(),
      notes: '$completionNotes\n\nOriginal Note: ${followup.notes}',
    );

    _pendingFollowups.removeAt(index);
    _completedFollowups.insert(0, completed);
    notifyListeners();
  }
}
