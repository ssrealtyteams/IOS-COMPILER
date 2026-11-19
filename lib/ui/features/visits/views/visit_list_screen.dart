import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sales_crm_dialer/core/theme/app_colors.dart';
import 'package:sales_crm_dialer/core/theme/app_theme.dart';
import 'package:sales_crm_dialer/core/theme/app_typography.dart';
import 'package:sales_crm_dialer/domain/entities/visit.dart';
import '../view_models/visit_view_model.dart';
import 'schedule_visit_sheet.dart';

class VisitListScreen extends StatefulWidget {
  const VisitListScreen({
    super.key,
    required this.viewModel,
  });

  final VisitViewModel viewModel;

  @override
  State<VisitListScreen> createState() => _VisitListScreenState();
}

class _VisitListScreenState extends State<VisitListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    widget.viewModel.loadVisits();
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
        title: const Text('Site Visits'),
        backgroundColor: AppColors.primary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: AppTypography.titleSmall.copyWith(color: Colors.white),
          unselectedLabelStyle: AppTypography.titleSmall.copyWith(color: Colors.white70),
          tabs: const [
            Tab(text: 'Upcoming'),
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
              _buildList(widget.viewModel.upcomingVisits, isUpcoming: true),
              _buildList(widget.viewModel.completedVisits, isUpcoming: false),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showScheduleSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Schedule Visit'),
      ),
    );
  }

  void _showScheduleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScheduleVisitSheet(
        onSchedule: (leadId, projectId, date, time, notes) {
          widget.viewModel.scheduleVisit(
            leadId: leadId,
            projectId: projectId,
            date: date,
            time: time,
            notes: notes,
          );
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildList(List<Visit> visits, {required bool isUpcoming}) {
    if (visits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.location_city_rounded : Icons.check_circle_outline_rounded,
              size: 64,
              color: AppColors.textSecondary.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'No upcoming visits' : 'No completed visits',
              style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: visits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildVisitCard(visits[index], isUpcoming: isUpcoming);
      },
    );
  }

  Widget _buildVisitCard(Visit visit, {required bool isUpcoming}) {
    final isToday = visit.scheduledAt.year == DateTime.now().year &&
        visit.scheduledAt.month == DateTime.now().month &&
        visit.scheduledAt.day == DateTime.now().day;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(
          color: isToday ? AppColors.primary : AppColors.border,
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: AppRadius.borderRadiusSm,
                ),
                child: const Icon(Icons.apartment_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visit.leadName.isNotEmpty ? visit.leadName : 'Lead ID: ${visit.leadId}',
                      style: AppTypography.titleSmall,
                    ),
                    if (visit.projectName != null && visit.projectName!.isNotEmpty)
                      Text(
                        visit.projectName!,
                        style: AppTypography.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                DateFormat('dd MMM yyyy, hh:mm a').format(visit.scheduledAt),
                style: AppTypography.bodySmall.copyWith(
                  color: isToday ? AppColors.primary : null,
                  fontWeight: isToday ? FontWeight.bold : null,
                ),
              ),
            ],
          ),
          if (visit.notes != null && visit.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    visit.notes!,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
