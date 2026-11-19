import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../common/widgets/primary_button.dart';
import 'package:sales_crm_dialer/ui/common/widgets/app_date_time_picker.dart';

class ScheduleVisitSheet extends StatefulWidget {
  const ScheduleVisitSheet({
    super.key,
    required this.onSchedule,
    this.initialLeadId,
  });

  final Function(String leadId, String projectId, DateTime date, TimeOfDay time, String? notes) onSchedule;
  final String? initialLeadId;

  @override
  State<ScheduleVisitSheet> createState() => _ScheduleVisitSheetState();
}

class _ScheduleVisitSheetState extends State<ScheduleVisitSheet> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedLeadId;
  String? _selectedProjectId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedLeadId = widget.initialLeadId;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Schedule Site Visit', style: AppTypography.titleMedium),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Mock Lead Dropdown
            DropdownButtonFormField<String>(
              value: _selectedLeadId,
              decoration: const InputDecoration(
                labelText: 'Select Lead',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'lead-1', child: Text('Rahul Sharma')),
                DropdownMenuItem(value: 'lead-2', child: Text('Priya Patel')),
              ],
              onChanged: (val) => setState(() => _selectedLeadId = val),
              validator: (val) => val == null ? 'Please select a lead' : null,
            ),
            const SizedBox(height: 16),

            // Mock Project Dropdown
            DropdownButtonFormField<String>(
              value: _selectedProjectId,
              decoration: const InputDecoration(
                labelText: 'Select Project',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'p1', child: Text('Sunset Towers')),
                DropdownMenuItem(value: 'p2', child: Text('Green Valley')),
              ],
              onChanged: (val) => setState(() => _selectedProjectId = val),
              validator: (val) => val == null ? 'Please select a project' : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showAppDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 60)),
                        primaryColor: AppColors.primary,
                      );
                      if (date != null) setState(() => _selectedDate = date);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _selectedDate == null 
                            ? 'Select Date' 
                            : DateFormat('dd MMM yyyy').format(_selectedDate!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final time = await showAppTimePicker(
                        context: context,
                        initialTime: _selectedTime ?? TimeOfDay.now(),
                        primaryColor: AppColors.primary,
                      );
                      if (time != null) setState(() => _selectedTime = time);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Time',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _selectedTime == null 
                            ? 'Select Time' 
                            : _selectedTime!.format(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedDate == null || _selectedTime == null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  'Date and time are required',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.error),
                ),
              ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            PrimaryButton(
              label: 'Schedule Visit',
              onPressed: () {
                if (_formKey.currentState!.validate() && 
                    _selectedDate != null && 
                    _selectedTime != null) {
                  widget.onSchedule(
                    _selectedLeadId!,
                    _selectedProjectId!,
                    _selectedDate!,
                    _selectedTime!,
                    _notesController.text,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
