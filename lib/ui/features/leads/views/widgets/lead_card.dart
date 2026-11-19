import 'package:flutter/material.dart';
import 'package:sales_crm_dialer/core/theme/app_colors.dart';
import 'package:sales_crm_dialer/domain/entities/lead.dart';
import 'edit_lead_sheet.dart';

class LeadCard extends StatelessWidget {
  const LeadCard({
    super.key,
    required this.lead,
    required this.onTap,
    required this.onCall,
    required this.onWhatsApp,
    required this.onShare,
    required this.onTimeline,
    this.onRecordings,
    required this.onLeadUpdated,
    this.animationDelay = 0,
  });

  final Lead lead;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onShare;
  final VoidCallback onTimeline;
  final VoidCallback? onRecordings;
  final void Function(Lead updatedLead) onLeadUpdated;
  final int animationDelay;

  Future<void> _handleEditTap(BuildContext context) async {
    final updated = await showEditLeadSheet(context, lead);
    if (updated != null) {
      onLeadUpdated(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFEBE3D5), width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 8),
                _buildProjectAndUnitDetails(),
                const SizedBox(height: 8),
                _buildActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: Avatar + Name/Phone + Status + Edit
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.statusColor(lead.status.apiValue).withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  lead.initials,
                  style: TextStyle(
                    color: AppColors.statusColor(lead.status.apiValue),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Name + phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lead.fullName.isNotEmpty ? lead.fullName : 'Website Lead',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _PriorityDot(priority: lead.priority),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lead.phone,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Right side: Status badge + Edit
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusBadge(status: lead.status),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _handleEditTap(context),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.ssGold.withAlpha(80)),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: AppColors.ssGoldDark,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Project Name, Configuration (2BHK, 3BHK, 4BHK) & Arrival Date Badge
  Widget _buildProjectAndUnitDetails() {
    final proj = (lead.projectName != null && lead.projectName!.isNotEmpty) ? lead.projectName! : 'Direct Dial';
    final hasUnit = lead.unitType != null && lead.unitType!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAE0D0), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Project Name & Unit Badge (Left Side)
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Project Name
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.ssGold.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.business_rounded, size: 13, color: AppColors.ssGoldDark),
                          const SizedBox(width: 4),
                          Text(
                            proj,
                            style: TextStyle(
                              color: AppColors.ssGoldDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Unit / Requirement (2 BHK, 3 BHK, 4 BHK, Duplex, etc.) - Only shown if set!
                    if (hasUnit)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bed_rounded, size: 12, color: Color(0xFF0284C7)),
                            const SizedBox(width: 4),
                            Text(
                              lead.unitType!,
                              style: const TextStyle(
                                color: Color(0xFF0369A1),
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Lead Incoming Age Badge (Orange Mark Area - Top Right)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded, size: 10.5, color: Color(0xFF64748B)),
                    const SizedBox(width: 3),
                    Text(
                      lead.timeAgoDisplay,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          // Date & Time + Source Info (compact and clear without "Arrived:")
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 10.5, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                lead.incomingDateTimeDisplay,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 3,
                height: 3,
                decoration: const BoxDecoration(color: Color(0xFF94A3B8), shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  lead.source,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8B6914),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        _ActionButton(
          icon: Icons.phone_rounded,
          label: 'CALL',
          color: AppColors.success,
          onTap: onCall,
        ),
        const SizedBox(width: 6),
        _ActionButton(
          icon: Icons.chat_rounded,
          label: 'WHATSAPP',
          color: const Color(0xFF25D366),
          onTap: onWhatsApp,
        ),
        const SizedBox(width: 6),
        _ActionButton(
          icon: Icons.share_rounded,
          label: 'SHARE',
          color: AppColors.info,
          onTap: onShare,
        ),
        const SizedBox(width: 6),
        _ActionButton(
          icon: Icons.timeline_rounded,
          label: 'HISTORY',
          color: AppColors.ssGoldDark,
          onTap: onTimeline,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
          decoration: BoxDecoration(
            color: color.withAlpha(18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withAlpha(45), width: 0.8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final LeadStatus status;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(status.apiValue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50), width: 0.8),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  const _PriorityDot({required this.priority});
  final LeadPriority priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      LeadPriority.high => AppColors.error,
      LeadPriority.medium => AppColors.warning,
      LeadPriority.low => AppColors.textTertiary,
    };

    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
