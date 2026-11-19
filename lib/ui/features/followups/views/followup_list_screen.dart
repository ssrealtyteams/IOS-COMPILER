import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sales_crm_dialer/core/theme/app_colors.dart';
import 'package:sales_crm_dialer/core/theme/app_theme.dart';
import 'package:sales_crm_dialer/core/theme/app_typography.dart';
import 'package:sales_crm_dialer/domain/entities/followup.dart';
import '../view_models/followup_view_model.dart';

class FollowupListScreen extends StatefulWidget {
  const FollowupListScreen({
    super.key,
    required this.viewModel,
    this.onCallTap,
  });

  final FollowupViewModel viewModel;
  final Function(String leadId)? onCallTap;

  @override
  State<FollowupListScreen> createState() => _FollowupListScreenState();
}

class _FollowupListScreenState extends State<FollowupListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    widget.viewModel.loadFollowups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Follow-ups'),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: AppTypography.titleSmall.copyWith(color: Colors.white),
          unselectedLabelStyle: AppTypography.titleSmall.copyWith(color: Colors.white70),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(widget.viewModel.pendingFollowups, isPending: true),
              _buildList(widget.viewModel.completedFollowups, isPending: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<Followup> followups, {required bool isPending}) {
    if (followups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPending ? Icons.event_available_rounded : Icons.task_alt_rounded,
              size: 64,
              color: AppColors.textSecondary.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              isPending ? 'No pending follow-ups' : 'No completed follow-ups',
              style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: followups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildFollowupCard(followups[index], isPending: isPending);
      },
    );
  }

  Widget _buildFollowupCard(Followup followup, {required bool isPending}) {
    final color = _getPriorityColor(followup.priority);
    final icon = _getTypeIcon(followup.type);
    final isOverdue = isPending && followup.scheduledAt.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(
          color: isOverdue ? AppColors.error : AppColors.border,
          width: isOverdue ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      followup.leadName.isNotEmpty ? followup.leadName : 'Lead: ${followup.leadId}',
                      style: AppTypography.titleSmall,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: isOverdue ? AppColors.error : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM, hh:mm a').format(followup.scheduledAt),
                          style: AppTypography.bodySmall.copyWith(
                            color: isOverdue ? AppColors.error : AppColors.textSecondary,
                            fontWeight: isOverdue ? FontWeight.w600 : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isPending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: AppRadius.borderRadiusSm,
                  ),
                  child: Text(
                    followup.priority.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
          if (followup.notes != null && followup.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              followup.notes!,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Color _getPriorityColor(FollowupPriority priority) {
    switch (priority) {
      case FollowupPriority.high:
        return AppColors.error;
      case FollowupPriority.medium:
        return AppColors.warning;
      case FollowupPriority.low:
        return AppColors.success;
    }
  }

  IconData _getTypeIcon(FollowupType type) {
    switch (type) {
      case FollowupType.call:
        return Icons.call_rounded;
      case FollowupType.email:
        return Icons.email_rounded;
      case FollowupType.whatsapp:
        return Icons.chat_bubble_rounded;
      case FollowupType.meeting:
        return Icons.groups_rounded;
      case FollowupType.siteVisit:
        return Icons.apartment_rounded;
    }
  }
}
