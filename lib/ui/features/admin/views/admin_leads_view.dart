import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sales_crm_dialer/core/theme/app_colors.dart';
import 'package:sales_crm_dialer/domain/entities/lead.dart';
import 'package:sales_crm_dialer/data/repositories/remote_lead_repository.dart';
import 'package:sales_crm_dialer/ui/features/admin/view_models/admin_view_model.dart';
import 'package:sales_crm_dialer/ui/features/admin/views/widgets/reassign_lead_sheet.dart';

class AdminLeadsView extends StatefulWidget {
  final AdminViewModel adminViewModel;

  const AdminLeadsView({
    super.key,
    required this.adminViewModel,
  });

  @override
  State<AdminLeadsView> createState() => _AdminLeadsViewState();
}

class _AdminLeadsViewState extends State<AdminLeadsView> {
  List<Lead> _allLeads = [];
  bool _isLoading = true;
  String _selectedStage = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLeads();
  }

  Future<void> _loadLeads() async {
    setState(() => _isLoading = true);
    try {
      final leads = await RemoteLeadRepository.getAllLeadsStatic();
      if (mounted) {
        setState(() {
          _allLeads = leads;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _callPhone(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final url = Uri.parse('tel:$clean');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _openWhatsApp(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d]'), '');
    final target = clean.length == 10 ? '91$clean' : clean;
    final url = Uri.parse('https://wa.me/$target');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  List<Lead> get _filteredLeads {
    return _allLeads.where((lead) {
      if (_selectedStage != 'all') {
        if (lead.status.name.toLowerCase() != _selectedStage.toLowerCase()) {
          return false;
        }
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatches = lead.fullName.toLowerCase().contains(q);
        final phoneMatches = lead.phone.contains(q);
        final projectMatches = (lead.projectName ?? '').toLowerCase().contains(q);
        if (!nameMatches && !phoneMatches && !projectMatches) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final stages = [
      ('all', 'All Leads (${_allLeads.length})'),
      ('newlead', 'New Leads'),
      ('warm', 'Call Back'),
      ('interested', 'Interested'),
      ('visitscheduled', 'Visit Sched.'),
      ('visitdone', 'Visit Done'),
      ('closedwon', 'Booked'),
      ('cold', 'Not Int.'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'All Company Leads',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF5C3D0E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadLeads,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              children: [
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Search by client name, phone, project...',
                      hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      prefixIcon: Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: stages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, idx) {
                      final s = stages[idx];
                      final isSelected = _selectedStage == s.$1;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedStage = s.$1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.ssGoldDark : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.ssGoldDark : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            s.$2,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.ssGoldDark))
                : _filteredLeads.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.folder_open_rounded, size: 48, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 10),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No leads matching "$_searchQuery"'
                                  : 'No leads found in this stage',
                              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLeads,
                        color: AppColors.ssGoldDark,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 80),
                          itemCount: _filteredLeads.length,
                          itemBuilder: (context, idx) {
                            final lead = _filteredLeads[idx];
                            return _buildAdminLeadCard(lead);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminLeadCard(Lead lead) {
    Color badgeColor;
    Color badgeBg;
    String statusTitle;

    switch (lead.status) {
      case LeadStatus.newLead:
        badgeColor = const Color(0xFF2563EB);
        badgeBg = const Color(0xFFEFF6FF);
        statusTitle = 'New Lead';
        break;
      case LeadStatus.contacted:
      case LeadStatus.interested:
      case LeadStatus.hot:
        badgeColor = const Color(0xFF0D9488);
        badgeBg = const Color(0xFFF0FDFA);
        statusTitle = 'Interested';
        break;
      case LeadStatus.visitScheduled:
        badgeColor = const Color(0xFFD97706);
        badgeBg = const Color(0xFFFFFBEB);
        statusTitle = 'Visit Sched.';
        break;
      case LeadStatus.visitDone:
        badgeColor = const Color(0xFF0D9488);
        badgeBg = const Color(0xFFF0FDFA);
        statusTitle = 'Visit Done';
        break;
      case LeadStatus.closedWon:
        badgeColor = const Color(0xFFB45309);
        badgeBg = const Color(0xFFFFF8E1);
        statusTitle = 'Booking Done';
        break;
      case LeadStatus.cold:
      case LeadStatus.closedLost:
        badgeColor = const Color(0xFFDC2626);
        badgeBg = const Color(0xFFFEF2F2);
        statusTitle = 'Not Interested';
        break;
      default:
        badgeColor = const Color(0xFF475569);
        badgeBg = const Color(0xFFF1F5F9);
        statusTitle = lead.status.displayName;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.fullName.isNotEmpty ? lead.fullName : 'Customer Contact',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '📞 ${lead.phone} • ${lead.projectName ?? "SS Realty"}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor.withAlpha(60)),
                ),
                child: Text(
                  statusTitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => ReassignLeadSheet(
                        lead: lead,
                        viewModel: widget.adminViewModel,
                      ),
                    ).then((_) => _loadLeads());
                  },
                  icon: const Icon(Icons.swap_horiz_rounded, size: 15, color: AppColors.ssGoldDark),
                  label: const Text(
                    'Reassign',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ssGoldDark),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    side: const BorderSide(color: Color(0xFFEDD98A)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    backgroundColor: const Color(0xFFFFFBEB),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _openWhatsApp(lead.phone),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF16A34A)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _callPhone(lead.phone),
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Icon(Icons.phone_rounded, size: 16, color: Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
