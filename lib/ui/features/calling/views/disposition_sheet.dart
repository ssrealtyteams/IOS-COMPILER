import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/services/contact_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/repositories/remote_lead_repository.dart';
import '../../../../domain/entities/call.dart';
import '../../../../domain/entities/lead.dart';
import '../view_models/disposition_view_model.dart';
import '../../common/widgets/primary_button.dart';
import '../../../common/widgets/app_date_time_picker.dart';

class DispositionSheet extends StatefulWidget {
  const DispositionSheet({
    super.key,
    required this.call,
    required this.lead,
    required this.viewModel,
    required this.onDismiss,
    this.initialRemarks,
  });

  final Call call;
  final Lead? lead;
  final DispositionViewModel viewModel;
  final VoidCallback onDismiss;
  final String? initialRemarks;

  @override
  State<DispositionSheet> createState() => _DispositionSheetState();
}

class _DispositionSheetState extends State<DispositionSheet> {
  late final TextEditingController _remarksController;
  late final TextEditingController _nameController;
  bool _nameStepCompleted = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRemarks ?? widget.call.remarks ?? widget.viewModel.remarks;
    _remarksController = TextEditingController(text: initial);
    _nameController = TextEditingController();
  }

  /// Checks if this was a manual dial AND the contact is unsaved in phonebook
  bool get _needsNamePrompt {
    // 1. Must be manual dial / direct call
    final isManual = widget.call.id.startsWith('manual-') ||
        (widget.call.leadId?.startsWith('manual-') ?? false) ||
        (widget.lead?.source == 'Manual Dial') ||
        (widget.lead?.id.startsWith('manual-') ?? false);
    if (!isManual) return false;

    // 2. Check if name is generic / unsaved
    final currentName = widget.lead?.fullName.trim() ?? '';
    final phone = widget.call.phoneNumber.trim();
    final isGeneric = currentName.isEmpty ||
        currentName.startsWith('Lead ') ||
        currentName == 'Unknown Contact' ||
        currentName == phone;

    if (!isGeneric) return false;

    // 3. Check device address book cache
    final savedName = ContactService.lookupContactName(phone);
    if (savedName != null && savedName.isNotEmpty) return false;

    return true;
  }

  static const _notInterestedCategories = [
    (
      '💰',
      'Budget Too High',
      'Property price exceeds customer budget',
      Color(0xFFE53935),
      Color(0xFFFFEBEE),
    ),
    (
      '📍',
      'Location Not Suitable',
      'Area/locality doesn\'t match preferences',
      Color(0xFF1565C0),
      Color(0xFFE3F2FD),
    ),
    (
      '🏗️',
      'Project Not Matching',
      'Size, type or specs don\'t fit needs',
      Color(0xFF6A1B9A),
      Color(0xFFF3E5F5),
    ),
    (
      '👨‍👩‍👧',
      'Family Not Convinced',
      'Disagreement within family members',
      Color(0xFF00695C),
      Color(0xFFE0F2F1),
    ),
    (
      '🏠',
      'Already Purchased',
      'Bought another property elsewhere',
      Color(0xFF2E7D32),
      Color(0xFFE8F5E9),
    ),
    (
      '⏰',
      'Not Looking Right Now',
      'Postponed plan / wrong timing',
      Color(0xFFE65100),
      Color(0xFFFFF3E0),
    ),
    (
      '🏦',
      'Loan / Finance Issue',
      'Bank loan or finance constraint',
      Color(0xFF37474F),
      Color(0xFFECEFF1),
    ),
  ];

  final _dealAmountController = TextEditingController();

  @override
  void dispose() {
    _remarksController.dispose();
    _nameController.dispose();
    _dealAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: AppRadius.xl),
        ),
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDragHandle(),
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: (_needsNamePrompt && !_nameStepCompleted)
                      ? _buildSaveNameStep(context)
                      : (widget.viewModel.isOnStep1
                          ? _buildStep1(context)
                          : _buildStep2(context)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: AppRadius.borderRadiusFull,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final displayName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : (widget.lead?.fullName ?? widget.call.phoneNumber);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: AppRadius.borderRadiusMd,
                ),
                child: const Icon(Icons.call_end_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: AppTypography.titleMedium,
                    ),
                    Text(
                      widget.call.phoneNumber,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (widget.call.durationSeconds > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.successSurface,
                    borderRadius: AppRadius.borderRadiusFull,
                  ),
                  child: Text(
                    widget.call.durationDisplay,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Step indicator
          if (_needsNamePrompt)
            Row(
              children: [
                _StepDot(
                  number: 1,
                  isActive: !_nameStepCompleted,
                  isDone: _nameStepCompleted,
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    color: _nameStepCompleted ? AppColors.primary : AppColors.border,
                  ),
                ),
                _StepDot(
                  number: 2,
                  isActive: _nameStepCompleted && widget.viewModel.isOnStep1,
                  isDone: _nameStepCompleted && !widget.viewModel.isOnStep1,
                ),
                Expanded(
                  child: Container(
                    height: 2,
                    color: (_nameStepCompleted && !widget.viewModel.isOnStep1) ? AppColors.primary : AppColors.border,
                  ),
                ),
                _StepDot(
                  number: 3,
                  isActive: _nameStepCompleted && !widget.viewModel.isOnStep1,
                  isDone: false,
                ),
              ],
            )
          else
            Row(
              children: [
                _StepDot(number: 1, isActive: widget.viewModel.isOnStep1, isDone: !widget.viewModel.isOnStep1),
                Expanded(
                  child: Container(
                    height: 2,
                    color: widget.viewModel.isOnStep1 ? AppColors.border : AppColors.primary,
                  ),
                ),
                _StepDot(number: 2, isActive: !widget.viewModel.isOnStep1, isDone: false),
              ],
            ),
        ],
      ),
    );
  }

  // ── STEP 0: Save Unsaved Contact Name (For Manual Unsaved Dials) ────────────
  Widget _buildSaveNameStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.ssGold.withAlpha(80)),
              ),
              child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.ssGoldDark, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Save Contact Name',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    'Manual Dial • Unsaved Contact',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ssGoldDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'This number is not saved in your phonebook. Please enter the customer / lead name to save it to your phone contacts & CRM before choosing disposition.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Enter Contact / Lead Name...',
            hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
            prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.ssGoldDark, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: AppRadius.borderRadiusMd,
              borderSide: const BorderSide(color: Color(0xFFE8D5B5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.borderRadiusMd,
              borderSide: const BorderSide(color: Color(0xFFE8D5B5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.borderRadiusMd,
              borderSide: const BorderSide(color: AppColors.ssGold, width: 1.8),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Save Name & Continue Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              final entered = _nameController.text.trim();
              if (entered.isNotEmpty) {
                final phone = widget.call.phoneNumber;
                // 1. Save to phone address book
                ContactService.saveOrUpdateContact(entered, phone);
                // 2. Update in repo
                if (widget.lead != null) {
                  final updated = widget.lead!.copyWith(fullName: entered);
                  RemoteLeadRepository.updateLeadInRepo(updated);
                }
              }
              setState(() => _nameStepCompleted = true);
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('Save Name & Continue'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ssGoldDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.borderRadiusMd,
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Skip Button
        Center(
          child: TextButton(
            onPressed: () => setState(() => _nameStepCompleted = true),
            child: const Text(
              'Skip (Continue without saving name)',
              style: TextStyle(
                color: Color(0xFF8D6E63),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.08);
  }

  // ── STEP 1: Connected or Not? ────────────────────────────────────────────────
  Widget _buildStep1(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Call Connected?',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Did the customer pick up the call?',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        // YES button
        _ConnectionButton(
          label: '✅  Yes, Call Connected',
          subtitle: 'Customer answered the call',
          color: AppColors.success,
          bgColor: AppColors.successSurface,
          onTap: () => widget.viewModel.setConnected(true),
        ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1),
        const SizedBox(height: 12),
        // NO button
        _ConnectionButton(
          label: '❌  Not Connected',
          subtitle: 'Customer did not pick up',
          color: AppColors.error,
          bgColor: const Color(0xFFFFF0F0),
          onTap: () => widget.viewModel.setConnected(false),
        ).animate(delay: 80.ms).fadeIn(duration: 200.ms).slideY(begin: 0.1),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── STEP 2: Outcome Details ──────────────────────────────────────────────────
  Widget _buildStep2(BuildContext context) {
    final isConnected = widget.viewModel.wasConnected == true;
    final isNotInterested = widget.viewModel.selectedDisposition == CallDisposition.notInterested;
    final isBookingDone = widget.viewModel.selectedDisposition == CallDisposition.closed;
    final showFollowup = widget.viewModel.showFollowup;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button + status badge
        Row(
          children: [
            GestureDetector(
              onTap: widget.viewModel.goBackToStep1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_ios_rounded, size: 14, color: AppColors.primary),
                  Text('Change', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isConnected ? AppColors.successSurface : const Color(0xFFFFF0F0),
                borderRadius: AppRadius.borderRadiusFull,
                border: Border.all(
                  color: isConnected ? AppColors.success : AppColors.error,
                ),
              ),
              child: Text(
                isConnected ? '✅ Connected' : '❌ Not Connected',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isConnected ? AppColors.success : AppColors.error,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          isConnected ? 'Select Disposition' : 'Why was it not connected?',
          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        // Disposition chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.viewModel.availableDispositions.asMap().entries.map((entry) {
            final i = entry.key;
            final d = entry.value;
            final isSelected = widget.viewModel.selectedDisposition == d;
            final color = d == CallDisposition.closed ? const Color(0xFFC9A227) : AppColors.dispositionColor(d.apiValue);
            return GestureDetector(
              onTap: () async {
                widget.viewModel.selectDisposition(d);

                // For Interested, Callback, Visit Scheduled: Automatically trigger Date (Calendar) then Time (Clock) picker
                if (d == CallDisposition.interested ||
                    d == CallDisposition.callback ||
                    d == CallDisposition.visitScheduled) {
                  await _pickDateAndTime(context);
                }
              },
              child: AnimatedContainer(
                duration: 150.ms,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color.withAlpha(25) : AppColors.surface,
                  borderRadius: AppRadius.borderRadiusMd,
                  border: Border.all(
                    color: isSelected ? color : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (d == CallDisposition.closed) ...[
                      const Icon(Icons.celebration_rounded, size: 15, color: Color(0xFFC9A227)),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      d.displayName,
                      style: TextStyle(
                        color: isSelected ? color : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    if (d == CallDisposition.callback) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.alarm_rounded, size: 14, color: AppColors.primary),
                    ],
                  ],
                ),
              ),
            ).animate(delay: Duration(milliseconds: i * 30)).fadeIn().scale(begin: const Offset(0.9, 0.9));
          }).toList(),
        ),

        // ── Follow-up Section (Calendar + Round Clock) for Interested, Call Back, Visit Scheduled ──
        if (showFollowup) ...[
          const SizedBox(height: 16),
          _buildFollowupSection(context),
        ],

        // ── Booking Done Deal Amount Section (Cr / Lac) ──
        if (isBookingDone) ...[
          const SizedBox(height: 16),
          _buildBookingDoneSection(context),
        ],

        // ── Not Interested MCQ Popup Section ──
        if (isNotInterested) ...[
          const SizedBox(height: 16),
          _buildNotInterestedSection(context),
        ],

        // ── Standard Remarks (for dispositions OTHER than Not Interested) ──
        if (!isNotInterested) ...[
          const SizedBox(height: 16),
          Text('Remarks (optional)', style: AppTypography.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _remarksController,
            onChanged: widget.viewModel.setRemarks,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: isBookingDone ? 'e.g. 10% token received, tower 2 4th floor...' : 'Add call notes here...',
              hintStyle: AppTypography.bodyMedium,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: AppRadius.borderRadiusMd,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderRadiusMd,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderRadiusMd,
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),
        // Save button
        PrimaryButton(
          label: isNotInterested
              ? (widget.viewModel.canSave ? 'Save Outcome' : 'Select reason & enter remark')
              : isBookingDone
                  ? (widget.viewModel.canSave
                      ? 'Confirm Booking (₹ ${widget.viewModel.bookingDealAmount} ${widget.viewModel.bookingDealUnit})'
                      : 'Enter Deal Done Amount')
                  : 'Save & Close',
          onPressed: widget.viewModel.canSave
              ? () async {
                  await widget.viewModel.saveDisposition(
                    callId: widget.call.id,
                    leadId: widget.lead?.id ?? 'manual-${widget.call.phoneNumber}',
                    durationDisplay: widget.call.durationDisplay,
                    lead: widget.lead,
                    recordingPath: widget.call.recordingPath,
                    recordingUrl: widget.call.recordingUrl,
                  );
                  widget.onDismiss();
                }
              : null,
          isDisabled: !widget.viewModel.canSave,
          isLoading: widget.viewModel.isSaving,
        ),
        SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
      ],
    );
  }

  // ── Booking Done Deal Amount Card (Cr / Lac) ──────────────────────────────
  Widget _buildBookingDoneSection(BuildContext context) {
    final unit = widget.viewModel.bookingDealUnit;
    final amtText = widget.viewModel.bookingDealAmount ?? '';
    final isValid = (double.tryParse(amtText.trim()) ?? 0) > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(
          color: AppColors.ssGold.withAlpha(180),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ssGold.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.ssGold.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.celebration_rounded, color: AppColors.ssGoldDark, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deal Done Amount',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Kitne me deal final hui? Enter amount & unit (Cr / Lac)',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF795548),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Amount input + Cr / Lac Unit Selector
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Amount text input
              Expanded(
                child: TextField(
                  controller: _dealAmountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '₹',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ssGoldDark,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    hintText: unit == 'Cr' ? 'e.g. 1.25' : 'e.g. 85',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade400,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.ssGold, width: 1.2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.ssGold.withAlpha(100), width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.ssGoldDark, width: 2),
                    ),
                  ),
                  onChanged: (val) {
                    widget.viewModel.setBookingDealAmount(val);
                  },
                ),
              ),
              const SizedBox(width: 10),

              // Unit Selector: Cr vs Lac
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EDE4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.ssGold.withAlpha(90)),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    _buildUnitChip('Cr', 'Crore', unit == 'Cr'),
                    const SizedBox(width: 2),
                    _buildUnitChip('Lac', 'Lakh', unit == 'Lac'),
                  ],
                ),
              ),
            ],
          ),

          // Live confirmation badge
          if (isValid) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF81C784), width: 0.8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Confirmed Deal Value: ₹ $amtText $unit',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.2),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.97, 0.97));
  }

  Widget _buildUnitChip(String unitValue, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        widget.viewModel.setBookingDealUnit(unitValue);
      },
      child: AnimatedContainer(
        duration: 150.ms,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ssGoldDark : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.ssGoldDark.withAlpha(60),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          unitValue,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF5D4037),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ── Followup Card (Calendar + Round Clock Picker) ──────────────────────────
  Widget _buildFollowupSection(BuildContext context) {
    final d = widget.viewModel.selectedDisposition;
    final isCallback = d == CallDisposition.callback;
    final isVisit = d == CallDisposition.visitScheduled;

    final title = isCallback
        ? 'Schedule Call Back'
        : isVisit
            ? 'Schedule Site Visit'
            : 'Schedule Follow-up';

    final subtitle = isCallback
        ? '⏰ Alarm will ring at selected time even if app is closed'
        : 'Select date & time for follow-up';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCallback ? const Color(0xFFE0F7FA) : AppColors.primarySurface,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(
          color: isCallback ? const Color(0xFF00838F) : AppColors.primary.withAlpha(60),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCallback ? Icons.alarm_rounded : Icons.calendar_today_rounded,
                color: isCallback ? const Color(0xFF00838F) : AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleSmall.copyWith(
                        color: isCallback ? const Color(0xFF006064) : null,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isCallback ? const Color(0xFF00838F) : AppColors.textSecondary,
                        fontWeight: isCallback ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Date Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDateAndTime(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: widget.viewModel.followupDate != null
                          ? (isCallback ? const Color(0xFF00838F) : AppColors.primary)
                          : AppColors.border,
                      width: widget.viewModel.followupDate != null ? 1.5 : 1,
                    ),
                  ),
                  icon: Icon(
                    Icons.calendar_month_rounded,
                    size: 16,
                    color: isCallback ? const Color(0xFF00838F) : AppColors.primary,
                  ),
                  label: Text(
                    widget.viewModel.followupDate != null
                        ? _formatDate(widget.viewModel.followupDate!)
                        : 'Select Date',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.viewModel.followupDate != null
                          ? Colors.black87
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Time Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickTimeOnly(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: widget.viewModel.followupTime != null
                          ? (isCallback ? const Color(0xFF00838F) : AppColors.primary)
                          : AppColors.border,
                      width: widget.viewModel.followupTime != null ? 1.5 : 1,
                    ),
                  ),
                  icon: Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: isCallback ? const Color(0xFF00838F) : AppColors.primary,
                  ),
                  label: Text(
                    widget.viewModel.followupTime != null
                        ? widget.viewModel.followupTime!.format(context)
                        : 'Select Time',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: widget.viewModel.followupTime != null
                          ? Colors.black87
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Priority Selector
          Row(
            children: FollowupPriorityOption.values.map((p) {
              final isSelected = widget.viewModel.followupPriority == p.value;
              return Expanded(
                child: GestureDetector(
                  onTap: () => widget.viewModel.setFollowupPriority(p.value),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? p.color.withAlpha(30) : Colors.white,
                      borderRadius: AppRadius.borderRadiusSm,
                      border: Border.all(color: isSelected ? p.color : AppColors.border),
                    ),
                    child: Center(
                      child: Text(
                        p.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? p.color : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Not Interested MCQ + Compulsory Remark Section ─────────────────────────
  Widget _buildNotInterestedSection(BuildContext context) {
    final selectedCategory = widget.viewModel.notInterestedCategory;
    final remarkNotEmpty = widget.viewModel.remarks.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.thumb_down_rounded, size: 16, color: Color(0xFFE53935)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why Not Interested? (Compulsory)',
                      style: AppTypography.titleSmall.copyWith(
                        color: const Color(0xFF3E2723),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Select reason + add remark to proceed',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '1. Select Reason *',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF5D4037)),
          ),
          const SizedBox(height: 8),
          // MCQ Category List
          ..._notInterestedCategories.map((cat) {
            final emoji = cat.$1;
            final title = cat.$2;
            final subtitle = cat.$3;
            final color = cat.$4;
            final bg = cat.$5;
            final isSelected = selectedCategory == title;

            return GestureDetector(
              onTap: () => widget.viewModel.setNotInterestedCategory(title),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? bg : Colors.white,
                  borderRadius: AppRadius.borderRadiusSm,
                  border: Border.all(
                    color: isSelected ? color : const Color(0xFFE0E0E0),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? color : Colors.black87,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? color.withAlpha(200) : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 18,
                      color: isSelected ? color : const Color(0xFFBDBDBD),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '2. Remark (Compulsory) *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF5D4037)),
              ),
              const Spacer(),
              if (remarkNotEmpty)
                const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF2E7D32)),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _remarksController,
            onChanged: widget.viewModel.setRemarks,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g. Customer says budget is 1 Cr, property is 1.3 Cr so cannot proceed...',
              hintStyle: const TextStyle(fontSize: 12, color: Colors.black38),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(10),
              border: OutlineInputBorder(
                borderRadius: AppRadius.borderRadiusSm,
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderRadiusSm,
                borderSide: BorderSide(
                  color: remarkNotEmpty ? const Color(0xFF81C784) : const Color(0xFFE0E0E0),
                  width: remarkNotEmpty ? 1.5 : 1,
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(6)),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          if (!widget.viewModel.canSave) ...[
            const SizedBox(height: 6),
            Text(
              selectedCategory == null
                  ? '⚠️ Please select a reason above'
                  : '⚠️ Please enter a remark to continue',
              style: const TextStyle(fontSize: 11, color: Color(0xFFD32F2F), fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  // ── Date & Time Pickers ──────────────────────────────────────────────────
  Future<void> _pickDateAndTime(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final defaultTime = TimeOfDay.now();

    final pickedDate = await showAppDatePicker(
      context: context,
      initialDate: widget.viewModel.followupDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'SELECT DATE',
      primaryColor: AppColors.primary,
    );

    if (pickedDate != null && context.mounted) {
      widget.viewModel.setFollowupDate(pickedDate);

      // Immediately open Round Clock (Time Picker) with auto AM/PM selection
      final pickedTime = await showAppTimePicker(
        context: context,
        initialTime: widget.viewModel.followupTime ?? defaultTime,
        helpText: 'SELECT TIME',
        primaryColor: AppColors.primary,
      );

      if (pickedTime != null) {
        widget.viewModel.setFollowupTime(pickedTime);
      }
    }
  }

  Future<void> _pickTimeOnly(BuildContext context) async {
    final defaultTime = TimeOfDay.now();

    final pickedTime = await showAppTimePicker(
      context: context,
      initialTime: widget.viewModel.followupTime ?? defaultTime,
      helpText: 'SELECT TIME',
      primaryColor: AppColors.primary,
    );
    if (pickedTime != null) {
      widget.viewModel.setFollowupTime(pickedTime);
    }
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

// ── Step Dot ──────────────────────────────────────────────────────────────────
class _StepDot extends StatelessWidget {
  const _StepDot({required this.number, required this.isActive, required this.isDone});
  final int number;
  final bool isActive;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final color = isActive || isDone ? AppColors.primary : AppColors.border;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : isDone ? AppColors.primarySurface : AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: isDone
            ? const Icon(Icons.check, size: 14, color: AppColors.primary)
            : Text(
                '$number',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : AppColors.textSecondary,
                ),
              ),
      ),
    );
  }
}

// ── Connection Button ─────────────────────────────────────────────────────────
class _ConnectionButton extends StatelessWidget {
  const _ConnectionButton({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });
  final String label;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadius.borderRadiusMd,
          border: Border.all(color: color.withAlpha(80), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 13, color: color.withAlpha(180)),
            ),
          ],
        ),
      ),
    );
  }
}

enum FollowupPriorityOption {
  high('High', AppColors.error),
  medium('Medium', AppColors.warning),
  low('Low', AppColors.success);

  const FollowupPriorityOption(this.label, this.color);
  final String label;
  final Color color;
  String get value => name;
}
