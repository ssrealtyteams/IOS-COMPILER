import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import '../../../../domain/entities/visit.dart';
import '../../../../core/error/result.dart';

@injectable
class VisitViewModel extends ChangeNotifier {
  ViewState _state = const ViewState.initial();
  ViewState get state => _state;

  List<Visit> _upcomingVisits = [];
  List<Visit> get upcomingVisits => _upcomingVisits;

  List<Visit> _completedVisits = [];
  List<Visit> get completedVisits => _completedVisits;

  Future<void> loadVisits() async {
    _state = const ViewState.loading();
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    final now = DateTime.now();
    _upcomingVisits = [
      Visit(
        id: 'v1',
        leadId: 'lead-1',
        projectId: 'p1',
        agentId: 'user-1',
        scheduledAt: now.add(const Duration(days: 1, hours: 2)),
        status: VisitStatus.scheduled,
        notes: 'Client bringing family',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    _completedVisits = [
      Visit(
        id: 'v2',
        leadId: 'lead-2',
        projectId: 'p2',
        agentId: 'user-1',
        scheduledAt: now.subtract(const Duration(days: 1)),
        status: VisitStatus.completed,
        completedAt: now.subtract(const Duration(days: 1, hours: -1)),
        notes: 'Very interested, negotiating price',
        locationCheckIn: '18.5204,73.8567',
        createdAt: now.subtract(const Duration(days: 4)),
      ),
    ];

    _state = const ViewState.success();
    notifyListeners();
  }

  Future<void> scheduleVisit({
    required String leadId,
    required String projectId,
    required DateTime date,
    required TimeOfDay time,
    String? notes,
  }) async {
    final scheduledAt = DateTime(
      date.year, date.month, date.day, time.hour, time.minute,
    );
    
    final visit = Visit(
      id: 'v_${DateTime.now().millisecondsSinceEpoch}',
      leadId: leadId,
      projectId: projectId,
      agentId: 'user-1',
      scheduledAt: scheduledAt,
      status: VisitStatus.scheduled,
      notes: notes,
      createdAt: DateTime.now(),
    );

    _upcomingVisits.insert(0, visit);
    // Sort by scheduledAt
    _upcomingVisits.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    
    notifyListeners();
  }

  Future<void> completeVisit(String id, String checkInCoords, String notes) async {
    final index = _upcomingVisits.indexWhere((v) => v.id == id);
    if (index == -1) return;

    final visit = _upcomingVisits[index];
    final completed = visit.copyWith(
      status: VisitStatus.completed,
      completedAt: DateTime.now(),
      locationCheckIn: checkInCoords,
      notes: notes.isNotEmpty ? notes : visit.notes,
    );

    _upcomingVisits.removeAt(index);
    _completedVisits.insert(0, completed);
    notifyListeners();
  }
}
