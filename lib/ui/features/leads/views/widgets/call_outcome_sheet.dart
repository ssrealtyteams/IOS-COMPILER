import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/services/notification_service.dart';
import '../../../../../domain/entities/lead.dart';
import 'package:sales_crm_dialer/ui/common/widgets/app_date_time_picker.dart';

// ─── Data Models ──────────────────────────────────────────────────────────────

enum CallConnection { connected, notConnected }
enum CallOutcomeType { interested, notInterested }
enum NotConnectedReason { ringing, busy, switchedOff, notReachable }
enum NextAction { callBackLater, visitSet, visitDone, booking }

class CallOutcomeResult {
  const CallOutcomeResult({
    required this.connection,
    this.notConnectedReason,
    this.outcome,
    this.notInterestedReason,
    this.nextAction,
    this.visitDay,
    this.visitTime,
    this.bookingAmount,
    this.downpaymentAmount,
  });

  final CallConnection connection;
  final NotConnectedReason? notConnectedReason;
  final CallOutcomeType? outcome;
  final String? notInterestedReason;
  final NextAction? nextAction;
  final String? visitDay;
  final TimeOfDay? visitTime;
  final String? bookingAmount;
  final String? downpaymentAmount;

  LeadStatus toLeadStatus(LeadStatus currentStatus) {
    if (connection == CallConnection.notConnected) return currentStatus;
    if (outcome == CallOutcomeType.notInterested) return LeadStatus.cold;
    if (nextAction == NextAction.visitSet) return LeadStatus.visitScheduled;
    if (nextAction == NextAction.visitDone) return LeadStatus.visitDone;
    if (nextAction == NextAction.booking) return LeadStatus.closedWon;
    return LeadStatus.interested;
  }
}

// ─── Main Sheet ───────────────────────────────────────────────────────────────

Future<CallOutcomeResult?> showCallOutcomeSheet(
  BuildContext context,
  Lead lead,
) {
  return showModalBottomSheet<CallOutcomeResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CallOutcomeSheet(lead: lead),
  );
}

class _CallOutcomeSheet extends StatefulWidget {
  const _CallOutcomeSheet({required this.lead});
  final Lead lead;

  @override
  State<_CallOutcomeSheet> createState() => _CallOutcomeSheetState();
}

class _CallOutcomeSheetState extends State<_CallOutcomeSheet> {
  // Step tracking
  int _step = 0;

  // Selections
  CallConnection? _connection;
  NotConnectedReason? _notConnectedReason;
  CallOutcomeType? _outcome;
  String? _notInterestedCategory; // MCQ selected category
  String? _notInterestedReason;   // Typed remark (mandatory)
  NextAction? _nextAction;
  // Shared date+time for both CallBack and Visit scheduling
  DateTime? _visitDate;
  TimeOfDay? _visitTime;

  final _reasonController = TextEditingController();
  final _bookingAmtCtrl = TextEditingController();
  final _downpaymentAmtCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // If lead is already interested, skip to interested actions
    if (widget.lead.status == LeadStatus.interested ||
        widget.lead.status == LeadStatus.visitScheduled) {
      _connection = CallConnection.connected;
      _outcome = CallOutcomeType.interested;
      _step = 3; // Skip to next action step
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _bookingAmtCtrl.dispose();
    _downpaymentAmtCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    DateTime? visitDateTime = _visitDate;
    if (visitDateTime != null && _visitTime != null) {
      visitDateTime = DateTime(
        visitDateTime.year,
        visitDateTime.month,
        visitDateTime.day,
        _visitTime!.hour,
        _visitTime!.minute,
      );
    }
    final result = CallOutcomeResult(
      connection: _connection!,
      notConnectedReason: _notConnectedReason,
      outcome: _outcome,
      notInterestedReason: _notInterestedReason ?? _reasonController.text.trim(),
      nextAction: _nextAction,
      visitDay: visitDateTime != null
          ? '${visitDateTime.day}/${visitDateTime.month}/${visitDateTime.year}'
          : null,
      visitTime: _visitTime,
      bookingAmount: _bookingAmtCtrl.text.trim().isNotEmpty ? _bookingAmtCtrl.text.trim() : null,
      downpaymentAmount: _downpaymentAmtCtrl.text.trim().isNotEmpty ? _downpaymentAmtCtrl.text.trim() : null,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    // Not Interested step has 7 cards + text field — needs scroll
    final needsScroll = _step == 2 && _outcome == CallOutcomeType.notInterested;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // For not-interested step, allow taller sheet
      constraints: BoxConstraints(
        maxHeight: needsScroll
            ? MediaQuery.of(context).size.height * 0.92
            : MediaQuery.of(context).size.height * 0.75,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Fixed: Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE0D5C0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // ── Fixed: Lead info header
          _buildLeadHeader(),
          const SizedBox(height: 20),
          // ── Fixed: Step progress indicator
          _buildStepIndicator(),
          const SizedBox(height: 20),
          // ── Scrollable: Step content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _buildCurrentStep(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadHeader() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.ssGold.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              widget.lead.initials,
              style: TextStyle(
                color: AppColors.ssGoldDark,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.lead.fullName,
                  style: AppTypography.titleSmall.copyWith(
                    color: const Color(0xFF3E2723),
                  )),
              Text(widget.lead.phone,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  )),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.ssGold.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.ssGold.withAlpha(60)),
          ),
          child: Text(
            'Call Outcome',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.ssGoldDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    final steps = widget.lead.status == LeadStatus.interested ||
            widget.lead.status == LeadStatus.visitScheduled
        ? ['Action', 'Schedule']
        : ['Status', 'Result', 'Details', 'Schedule'];
    final currentStep = widget.lead.status == LeadStatus.interested ||
            widget.lead.status == LeadStatus.visitScheduled
        ? _step - 3
        : _step;

    return Row(
      children: steps.asMap().entries.map((e) {
        final active = e.key <= currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.ssGoldDark
                        : const Color(0xFFE8D5B5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (e.key < steps.length - 1) const SizedBox(width: 4),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildConnectionStep();
      case 1:
        return _connection == CallConnection.notConnected
            ? _buildNotConnectedReasonStep()
            : _buildOutcomeStep();
      case 2:
        return _outcome == CallOutcomeType.notInterested
            ? _buildNotInterestedReasonStep()
            : _buildNextActionStep();
      case 3:
        return _buildNextActionStep();
      case 4:
        return _buildVisitDateTimeStep();
      case 5:
        return _buildBookingDetailsStep();
      default:
        return const SizedBox();
    }
  }

  // ── Step 0: Connected? ──────────────────────────────────────────────────────
  Widget _buildConnectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Did the call connect?',
            style: AppTypography.titleSmall.copyWith(
              color: const Color(0xFF3E2723),
            )),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _BigOptionButton(
                label: '✅ Connected',
                description: 'Call was answered',
                color: const Color(0xFF2E7D32),
                bgColor: const Color(0xFFE8F5E9),
                onTap: () {
                  setState(() {
                    _connection = CallConnection.connected;
                    _step = 1;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BigOptionButton(
                label: '❌ Not Connected',
                description: 'Call not answered',
                color: const Color(0xFFBF360C),
                bgColor: const Color(0xFFFBE9E7),
                onTap: () {
                  setState(() {
                    _connection = CallConnection.notConnected;
                    _step = 1;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 1 (Not Connected): Reason ─────────────────────────────────────────
  Widget _buildNotConnectedReasonStep() {
    final reasons = [
      (NotConnectedReason.ringing, '📳 Ringing', 'Phone rang but no answer'),
      (NotConnectedReason.busy, '🔴 Busy', 'Line was busy'),
      (NotConnectedReason.switchedOff, '📴 Switched Off', 'Phone was off'),
      (NotConnectedReason.notReachable, '🚫 Not Reachable', 'Out of coverage'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Why was it not connected?',
            style: AppTypography.titleSmall.copyWith(
              color: const Color(0xFF3E2723),
            )),
        const SizedBox(height: 16),
        ...reasons.map((r) => _ReasonTile(
              label: r.$2,
              description: r.$3,
              selected: _notConnectedReason == r.$1,
              onTap: () => setState(() => _notConnectedReason = r.$1),
            )),
        const SizedBox(height: 16),
        _ActionButton(
          label: 'Save Outcome',
          enabled: _notConnectedReason != null,
          onTap: _submit,
        ),
      ],
    );
  }

  // ── Step 1 (Connected): Outcome ────────────────────────────────────────────
  Widget _buildOutcomeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What was the outcome?',
            style: AppTypography.titleSmall.copyWith(
              color: const Color(0xFF3E2723),
            )),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _BigOptionButton(
                label: '🌟 Interested',
                description: 'Customer is interested',
                color: const Color(0xFF8B6914),
                bgColor: const Color(0xFFFFF8E1),
                onTap: () {
                  setState(() {
                    _outcome = CallOutcomeType.interested;
                    _step = 2;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BigOptionButton(
                label: '👎 Not Interested',
                description: 'Customer declined',
                color: const Color(0xFF616161),
                bgColor: const Color(0xFFF5F5F5),
                onTap: () {
                  setState(() {
                    _outcome = CallOutcomeType.notInterested;
                    _step = 2;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 2 (Not Interested): Reason ────────────────────────────────────────
  Widget _buildNotInterestedReasonStep() {
    // Real-estate specific MCQ categories
    final categories = [
      (
        '💰',
        'Budget Too High',
        'Property price exceeds budget',
        const Color(0xFFE53935),
        const Color(0xFFFFEBEE),
      ),
      (
        '📍',
        'Location Not Suitable',
        'Area/locality doesn\'t match',
        const Color(0xFF1565C0),
        const Color(0xFFE3F2FD),
      ),
      (
        '🏗️',
        'Project Not Matching',
        'Size, type or specs don\'t fit needs',
        const Color(0xFF6A1B9A),
        const Color(0xFFF3E5F5),
      ),
      (
        '👨\u200d👩\u200d👧',
        'Family Not Convinced',
        'Disagreement within family',
        const Color(0xFF00695C),
        const Color(0xFFE0F2F1),
      ),
      (
        '🏠',
        'Already Purchased',
        'Bought property elsewhere',
        const Color(0xFF2E7D32),
        const Color(0xFFE8F5E9),
      ),
      (
        '⏰',
        'Not Looking Right Now',
        'Wrong timing, will look later',
        const Color(0xFFE65100),
        const Color(0xFFFFF3E0),
      ),
      (
        '🏦',
        'Loan / Finance Issue',
        'Bank loan not approved',
        const Color(0xFF37474F),
        const Color(0xFFECEFF1),
      ),
    ];

    final remarkFilled = _notInterestedReason != null &&
        _notInterestedReason!.trim().isNotEmpty;
    final canSave = _notInterestedCategory != null && remarkFilled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.thumb_down_rounded,
                  size: 20, color: Color(0xFFE53935)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why Not Interested?',
                    style: AppTypography.titleSmall.copyWith(
                      color: const Color(0xFF3E2723),
                    ),
                  ),
                  Text(
                    'Select reason + add remark (both mandatory)',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Step 1 label
        _StepLabel(number: '1', text: 'Select reason'),
        const SizedBox(height: 10),

        // ── MCQ Category Cards
        ...categories.map((cat) {
          final emoji = cat.$1;
          final title = cat.$2;
          final subtitle = cat.$3;
          final color = cat.$4;
          final bg = cat.$5;
          final isSelected = _notInterestedCategory == title;

          return GestureDetector(
            onTap: () => setState(() => _notInterestedCategory = title),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isSelected ? bg : Colors.white,
                borderRadius: AppRadius.borderRadiusMd,
                border: Border.all(
                  color: isSelected ? color : const Color(0xFFE8E0D5),
                  width: isSelected ? 1.8 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withAlpha(30),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // Emoji + color dot
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected ? color.withAlpha(20) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(emoji,
                          style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? color : const Color(0xFF3E2723),
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? color.withAlpha(180)
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Selection indicator
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isSelected
                        ? Icon(Icons.check_circle_rounded,
                            key: const ValueKey('check'),
                            color: color,
                            size: 20)
                        : Icon(Icons.radio_button_unchecked_rounded,
                            key: const ValueKey('empty'),
                            color: const Color(0xFFBDBDBD),
                            size: 20),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 16),

        // ── Step 2 label
        _StepLabel(number: '2', text: 'Add remark (mandatory)'),
        const SizedBox(height: 10),

        // ── Remark text field
        TextField(
          controller: _reasonController,
          decoration: InputDecoration(
            hintText: _notInterestedCategory == null
                ? 'Select a reason above first...'
                : 'e.g. Customer has 1 Cr budget, property is 1.3 Cr...',
            hintStyle: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
            filled: true,
            fillColor: _notInterestedCategory != null
                ? const Color(0xFFFAF7F2)
                : const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: AppRadius.borderRadiusMd,
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.borderRadiusMd,
              borderSide: BorderSide(
                color: remarkFilled ? const Color(0xFF2E7D32) : AppColors.ssGold,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.borderRadiusMd,
              borderSide: BorderSide(
                color: remarkFilled
                    ? const Color(0xFF81C784)
                    : AppColors.border,
                width: remarkFilled ? 1.5 : 1,
              ),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            suffixIcon: remarkFilled
                ? const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32), size: 20)
                : null,
          ),
          maxLines: 3,
          enabled: _notInterestedCategory != null,
          onChanged: (v) => setState(() => _notInterestedReason = v.trim()),
        ),

        // ── Validation hint
        if (!canSave) ...[  
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _notInterestedCategory == null
                    ? Icons.info_outline_rounded
                    : Icons.edit_note_rounded,
                size: 13,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                _notInterestedCategory == null
                    ? 'Please select a reason'
                    : 'Please add a remark to continue',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 16),

        // ── Save Button
        _ActionButton(
          label: canSave ? '💾 Save Outcome' : 'Select reason & add remark',
          enabled: canSave,
          onTap: () {
            // Combine category + remark for the final reason
            _notInterestedReason =
                '$_notInterestedCategory: ${_reasonController.text.trim()}';
            _submit();
          },
        ),
      ],
    );
  }

  // ── Step 2 (Interested): Next Action ───────────────────────────────────────
  Widget _buildNextActionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What is the next step?',
            style: AppTypography.titleSmall.copyWith(
              color: const Color(0xFF3E2723),
            )),
        const SizedBox(height: 16),
        Row(
          children: [
            // ── Call Back Later → opens date+time picker + schedules alarm
            Expanded(
              child: _BigOptionButton(
                label: '📞 Call Back Later',
                description: 'Set reminder & alarm',
                color: const Color(0xFF00838F),
                bgColor: const Color(0xFFE0F7FA),
                onTap: () {
                  setState(() {
                    _nextAction = NextAction.callBackLater;
                    _visitDate = null;
                    _visitTime = null;
                    _step = 4; // → date+time picker step
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            // ── Visit Set → opens date+time picker (no alarm)
            Expanded(
              child: _BigOptionButton(
                label: '🏠 Visit Set',
                description: 'Schedule a site visit',
                color: const Color(0xFF8B6914),
                bgColor: const Color(0xFFFFF8E1),
                onTap: () {
                  setState(() {
                    _nextAction = NextAction.visitSet;
                    _visitDate = null;
                    _visitTime = null;
                    _step = 4; // → date+time picker step
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // ── Visit Done → direct submit, no calendar
            Expanded(
              child: _BigOptionButton(
                label: '🤝 Visit Done',
                description: 'Site visit completed',
                color: const Color(0xFF2E7D32),
                bgColor: const Color(0xFFE8F5E9),
                onTap: () {
                  setState(() => _nextAction = NextAction.visitDone);
                  _submit();
                },
              ),
            ),
            const SizedBox(width: 12),
            // ── Booking → booking details form, no calendar
            Expanded(
              child: _BigOptionButton(
                label: '🎉 Booking',
                description: 'Property booked',
                color: const Color(0xFF4527A0),
                bgColor: const Color(0xFFEDE7F6),
                onTap: () {
                  setState(() {
                    _nextAction = NextAction.booking;
                    _step = 5;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 5: Booking Details ──────────────────────────────────────────────
  Widget _buildBookingDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Booking Details',
            style: AppTypography.titleSmall.copyWith(
              color: const Color(0xFF3E2723),
            )),
        const SizedBox(height: 16),
        TextField(
          controller: _bookingAmtCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Deal Value (in Cr)',
            hintText: 'e.g. 1.2',
            border: OutlineInputBorder(borderRadius: AppRadius.borderRadiusMd),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _downpaymentAmtCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Downpayment (in Lacs)',
            hintText: 'e.g. 12',
            border: OutlineInputBorder(borderRadius: AppRadius.borderRadiusMd),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 24),
        _ActionButton(
          label: 'Save Booking',
          enabled: true,
          onTap: _submit,
        ),
      ],
    );
  }

  // ── Step 4: Date + Time Picker (shared for Call Back & Visit Set) ──────────
  Widget _buildVisitDateTimeStep() {
    final isCallBack = _nextAction == NextAction.callBackLater;


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title changes based on action type
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCallBack
                    ? const Color(0xFFE0F7FA)
                    : const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isCallBack ? Icons.phone_callback_rounded : Icons.home_work_rounded,
                size: 22,
                color: isCallBack ? const Color(0xFF00838F) : AppColors.ssGoldDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCallBack ? 'Schedule Call Back' : 'Schedule Site Visit',
                    style: AppTypography.titleSmall.copyWith(
                      color: const Color(0xFF3E2723),
                    ),
                  ),
                  Text(
                    isCallBack
                        ? '⏰ Alarm will ring at selected time'
                        : 'Select date & time for the visit',
                    style: TextStyle(
                      fontSize: 11,
                      color: isCallBack
                          ? const Color(0xFF00838F)
                          : AppColors.textTertiary,
                      fontWeight: isCallBack ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Date + Time tap button
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final defaultTime = TimeOfDay.now();
            final pickerColor = isCallBack ? const Color(0xFF00838F) : AppColors.ssGoldDark;

            // Step 1: Calendar (date)
            final pickedDate = await showAppDatePicker(
              context: context,
              initialDate: _visitDate ?? today,
              firstDate: today,
              lastDate: today.add(const Duration(days: 365)),
              helpText: isCallBack ? 'SELECT CALL BACK DATE' : 'SELECT VISIT DATE',
              primaryColor: pickerColor,
            );
            if (pickedDate == null || !mounted) return;

            // Step 2: Round clock (time)
            final pickedTime = await showAppTimePicker(
              context: context,
              initialTime: _visitTime ?? defaultTime,
              helpText: isCallBack ? 'SELECT CALL BACK TIME' : 'SELECT VISIT TIME',
              primaryColor: pickerColor,
            );
            if (!mounted) return;
            setState(() {
              _visitDate = pickedDate;
              if (pickedTime != null) _visitTime = pickedTime;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.borderRadiusMd,
              border: Border.all(
                color: _visitDate != null
                    ? (isCallBack ? const Color(0xFF00838F) : AppColors.ssGold)
                    : const Color(0xFFE8D5B5),
                width: _visitDate != null ? 1.5 : 1,
              ),
              boxShadow: _visitDate != null
                  ? [
                      BoxShadow(
                        color: (isCallBack
                                ? const Color(0xFF00838F)
                                : AppColors.ssGold)
                            .withAlpha(25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Calendar icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCallBack
                        ? const Color(0xFFE0F7FA)
                        : AppColors.ssGold.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    size: 20,
                    color: isCallBack
                        ? const Color(0xFF00838F)
                        : AppColors.ssGoldDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _visitDate != null
                            ? '${_visitDate!.day}/${_visitDate!.month}/${_visitDate!.year}'
                                '${_visitTime != null ? "  •  ${_visitTime!.format(context)}" : "  •  Tap to set time"}'
                            : (isCallBack
                                ? 'Select call back date & time'
                                : 'Select visit date & time'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _visitDate != null
                              ? const Color(0xFF3E2723)
                              : AppColors.textTertiary,
                        ),
                      ),
                      if (_visitDate == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  size: 10, color: AppColors.textTertiary),
                              const SizedBox(width: 4),
                              Text(
                                'Calendar opens → then clock',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isCallBack
                      ? const Color(0xFF00838F)
                      : AppColors.ssGoldDark,
                ),
              ],
            ),
          ),
        ),

        // ── Confirmation preview card
        if (_visitDate != null && _visitTime != null) ...[  
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isCallBack
                  ? const Color(0xFFE0F7FA)
                  : const Color(0xFFFFF8E1),
              borderRadius: AppRadius.borderRadiusMd,
              border: Border.all(
                color: isCallBack
                    ? const Color(0xFF00838F).withAlpha(60)
                    : AppColors.ssGold.withAlpha(60),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCallBack
                      ? Icons.alarm_rounded
                      : Icons.event_available_rounded,
                  size: 18,
                  color: isCallBack
                      ? const Color(0xFF00838F)
                      : const Color(0xFF8B6914),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_visitDate!.day}/${_visitDate!.month}/${_visitDate!.year} at ${_visitTime!.format(context)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isCallBack
                              ? const Color(0xFF006064)
                              : AppColors.ssGoldDark,
                        ),
                      ),
                      if (isCallBack)
                        Text(
                          '🔔 Alarm will ring even if app is closed',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF00838F),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        _ActionButton(
          label: isCallBack
              ? '🔔 Set Alarm & Save'
              : '✅ Confirm Visit',
          enabled: _visitDate != null && _visitTime != null,
          onTap: _submitWithSchedule,
        ),
      ],
    );
  }

  // ── Submit with optional alarm scheduling ─────────────────────────────────
  void _submitWithSchedule() {
    if (_nextAction == NextAction.callBackLater &&
        _visitDate != null &&
        _visitTime != null) {
      // Build exact DateTime for the alarm
      final alarmDateTime = DateTime(
        _visitDate!.year,
        _visitDate!.month,
        _visitDate!.day,
        _visitTime!.hour,
        _visitTime!.minute,
      );
      // Schedule the alarm (fires even if app is backgrounded / user logged out)
      NotificationService.scheduleFollowupAlarm(widget.lead, alarmDateTime);
    }
    _submit();
  }
}

// ─── Reusable Sub-widgets ─────────────────────────────────────────────────────

class _BigOptionButton extends StatelessWidget {
  const _BigOptionButton({
    required this.label,
    required this.description,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  final String label;
  final String description;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadius.borderRadiusMd,
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                )),
            const SizedBox(height: 4),
            Text(description,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withAlpha(180),
                )),
          ],
        ),
      ).animate().scale(
            begin: const Offset(0.97, 0.97),
            end: const Offset(1.0, 1.0),
            duration: const Duration(milliseconds: 150),
          ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF8E1) : Colors.white,
          borderRadius: AppRadius.borderRadiusMd,
          border: Border.all(
            color: selected
                ? AppColors.ssGoldDark
                : const Color(0xFFE8D5B5),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.ssGoldDark
                      : const Color(0xFF5D4037),
                )),
            const SizedBox(width: 8),
            Text(description,
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF8D6E63),
                )),
            const Spacer(),
            if (selected)
              Icon(Icons.check_circle_rounded,
                  color: AppColors.ssGoldDark, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              enabled ? AppColors.ssGoldDark : const Color(0xFFE8D5B5),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderRadiusMd,
          ),
          elevation: enabled ? 2 : 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}

// ─── Step Label ───────────────────────────────────────────────────────────────
class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.number, required this.text});
  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.ssGoldDark,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF5D4037),
          ),
        ),
      ],
    );
  }
}
