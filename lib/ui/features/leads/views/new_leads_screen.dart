import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/lead.dart';
import '../view_models/lead_list_view_model.dart';

class NewLeadsScreen extends StatefulWidget {
  const NewLeadsScreen({
    super.key,
    required this.viewModel,
    required this.onCall,
    required this.onWhatsApp,
  });

  final LeadListViewModel viewModel;
  final void Function(Lead) onCall;
  final void Function(Lead) onWhatsApp;

  @override
  State<NewLeadsScreen> createState() => _NewLeadsScreenState();
}

class _NewLeadsScreenState extends State<NewLeadsScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Assigned Leads'),
            ListenableBuilder(
              listenable: widget.viewModel,
              builder: (_, __) => Text(
                '${widget.viewModel.leads.length} leads',
                style: AppTypography.labelSmall.copyWith(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final leads = widget.viewModel.leads;
          if (widget.viewModel.state.isLoading && leads.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (leads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_turned_in_outlined, size: 64, color: AppColors.textTertiary),
                  const SizedBox(height: 16),
                  Text('No new leads assigned!', style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => widget.viewModel.loadLeads(refresh: true),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 32),
              addRepaintBoundaries: true,
              addAutomaticKeepAlives: false,
              cacheExtent: 600,
              itemCount: leads.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final lead = leads[index];
                return _NewLeadCard(
                  lead: lead,
                  onCall: () => widget.onCall(lead),
                  onWhatsApp: () => widget.onWhatsApp(lead),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NewLeadCard extends StatelessWidget {
  const _NewLeadCard({
    required this.lead,
    required this.onCall,
    required this.onWhatsApp,
  });

  final Lead lead;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) {
    final proj = (lead.projectName != null && lead.projectName!.isNotEmpty)
        ? lead.projectName!
        : 'SS Realty Project';

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBE3D5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar + Name/Phone + NEW Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Initials Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withAlpha(40)),
                      ),
                      child: Center(
                        child: Text(
                          lead.initials,
                          style: TextStyle(
                            color: AppColors.ssGoldDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Name & Phone
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lead.fullName.isNotEmpty ? lead.fullName : 'Website Lead',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
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
                    const SizedBox(width: 8),
                    // NEW Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.ssGold.withAlpha(80)),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Color(0xFFB8860B),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Project Details Badge (Project Name Only + Clean Layout)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFBF7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEAE0D0), width: 0.8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Project Name
                      Row(
                        children: [
                          Icon(Icons.apartment_rounded, size: 14, color: AppColors.ssGoldDark),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              proj,
                              style: TextStyle(
                                color: AppColors.ssGoldDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Real Date & Time + Source
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
                          // Age indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              lead.timeAgoDisplay,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFEBE3D5)),

          // Call & WhatsApp Action Buttons
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onCall,
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone_rounded, color: AppColors.success, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Call',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 28, color: const Color(0xFFEBE3D5)),
              Expanded(
                child: InkWell(
                  onTap: onWhatsApp,
                  borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'WhatsApp',
                          style: AppTypography.labelLarge.copyWith(
                            color: const Color(0xFF25D366),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }
}
