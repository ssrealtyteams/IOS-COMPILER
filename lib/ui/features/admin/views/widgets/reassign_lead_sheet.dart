import 'package:flutter/material.dart';
import 'package:sales_crm_dialer/core/theme/app_colors.dart';
import 'package:sales_crm_dialer/core/theme/app_typography.dart';
import 'package:sales_crm_dialer/domain/entities/lead.dart';
import 'package:sales_crm_dialer/ui/features/admin/view_models/admin_view_model.dart';

class ReassignLeadSheet extends StatefulWidget {
  final Lead lead;
  final AdminViewModel viewModel;

  const ReassignLeadSheet({
    super.key,
    required this.lead,
    required this.viewModel,
  });

  @override
  State<ReassignLeadSheet> createState() => _ReassignLeadSheetState();
}

class _ReassignLeadSheetState extends State<ReassignLeadSheet> {
  String? _selectedAgentId;
  String? _selectedAgentName;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final telecallers = widget.viewModel.telecallers;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            'Reassign Lead',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select the target telecaller to transfer ${widget.lead.fullName} (${widget.lead.phone})',
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 16),

          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: telecallers.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, idx) {
                final agent = telecallers[idx];
                final isSelected = _selectedAgentId == agent.id;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: isSelected ? AppColors.ssGoldDark : const Color(0xFFF1F5F9),
                        child: Text(
                          agent.name.isNotEmpty ? agent.name[0].toUpperCase() : 'A',
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: agent.isOnline ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Text(
                    agent.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? AppColors.ssGoldDark : const Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: Text(
                    '${agent.employeeId} • ${agent.assignedLeads} Assigned • ${agent.isQueueActive ? "Queue Active" : "On Leave"}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  trailing: Radio<String>(
                    value: agent.id,
                    groupValue: _selectedAgentId,
                    activeColor: AppColors.ssGoldDark,
                    onChanged: (val) {
                      setState(() {
                        _selectedAgentId = val;
                        _selectedAgentName = agent.name;
                      });
                    },
                  ),
                  onTap: () {
                    setState(() {
                      _selectedAgentId = agent.id;
                      _selectedAgentName = agent.name;
                    });
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (_selectedAgentId == null || _isSaving)
                  ? null
                  : () async {
                      setState(() => _isSaving = true);
                      final ok = await widget.viewModel.reassignLead(
                        widget.lead.id,
                        _selectedAgentId!,
                        _selectedAgentName ?? 'Telecaller',
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok
                                ? 'Lead reassigned to $_selectedAgentName successfully!'
                                : 'Failed to reassign lead'),
                            backgroundColor: ok ? const Color(0xFF16A34A) : AppColors.error,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ssGoldDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Confirm Reassignment',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
