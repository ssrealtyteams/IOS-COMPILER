import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/lead.dart';
import '../../../../domain/entities/project.dart';
import '../../common/widgets/primary_button.dart';

class ShareDetailsSheet extends StatefulWidget {
  const ShareDetailsSheet({
    super.key,
    required this.lead,
    required this.projects,
  });

  final Lead lead;
  final List<Project> projects;

  @override
  State<ShareDetailsSheet> createState() => _ShareDetailsSheetState();
}

class _ShareDetailsSheetState extends State<ShareDetailsSheet> {
  final Set<String> _selectedProjectIds = {};
  bool _isSharing = false;

  bool get _hasSelection => _selectedProjectIds.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollCtrl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'Select Projects to Share',
                      style: AppTypography.titleSmall,
                    ),
                  ),
                  _buildProjectList(),
                  if (_hasSelection) ...[
                    const Divider(height: 1),
                    _buildMessagePreview(),
                  ],
                ],
              ),
            ),
          ),
          _buildShareButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: AppRadius.borderRadiusFull,
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8FBF0),
                  borderRadius: AppRadius.borderRadiusMd,
                ),
                child: const Icon(
                  Icons.share_rounded,
                  color: Color(0xFF25D366),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share with ${widget.lead.fullName}',
                      style: AppTypography.titleMedium,
                    ),
                    Text(
                      widget.lead.phone,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectList() {
    if (widget.projects.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text('No projects available'),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.projects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final project = widget.projects[index];
        final isSelected = _selectedProjectIds.contains(project.id);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedProjectIds.remove(project.id);
              } else {
                _selectedProjectIds.add(project.id);
              }
            });
          },
          child: AnimatedContainer(
            duration: 200.ms,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.ssGold.withAlpha(20) : AppColors.surface,
              borderRadius: AppRadius.borderRadiusMd,
              border: Border.all(
                color: isSelected ? AppColors.ssGold : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.ssGold.withAlpha(40) : AppColors.primarySurface,
                    borderRadius: AppRadius.borderRadiusSm,
                    image: project.thumbnailUrl != null
                        ? DecorationImage(
                            image: NetworkImage(project.thumbnailUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: project.thumbnailUrl == null
                      ? const Icon(Icons.apartment_rounded,
                          color: AppColors.primary, size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: AppTypography.titleSmall,
                      ),
                      if (project.location != null)
                        Text(
                          project.location!,
                          style: AppTypography.bodySmall,
                        ),
                      if (project.pricing.isNotEmpty)
                        Text(
                          project.pricing.values.first,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                    ],
                  ),
                ),
                Checkbox(
                  value: isSelected,
                  onChanged: (_) {
                    setState(() {
                      if (isSelected) {
                        _selectedProjectIds.remove(project.id);
                      } else {
                        _selectedProjectIds.add(project.id);
                      }
                    });
                  },
                  activeColor: AppColors.ssGold,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderRadiusSm,
                  ),
                ),
              ],
            ),
          ).animate(delay: Duration(milliseconds: index * 60)).fadeIn().slideX(begin: 0.1),
        );
      },
    );
  }

  Widget _buildMessagePreview() {
    final selected = widget.projects
        .where((p) => _selectedProjectIds.contains(p.id))
        .toList();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FBF0),
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(color: const Color(0xFF25D366).withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded,
                  size: 14, color: Color(0xFF25D366)),
              const SizedBox(width: 6),
              Text(
                'Message Preview',
                style: AppTypography.labelSmall
                    .copyWith(color: const Color(0xFF25D366)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _generateMessage(selected),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: PrimaryButton(
        label: _hasSelection ? 'Share on WhatsApp' : 'Select at least one project',
        isDisabled: !_hasSelection,
        isLoading: _isSharing,
        color: const Color(0xFF25D366),
        onPressed: _hasSelection ? () => _shareOnWhatsApp(context) : null,
        icon: Icons.send_rounded,
      ),
    );
  }

  Future<void> _shareOnWhatsApp(BuildContext context) async {
    setState(() => _isSharing = true);

    final selected = widget.projects
        .where((p) => _selectedProjectIds.contains(p.id))
        .toList();

    final message = _generateMessage(selected);
    final phone = widget.lead.phone.replaceAll(RegExp(r'[^\d]'), '');
    final url = Uri.parse('whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      if (context.mounted) Navigator.pop(context);
      // TODO: Log to timeline
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp. Please check if it is installed.')),
        );
      }
    } finally {
      setState(() => _isSharing = false);
    }
  }

  String _generateMessage(List<Project> selected) {
    final buffer = StringBuffer();
    buffer.writeln('Hi ${widget.lead.fullName},');
    buffer.writeln();
    buffer.writeln('I would like to share some amazing properties that match your requirements:');
    buffer.writeln();

    for (final project in selected) {
      buffer.writeln('🏢 *${project.name}*');
      if (project.location != null) buffer.writeln('📍 ${project.location}');
      if (project.pricing.isNotEmpty) {
        buffer.writeln('💰 ${project.pricing.values.first}');
      }
      if (project.websiteUrl != null) {
        buffer.writeln('🌐 ${project.websiteUrl}');
      }
      buffer.writeln();
    }

    buffer.writeln('Please click the links above to explore more properties.');
    buffer.writeln();
    buffer.writeln('Feel free to reach out for any queries. We would love to help you find your dream home! 🏡');

    return buffer.toString();
  }
}
