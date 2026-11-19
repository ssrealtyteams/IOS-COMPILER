import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../domain/entities/lead.dart';
import '../../view_models/lead_list_view_model.dart';
import '../../../calling/widgets/audio_recording_player.dart';

Future<void> showCallHistorySheet(BuildContext context, Lead lead, List<Activity> activities) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CallHistorySheet(lead: lead, activities: activities),
  );
}

class _CallHistorySheet extends StatelessWidget {
  const _CallHistorySheet({required this.lead, required this.activities});
  final Lead lead;
  final List<Activity> activities;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFE0D5C0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.ssGold.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.history_rounded, color: AppColors.ssGoldDark),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Call History', style: AppTypography.titleMedium),
                      const SizedBox(height: 2),
                      Text(lead.phone, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderLight),
          
          Expanded(
            child: activities.isEmpty 
              ? Center(
                  child: Text('No call history yet', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                )
              : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: activities.length,
              separatorBuilder: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: AppColors.borderLight, height: 1),
              ),
              itemBuilder: (context, index) {
                final item = activities[index];
                
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getColorForOutcome(item.outcome),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.background, width: 2),
                          ),
                        ),
                        if (index != activities.length - 1)
                          Container(
                            width: 2,
                            height: 50,
                            color: AppColors.borderLight,
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.outcome,
                                style: AppTypography.titleSmall.copyWith(
                                  color: _getColorForOutcome(item.outcome),
                                ),
                              ),
                              Text(
                                DateFormat('MMM d, h:mm a').format(item.date),
                                style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.timer_outlined, size: 13, color: Color(0xFF475569)),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDuration(item.duration),
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'By ${item.agentName}',
                                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (item.notes != null && item.notes!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.notes!,
                              style: AppTypography.bodySmall.copyWith(color: const Color(0xFF424242)),
                            ),
                          ],
                          if (item.recordingUrl != null || item.recordingPath != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: AudioRecordingPlayer(
                                filePath: item.recordingPath,
                                s3Url: item.recordingUrl,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForOutcome(String outcome) {
    switch (outcome) {
      case 'Interested':
      case 'Visit Set':
        return AppColors.success;
      case 'Not Reachable':
      case 'Call Back':
        return AppColors.warning;
      case 'Not Interested':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  String _formatDuration(String dur) {
    final clean = dur.trim();
    if (clean.isEmpty || clean == '0s' || clean == '0') return '0s';
    final parsed = int.tryParse(clean.replaceAll(RegExp(r'[^0-9]'), ''));
    if (parsed != null && !clean.contains('m')) {
      final m = parsed ~/ 60;
      final s = parsed % 60;
      if (m > 0) return '${m}m ${s}s';
      return '${s}s';
    }
    return clean;
  }
}
