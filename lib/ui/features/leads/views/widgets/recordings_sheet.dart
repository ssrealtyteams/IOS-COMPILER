import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../domain/entities/lead.dart';
import '../../view_models/lead_list_view_model.dart';
import '../../../calling/widgets/audio_recording_player.dart';

Future<void> showRecordingsSheet(BuildContext context, Lead lead, List<Activity> activities) {
  final recordings = activities.where((a) => a.recordingUrl != null || a.recordingPath != null).toList();

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RecordingsSheet(lead: lead, recordings: recordings),
  );
}

class _RecordingsSheet extends StatelessWidget {
  const _RecordingsSheet({required this.lead, required this.recordings});
  final Lead lead;
  final List<Activity> recordings;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFFFDF8F1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE0D5C0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B6914).withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.mic_rounded, color: Color(0xFF8B6914), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Call Recordings', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B6914),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${recordings.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${lead.fullName} • ${lead.phone}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
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

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE8D5B5)),

          // Body list
          Expanded(
            child: recordings.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mic_off_rounded, size: 48, color: AppColors.textTertiary.withAlpha(150)),
                          const SizedBox(height: 12),
                          Text(
                            'No Voice Recordings Yet',
                            style: AppTypography.titleSmall.copyWith(color: const Color(0xFF5D4037)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Make a call to this lead and recordings will automatically be saved and uploaded to AWS S3.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: recordings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = recordings[index];
                      final isS3 = item.recordingUrl != null && item.recordingUrl!.isNotEmpty;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8D5B5), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(8),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top metadata row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getColorForOutcome(item.outcome).withAlpha(25),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: _getColorForOutcome(item.outcome).withAlpha(80)),
                                      ),
                                      child: Text(
                                        item.outcome,
                                        style: TextStyle(
                                          color: _getColorForOutcome(item.outcome),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isS3)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5E9),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.cloud_done_rounded, size: 12, color: Color(0xFF2E7D32)),
                                            SizedBox(width: 4),
                                            Text(
                                              'AWS S3',
                                              style: TextStyle(
                                                color: Color(0xFF2E7D32),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                Text(
                                  DateFormat('MMM d, h:mm a').format(item.date),
                                  style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Agent & Duration info
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  item.duration,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: const Color(0xFF3E2723),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.agentName,
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            if (item.notes != null && item.notes!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAF7F2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.notes!,
                                  style: AppTypography.bodySmall.copyWith(color: const Color(0xFF424242)),
                                ),
                              ),
                            ],

                            const SizedBox(height: 10),

                            // Audio Player
                            AudioRecordingPlayer(
                              filePath: item.recordingPath,
                              s3Url: item.recordingUrl,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideY(begin: 0.05);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getColorForOutcome(String outcome) {
    final lower = outcome.toLowerCase();
    if (lower.contains('interest') && !lower.contains('not')) return AppColors.success;
    if (lower.contains('visit')) return const Color(0xFF2E7D32);
    if (lower.contains('callback') || lower.contains('call back') || lower.contains('ringing')) return AppColors.warning;
    if (lower.contains('not') || lower.contains('switch') || lower.contains('lost')) return AppColors.error;
    return AppColors.primary;
  }
}
