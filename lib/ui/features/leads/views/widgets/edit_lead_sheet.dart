import 'package:flutter/material.dart';
import '../../../../../core/services/contact_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../domain/entities/lead.dart';
import 'package:sales_crm_dialer/ui/common/widgets/app_date_time_picker.dart';

Future<Lead?> showEditLeadSheet(BuildContext context, Lead lead) {
  return showModalBottomSheet<Lead>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditLeadSheet(lead: lead),
  );
}

class _EditLeadSheet extends StatefulWidget {
  const _EditLeadSheet({required this.lead});
  final Lead lead;

  @override
  State<_EditLeadSheet> createState() => _EditLeadSheetState();
}

class _EditLeadSheetState extends State<_EditLeadSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _altPhoneCtrl;
  late final TextEditingController _customProjectCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _budgetAmtCtrl;
  late final TextEditingController _notesCtrl;

  late LeadPriority _priority;
  String? _selectedProject;
  String? _selectedUnitType;
  late String? _propertyType;
  DateTime? _followUpDate;
  TimeOfDay? _followUpTime;

  // Budget unit: 'L' = Lac, 'Cr' = Crore
  String _budgetUnit = 'L';

  static const _liveProjects = [
    'Orchid',
    'Nivasa III',
    'Amaryllis',
    'Vasundhara',
    'Velora',
    'The Arch',
    'Other / Custom',
  ];

  static const _unitTypeOptions = [
    '2 BHK',
    '3 BHK',
    '4 BHK',
    'Simplex',
    'Duplex',
    '1 BHK',
    'Studio',
    'Villa',
    'Plot',
  ];

  static const _propertyTypes = ['Flat', 'Villa', 'Plot', 'Commercial', 'Studio'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.lead.fullName);
    _phoneCtrl = TextEditingController(text: widget.lead.phone);
    _altPhoneCtrl = TextEditingController(text: widget.lead.alternatePhone ?? '');
    
    // Check if current project is one of live projects
    final currentProj = widget.lead.projectName?.trim();
    if (currentProj != null && currentProj.isNotEmpty) {
      if (_liveProjects.sublist(0, _liveProjects.length - 1).contains(currentProj)) {
        _selectedProject = currentProj;
        _customProjectCtrl = TextEditingController();
      } else {
        _selectedProject = 'Other / Custom';
        _customProjectCtrl = TextEditingController(text: currentProj);
      }
    } else {
      _selectedProject = null;
      _customProjectCtrl = TextEditingController();
    }

    _selectedUnitType = widget.lead.unitType?.trim();
    _locationCtrl = TextEditingController(text: widget.lead.location ?? '');

    // Pre-fill budget: show in Lac by default
    final bMin = widget.lead.budgetMin;
    if (bMin != null) {
      if (bMin >= 10000000) {
        _budgetUnit = 'Cr';
        _budgetAmtCtrl = TextEditingController(
            text: (bMin / 10000000).toStringAsFixed(2));
      } else {
        _budgetUnit = 'L';
        _budgetAmtCtrl = TextEditingController(
            text: (bMin / 100000).toStringAsFixed(2));
      }
    } else {
      _budgetAmtCtrl = TextEditingController();
    }

    _notesCtrl = TextEditingController();
    _priority = widget.lead.priority;
    _propertyType = widget.lead.propertyType;
    _followUpDate = widget.lead.lastActivityAt;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _altPhoneCtrl.dispose();
    _customProjectCtrl.dispose();
    _locationCtrl.dispose();
    _budgetAmtCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // Convert display value + unit to actual rupee amount
  double? _budgetToRupees() {
    final v = double.tryParse(_budgetAmtCtrl.text.replaceAll(',', ''));
    if (v == null) return null;
    return _budgetUnit == 'Cr' ? v * 10000000 : v * 100000;
  }

  void _save() {
    // Combine date + time if both selected
    DateTime? followUp = _followUpDate;
    if (followUp != null && _followUpTime != null) {
      followUp = DateTime(
        followUp.year,
        followUp.month,
        followUp.day,
        _followUpTime!.hour,
        _followUpTime!.minute,
      );
    }
    final budget = _budgetToRupees();

    String? finalProject;
    if (_selectedProject == 'Other / Custom') {
      final custom = _customProjectCtrl.text.trim();
      finalProject = custom.isNotEmpty ? custom : null;
    } else {
      finalProject = _selectedProject;
    }

    final finalName = _nameCtrl.text.trim();
    final finalPhone = _phoneCtrl.text.trim();

    // Auto-save to phone address book if name is valid
    if (finalName.isNotEmpty && !finalName.startsWith('Lead ') && finalPhone.isNotEmpty) {
      ContactService.saveOrUpdateContact(finalName, finalPhone);
    }

    final updated = widget.lead.copyWith(
      fullName: finalName,
      phone: finalPhone,
      alternatePhone: _altPhoneCtrl.text.trim().isEmpty
          ? null
          : _altPhoneCtrl.text.trim(),
      projectName: finalProject,
      unitType: _selectedUnitType,
      location: _locationCtrl.text.trim().isEmpty
          ? null
          : _locationCtrl.text.trim(),
      budgetMin: budget,
      budgetMax: budget,
      priority: _priority,
      propertyType: _propertyType,
      lastActivityAt: followUp,
    );
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFFFDF8F1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle + header
          _buildHeader(),
          // Scrollable form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Customer Info'),
                  _buildField('Full Name', _nameCtrl,
                      icon: Icons.person_outline_rounded),
                  _buildField('Phone Number', _phoneCtrl,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone),
                  _buildField('Alternate Phone', _altPhoneCtrl,
                      icon: Icons.phone_forwarded_outlined,
                      hint: 'Optional',
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  
                  _sectionLabel('Project & Interested Flat Type'),
                  _buildProjectSelector(),
                  const SizedBox(height: 12),
                  _buildUnitTypeSelector(),
                  const SizedBox(height: 12),
                  _buildField('Location / Area', _locationCtrl,
                      icon: Icons.location_on_outlined,
                      hint: 'e.g. Gwal Pahari, Chattarpur / Delhi NCR'),
                  _buildPropertyTypeSelector(),
                  const SizedBox(height: 16),
                  
                  _sectionLabel('Budget'),
                  _buildBudgetField(),
                  const SizedBox(height: 16),
                  
                  _sectionLabel('Priority'),
                  _buildPrioritySelector(),
                  const SizedBox(height: 16),
                  
                  _sectionLabel('Follow-up Date'),
                  _buildFollowUpDatePicker(),
                  const SizedBox(height: 16),
                  
                  _sectionLabel('Notes'),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: _inputDeco(
                      'Add any notes about this lead...',
                      Icons.notes_rounded,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save Changes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ssGoldDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.borderRadiusMd,
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF5C3D0E),
            Color(0xFF8B6914),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(60),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Lead Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      widget.lead.phone,
                      style: TextStyle(
                        color: Colors.white.withAlpha(180),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.ssGoldDark,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: _inputDeco(hint ?? label, icon),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
      prefixIcon: Icon(icon, size: 18, color: AppColors.ssGoldDark),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        borderSide: const BorderSide(color: AppColors.ssGold, width: 1.5),
      ),
    );
  }

  // ── Project Selector (Live Website Projects Dropdown & Quick Chips) ─────────
  Widget _buildProjectSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select SS Realty Project',
          style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.borderRadiusMd,
            border: Border.all(
              color: _selectedProject != null ? AppColors.ssGold : const Color(0xFFE8D5B5),
              width: _selectedProject != null ? 1.5 : 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _liveProjects.contains(_selectedProject) ? _selectedProject : null,
              hint: Row(
                children: const [
                  Icon(Icons.apartment_rounded, size: 18, color: AppColors.ssGoldDark),
                  SizedBox(width: 10),
                  Text('Choose Project...', style: TextStyle(color: AppColors.textTertiary, fontSize: 14)),
                ],
              ),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.ssGoldDark),
              items: _liveProjects.map((proj) {
                return DropdownMenuItem<String>(
                  value: proj,
                  child: Row(
                    children: [
                      Icon(
                        proj == 'Other / Custom' ? Icons.edit_note_rounded : Icons.business_rounded,
                        size: 16,
                        color: AppColors.ssGoldDark,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        proj,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3E2723),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedProject = val;
                  if (val != null && val != 'Other / Custom') {
                    if (_locationCtrl.text.trim().isEmpty) {
                      _locationCtrl.text = 'Chattarpur / Delhi NCR';
                    }
                  }
                });
              },
            ),
          ),
        ),
        if (_selectedProject == 'Other / Custom') ...[
          const SizedBox(height: 8),
          _buildField('Custom Project Name', _customProjectCtrl,
              icon: Icons.edit_rounded, hint: 'Type custom project name...'),
        ],
      ],
    );
  }

  // ── Unit Type / Interested Flat Configuration Selector ─────────────────────
  Widget _buildUnitTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interested Flat / Unit Configuration',
          style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _unitTypeOptions.map((unit) {
            final isSelected = _selectedUnitType == unit;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedUnitType = isSelected ? null : unit;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0284C7) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFBAE6FD),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withAlpha(60),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bed_rounded,
                      size: 14,
                      color: isSelected ? Colors.white : const Color(0xFF0369A1),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : const Color(0xFF0369A1),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPropertyTypeSelector() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Property Type',
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _propertyTypes.map((type) {
              final selected = _propertyType == type;
              return GestureDetector(
                onTap: () => setState(() => _propertyType = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.ssGoldDark
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? AppColors.ssGoldDark
                          : const Color(0xFFE8D5B5),
                    ),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : const Color(0xFF5D4037),
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

  Widget _buildPrioritySelector() {
    final options = [
      (LeadPriority.high, '🔴 High', const Color(0xFFBF360C),
          const Color(0xFFFBE9E7)),
      (LeadPriority.medium, '🟡 Medium', const Color(0xFF8B6914),
          const Color(0xFFFFF8E1)),
      (LeadPriority.low, '🟢 Low', const Color(0xFF2E7D32),
          const Color(0xFFE8F5E9)),
    ];

    return Row(
      children: options.map((o) {
        final selected = _priority == o.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _priority = o.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? o.$4 : Colors.white,
                borderRadius: AppRadius.borderRadiusMd,
                border: Border.all(
                  color: selected ? o.$3 : const Color(0xFFE8D5B5),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  o.$2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? o.$3 : const Color(0xFF8D6E63),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBudgetField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _budgetAmtCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDeco('Enter amount', Icons.currency_rupee_rounded),
          ),
        ),
        const SizedBox(width: 10),
        // Unit toggle buttons
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.borderRadiusMd,
            border: Border.all(color: const Color(0xFFE8D5B5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: ['L', 'Cr'].map((unit) {
              final selected = _budgetUnit == unit;
              return GestureDetector(
                onTap: () => setState(() => _budgetUnit = unit),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.ssGoldDark
                        : Colors.transparent,
                    borderRadius: unit == 'L'
                        ? const BorderRadius.horizontal(
                            left: Radius.circular(10))
                        : const BorderRadius.horizontal(
                            right: Radius.circular(10)),
                  ),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color:
                          selected ? Colors.white : const Color(0xFF8B6914),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFollowUpDatePicker() {
    return Column(
      children: [
        // Date + Time display row (tappable)
        GestureDetector(
          onTap: () async {
            // Step 1: Pick date
            final pickedDate = await showAppDatePicker(
              context: context,
              initialDate:
                  _followUpDate ?? DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              primaryColor: AppColors.ssGoldDark,
            );
            if (pickedDate == null || !mounted) return;
            // Step 2: Auto-open time picker
            final pickedTime = await showAppTimePicker(
              context: context,
              initialTime: _followUpTime ?? TimeOfDay.now(),
              primaryColor: AppColors.ssGoldDark,
            );
            if (!mounted) return;
            setState(() {
              _followUpDate = pickedDate;
              if (pickedTime != null) _followUpTime = pickedTime;
            });
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.borderRadiusMd,
              border: Border.all(
                color: _followUpDate != null
                    ? AppColors.ssGold
                    : const Color(0xFFE8D5B5),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded,
                    size: 18, color: AppColors.ssGoldDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _followUpDate != null
                        ? '${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year}'  
                            '${_followUpTime != null ? "  •  ${_followUpTime!.format(context)}" : "  •  Tap to set time"}'
                        : 'Select follow-up date & time',
                    style: TextStyle(
                      fontSize: 14,
                      color: _followUpDate != null
                          ? const Color(0xFF3E2723)
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
                if (_followUpDate != null)
                  GestureDetector(
                    onTap: () => setState(() {
                      _followUpDate = null;
                      _followUpTime = null;
                    }),
                    child: const Icon(Icons.clear_rounded,
                        size: 16, color: AppColors.textTertiary),
                  ),
              ],
            ),
          ),
        ),
        // Show OK chip when both date and time are set
        if (_followUpDate != null && _followUpTime != null) ...[  
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  size: 16, color: AppColors.ssGoldDark),
              const SizedBox(width: 6),
              Text(
                'Follow-up: ${_followUpDate!.day}/${_followUpDate!.month}/${_followUpDate!.year} at ${_followUpTime!.format(context)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ssGoldDark,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
