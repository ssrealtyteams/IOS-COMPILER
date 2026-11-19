import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import '../../../../domain/entities/call.dart';
import '../../../../domain/entities/lead.dart';
import '../../../../data/repositories/remote_lead_repository.dart';
import '../../../../core/services/notification_service.dart';
import '../../leads/view_models/lead_list_view_model.dart';
import '../../auth/data/sources/local/local_auth_source_impl.dart';

enum DispositionStep {
  /// Step 1: Was the call connected or not?
  connectionStatus,

  /// Step 2: What was the outcome? (shown only after step 1)
  outcomeDetails,
}

@injectable
class DispositionViewModel extends ChangeNotifier {
  DispositionViewModel(this._leadRepo);
  final LeadRepository _leadRepo;

  // ── Step tracking ─────────────────────────────────
  DispositionStep _step = DispositionStep.connectionStatus;
  DispositionStep get step => _step;
  bool get isOnStep1 => _step == DispositionStep.connectionStatus;

  // Step 1: was the call connected?
  bool? _wasConnected;
  bool? get wasConnected => _wasConnected;

  // ── Step 2 State ──────────────────────────────────
  CallDisposition? _selectedDisposition;
  CallDisposition? get selectedDisposition => _selectedDisposition;

  String _remarks = '';
  String get remarks => _remarks;

  // Not Interested state
  String? _notInterestedCategory;
  String? get notInterestedCategory => _notInterestedCategory;

  // Booking Done state (Deal amount in Cr / Lac)
  String? _bookingDealAmount;
  String? get bookingDealAmount => _bookingDealAmount;

  String _bookingDealUnit = 'Cr'; // 'Cr' or 'Lac'
  String get bookingDealUnit => _bookingDealUnit;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  // Follow-up state (for Interested, Callback, Visit Scheduled)
  DateTime? _followupDate;
  DateTime? get followupDate => _followupDate;

  TimeOfDay? _followupTime;
  TimeOfDay? get followupTime => _followupTime;

  String _followupPriority = 'medium';
  String get followupPriority => _followupPriority;

  /// Dispositions that require date + time selection (Calendar + Clock)
  bool get showFollowup =>
      _selectedDisposition == CallDisposition.interested ||
      _selectedDisposition == CallDisposition.callback ||
      _selectedDisposition == CallDisposition.visitScheduled;

  /// Computed Booking Deal Amount in Crores (for metrics & leaderboard)
  double get bookingDealAmountInCr {
    final parsed = double.tryParse(_bookingDealAmount?.trim() ?? '0') ?? 0.0;
    if (_bookingDealUnit == 'Lac') {
      return parsed / 100.0;
    }
    return parsed;
  }

  /// Dispositions shown when call was CONNECTED (lost removed per requirement)
  static const connectedDispositions = [
    CallDisposition.interested,
    CallDisposition.callback,
    CallDisposition.visitScheduled,
    CallDisposition.visitDone,
    CallDisposition.closed, // Displays as "Booking Done"
    CallDisposition.notInterested,
  ];

  /// Dispositions shown when call was NOT CONNECTED
  static const notConnectedDispositions = [
    CallDisposition.notConnected,
    CallDisposition.busy,
    CallDisposition.ringing,
    CallDisposition.switchedOff,
    CallDisposition.notReachable,
    CallDisposition.wrongNumber,
  ];

  List<CallDisposition> get availableDispositions =>
      _wasConnected == true ? connectedDispositions : notConnectedDispositions;

  /// Validation check for saving disposition
  bool get canSave {
    if (_selectedDisposition == null) return false;

    // For Not Interested: BOTH MCQ category and typed remarks are mandatory
    if (_selectedDisposition == CallDisposition.notInterested) {
      return _notInterestedCategory != null && _remarks.trim().isNotEmpty;
    }

    // For Booking Done: Deal amount must be entered and > 0
    if (_selectedDisposition == CallDisposition.closed) {
      if (_bookingDealAmount == null || _bookingDealAmount!.trim().isEmpty) {
        return false;
      }
      final parsed = double.tryParse(_bookingDealAmount!.trim());
      return parsed != null && parsed > 0;
    }

    // For Followup/Callback/Visit/Interested: Date & Time are required
    if (showFollowup) {
      return _followupDate != null && _followupTime != null;
    }

    return true;
  }

  // ── Commands ───────────────────────────────────────
  void setConnected(bool connected) {
    _wasConnected = connected;
    _selectedDisposition = null;
    _notInterestedCategory = null;
    _bookingDealAmount = null;
    _bookingDealUnit = 'Cr';
    _remarks = '';
    _followupDate = null;
    _followupTime = null;
    _step = DispositionStep.outcomeDetails;
    notifyListeners();
  }

  void goBackToStep1() {
    _step = DispositionStep.connectionStatus;
    _wasConnected = null;
    _selectedDisposition = null;
    _notInterestedCategory = null;
    _bookingDealAmount = null;
    _bookingDealUnit = 'Cr';
    _remarks = '';
    _followupDate = null;
    _followupTime = null;
    notifyListeners();
  }

  void selectDisposition(CallDisposition disposition) {
    _selectedDisposition = disposition;
    _notInterestedCategory = null;
    if (_selectedDisposition != CallDisposition.closed) {
      _bookingDealAmount = null;
    }
    if (!showFollowup) {
      _followupDate = null;
      _followupTime = null;
    }
    notifyListeners();
  }

  void setBookingDealAmount(String value) {
    _bookingDealAmount = value;
    notifyListeners();
  }

  void setBookingDealUnit(String unit) {
    _bookingDealUnit = unit;
    notifyListeners();
  }

  void setNotInterestedCategory(String? category) {
    _notInterestedCategory = category;
    notifyListeners();
  }

  void setRemarks(String value) {
    _remarks = value;
    notifyListeners();
  }

  void setFollowupDate(DateTime date) {
    _followupDate = date;
    notifyListeners();
  }

  void setFollowupTime(TimeOfDay time) {
    _followupTime = time;
    notifyListeners();
  }

  void setFollowupPriority(String priority) {
    _followupPriority = priority;
    notifyListeners();
  }

  Future<void> saveDisposition({
    required String callId,
    required String leadId,
    required String durationDisplay,
    Lead? lead,
    String? recordingPath,
    String? recordingUrl,
  }) async {
    if (!canSave || _selectedDisposition == null) return;

    _isSaving = true;
    notifyListeners();

    try {
      DateTime? scheduledAt;
      if (showFollowup && _followupDate != null && _followupTime != null) {
        scheduledAt = DateTime(
          _followupDate!.year,
          _followupDate!.month,
          _followupDate!.day,
          _followupTime!.hour,
          _followupTime!.minute,
        );
      }

      String notes = _remarks.trim();
      if (_selectedDisposition == CallDisposition.notInterested) {
        notes = '[$_notInterestedCategory] ${_remarks.trim()}';
      } else if (_selectedDisposition == CallDisposition.closed) {
        notes = '[Booking Done] Deal Value: ₹${_bookingDealAmount?.trim()} $_bookingDealUnit${_remarks.trim().isNotEmpty ? " - ${_remarks.trim()}" : ""}';
      }

      String agentName = 'Agent';
      try {
        final user = await LocalAuthSourceImpl().getCurrentUser();
        if (user != null && user.fullName.isNotEmpty) {
          agentName = user.fullName;
        }
      } catch (_) {}

      final activity = Activity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        outcome: _selectedDisposition!.displayName,
        duration: durationDisplay,
        agentName: agentName,
        notes: notes,
        recordingPath: recordingPath,
        recordingUrl: recordingUrl,
      );

      await _leadRepo.addActivity(leadId, activity);

      LeadStatus newStatus = LeadStatus.contacted;
      if (_wasConnected == false) newStatus = LeadStatus.notConnected;
      if (_selectedDisposition == CallDisposition.interested) newStatus = LeadStatus.negotiation;
      if (_selectedDisposition == CallDisposition.callback) newStatus = LeadStatus.interested;
      if (_selectedDisposition == CallDisposition.visitScheduled) newStatus = LeadStatus.visitScheduled;
      if (_selectedDisposition == CallDisposition.visitDone) newStatus = LeadStatus.visitDone;
      if (_selectedDisposition == CallDisposition.closed) newStatus = LeadStatus.closedWon;
      if (_selectedDisposition == CallDisposition.notInterested) newStatus = LeadStatus.cold;

      await _leadRepo.updateStatus(leadId, newStatus);
      await Future.delayed(const Duration(milliseconds: 200));

      // Ringing alarm is EXCLUSIVELY scheduled for Call Back disposition in India timezone
      if (scheduledAt != null && _selectedDisposition == CallDisposition.callback) {
        Lead targetLead;
        if (lead != null) {
          targetLead = lead;
        } else {
          try {
            final leadResult = await _leadRepo.getLeadById(leadId);
            if (leadResult.isSuccess) {
              targetLead = leadResult.data;
            } else {
              targetLead = await RemoteLeadRepository.findOrCreateLead(
                leadId.replaceAll('manual-', ''),
              );
            }
          } catch (_) {
            targetLead = await RemoteLeadRepository.findOrCreateLead(
              leadId.replaceAll('manual-', ''),
            );
          }
        }

        await NotificationService.scheduleFollowupAlarm(targetLead, scheduledAt);
      }
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void reset() {
    _step = DispositionStep.connectionStatus;
    _wasConnected = null;
    _selectedDisposition = null;
    _notInterestedCategory = null;
    _bookingDealAmount = null;
    _bookingDealUnit = 'Cr';
    _remarks = '';
    _followupDate = null;
    _followupTime = null;
    _followupPriority = 'medium';
    _isSaving = false;
    notifyListeners();
  }
}
