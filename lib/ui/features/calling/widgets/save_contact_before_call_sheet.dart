import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/services/contact_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/repositories/remote_lead_repository.dart';
import '../../../../domain/entities/lead.dart';

/// Shows the Save Contact & Call bottom sheet before initiating a manual call
Future<void> showSaveContactBeforeCallSheet(
  BuildContext context, {
  required String phoneNumber,
  String? initialName,
  required Function(Lead lead) onCallInitiate,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => SaveContactBeforeCallSheet(
      phoneNumber: phoneNumber,
      initialName: initialName,
      onCallInitiate: onCallInitiate,
    ),
  );
}

class SaveContactBeforeCallSheet extends StatefulWidget {
  const SaveContactBeforeCallSheet({
    super.key,
    required this.phoneNumber,
    this.initialName,
    required this.onCallInitiate,
  });

  final String phoneNumber;
  final String? initialName;
  final Function(Lead lead) onCallInitiate;

  @override
  State<SaveContactBeforeCallSheet> createState() => _SaveContactBeforeCallSheetState();
}

class _SaveContactBeforeCallSheetState extends State<SaveContactBeforeCallSheet> {
  late final TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final name = (widget.initialName != null &&
            widget.initialName!.isNotEmpty &&
            !widget.initialName!.startsWith('Lead ') &&
            widget.initialName != 'Unknown Contact')
        ? widget.initialName!
        : '';
    _nameController = TextEditingController(text: name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatPhone(String raw) {
    final clean = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.length == 10) {
      return '${clean.substring(0, 5)} ${clean.substring(5)}';
    }
    return raw;
  }

  Future<void> _submitAndCall({bool isDirectSkip = false}) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final enteredName = _nameController.text.trim();
    final phone = widget.phoneNumber.trim();

    Lead? createdLead;
    try {
      if (!isDirectSkip && enteredName.isNotEmpty) {
        // 1. Save directly to device phonebook contacts
        ContactService.saveOrUpdateContact(enteredName, phone);

        // 2. Create or find lead in CRM repository with the entered name
        createdLead = await RemoteLeadRepository.findOrCreateLead(phone, customName: enteredName);
      } else {
        // Direct call without saving a custom name
        createdLead = await RemoteLeadRepository.findOrCreateLead(phone);
      }
    } catch (e) {
      debugPrint('Error saving contact before call: $e');
    }

    if (mounted) {
      Navigator.of(context).pop(); // Close the sheet
    }

    if (createdLead != null) {
      widget.onCallInitiate(createdLead);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final formattedPhone = _formatPhone(widget.phoneNumber);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: bottomInset + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE0D5C0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header with Gold Accent Icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.ssGold.withAlpha(80)),
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: AppColors.ssGoldDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Save Contact & Call',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.phone_rounded, size: 12, color: AppColors.ssGoldDark),
                        const SizedBox(width: 4),
                        Text(
                          formattedPhone,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ssGoldDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Informative helper banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF8B6914).withAlpha(12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF8B6914).withAlpha(25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.ssGoldDark, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Enter the customer name to save it to your phone contacts & CRM before starting the call.',
                    style: AppTypography.bodySmall.copyWith(
                      color: const Color(0xFF5C4033),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Name Input Field
          Text(
            'CUSTOMER / LEAD NAME',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _submitAndCall(),
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. Rahul Sharma, Amit Verma...',
              hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14, fontWeight: FontWeight.normal),
              prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.ssGoldDark, size: 22),
              suffixIcon: _nameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textTertiary),
                      onPressed: () {
                        _nameController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: const OutlineInputBorder(
                borderRadius: AppRadius.borderRadiusMd,
                borderSide: BorderSide(color: Color(0xFFE8D5B5)),
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: AppRadius.borderRadiusMd,
                borderSide: BorderSide(color: Color(0xFFE8D5B5)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: AppRadius.borderRadiusMd,
                borderSide: BorderSide(color: AppColors.ssGold, width: 1.8),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 20),

          // Primary Button: "Save & Call Now"
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : () => _submitAndCall(),
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.call_rounded, size: 20),
              label: Text(
                _nameController.text.trim().isNotEmpty ? 'Save & Call Now' : 'Call with Number',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.borderRadiusMd,
                ),
                elevation: 3,
                shadowColor: AppColors.success.withAlpha(100),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Secondary Action: Skip / Direct Call (if name not provided)
          if (_nameController.text.trim().isNotEmpty)
            Center(
              child: TextButton.icon(
                onPressed: _isSaving ? null : () => _submitAndCall(isDirectSkip: true),
                icon: const Icon(Icons.phone_forwarded_rounded, size: 14, color: AppColors.textSecondary),
                label: const Text(
                  'Call without saving name',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1);
  }
}
