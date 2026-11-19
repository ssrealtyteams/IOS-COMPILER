import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sales_crm_dialer/core/theme/app_colors.dart';
import 'package:sales_crm_dialer/data/models/admin_models.dart';
import 'package:sales_crm_dialer/ui/features/admin/view_models/admin_view_model.dart';

class AgentPerformanceDrilldownSheet extends StatefulWidget {
  final TelecallerOverview agent;
  final AdminViewModel viewModel;
  final int initialTabIndex; // 0: Visit Sched, 1: Visit Done, 2: Booking Done, 3: All Calls

  const AgentPerformanceDrilldownSheet({
    super.key,
    required this.agent,
    required this.viewModel,
    this.initialTabIndex = 0,
  });

  static void show(
    BuildContext context,
    TelecallerOverview agent,
    AdminViewModel viewModel, {
    int initialTabIndex = 0,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AgentPerformanceDrilldownSheet(
        agent: agent,
        viewModel: viewModel,
        initialTabIndex: initialTabIndex,
      ),
    );
  }

  @override
  State<AgentPerformanceDrilldownSheet> createState() => _AgentPerformanceDrilldownSheetState();
}

class _AgentPerformanceDrilldownSheetState extends State<AgentPerformanceDrilldownSheet> {
  late int _activeTab; // 0: Visit Sched, 1: Visit Done, 2: Booking Done, 3: All Calls
  AgentCustomerBreakdown? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTabIndex;
    _loadData();
  }

  Future<void> _loadData() async {
    final res = await widget.viewModel.fetchAgentCustomerBreakdown(widget.agent);
    if (mounted) {
      setState(() {
        _data = res;
        _isLoading = false;
      });
    }
  }

  void _callNumber(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final url = Uri.parse('tel:$clean');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _openWhatsApp(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final url = Uri.parse('whatsapp://send?phone=$clean');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final agent = widget.agent;
    final initials = agent.name.trim().isNotEmpty
        ? agent.name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : 'AG';

    final schedCount = _data?.visitScheduled.length ?? agent.visitScheduledLeads;
    final doneCount = _data?.visitDone.length ?? agent.visitDoneLeads;
    final bookCount = _data?.bookingDone.length ?? agent.bookedLeads;
    final callsCount = _data?.allCallLogs.length ?? agent.totalCalls;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 6),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header: Agent Info & Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.ssGoldDark, AppColors.ssGold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              agent.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              agent.employeeId,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            agent.isOnline ? Icons.circle : Icons.circle_outlined,
                            size: 7.5,
                            color: agent.isOnline ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              agent.isOnline
                                  ? (agent.firstPunchIn != null ? 'Online • Shift: ${agent.firstPunchIn}' : 'Online Now')
                                  : (agent.firstPunchIn != null ? 'Offline • Shift: ${agent.firstPunchIn}' : 'Offline'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: agent.isOnline ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _callNumber(agent.phone),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: const Icon(Icons.phone_rounded, color: Color(0xFF16A34A), size: 15),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _openWhatsApp(agent.phone),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF6EE7B7)),
                        ),
                        child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF059669), size: 15),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3 Mode Tabs: Visit Scheduled, Visit Done, Booking Done, All Calls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTabButton(0, '📅 Sched ($schedCount)', const Color(0xFFD97706)),
                  _buildTabButton(1, '🚗 Done ($doneCount)', const Color(0xFF0D9488)),
                  _buildTabButton(2, '🏆 Booked ($bookCount)', const Color(0xFFB45309)),
                  _buildTabButton(3, '📞 Calls ($callsCount)', const Color(0xFF2563EB)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Tab Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.ssGoldDark),
                  )
                : _buildActiveTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, Color activeColor) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? activeColor : const Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case 0:
        return _buildCustomerListSection(
          title: '📅 Site Visits Scheduled',
          subtitle: 'Customers who have agreed for project site visit',
          items: _data?.visitScheduled ?? [],
          badgeColor: const Color(0xFFD97706),
          badgeBg: const Color(0xFFFFFBEB),
          statusLabel: 'Visit Scheduled',
          emptyMessage: 'No site visits scheduled currently for ${widget.agent.name}',
        );
      case 1:
        return _buildCustomerListSection(
          title: '🚗 Site Visits Done',
          subtitle: 'Customers whose physical property visit is completed',
          items: _data?.visitDone ?? [],
          badgeColor: const Color(0xFF0D9488),
          badgeBg: const Color(0xFFF0FDFA),
          statusLabel: 'Visit Completed',
          emptyMessage: 'No completed visits recorded currently for ${widget.agent.name}',
        );
      case 2:
        return _buildCustomerListSection(
          title: '🏆 Bookings / Deals Closed',
          subtitle: 'Customers who confirmed token advance and deal closure',
          items: _data?.bookingDone ?? [],
          badgeColor: const Color(0xFFB45309),
          badgeBg: const Color(0xFFFFF8E1),
          statusLabel: 'Booking Done',
          emptyMessage: 'No closed bookings recorded currently for ${widget.agent.name}',
        );
      case 3:
      default:
        return _buildCallLogsSection();
    }
  }

  Widget _buildCustomerListSection({
    required String title,
    required String subtitle,
    required List<CustomerBreakdownItem> items,
    required Color badgeColor,
    required Color badgeBg,
    required String statusLabel,
    required String emptyMessage,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: badgeBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.folder_open_rounded, size: 36, color: badgeColor),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              Text(
                emptyMessage,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor.withAlpha(60)),
                  ),
                  child: Text(
                    '${items.length} Customers',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: badgeColor),
                  ),
                ),
              ],
            ),
          );
        }

        final item = items[index - 1];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
              // Row 1: Customer Name + Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.customerName,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 12.5, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              item.customerPhone.isNotEmpty ? item.customerPhone : 'Number hidden',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: badgeColor.withAlpha(70)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),

              // Row 2: Property Requirement & Scheduled Date
              Row(
                children: [
                  if (item.projectName != null && item.projectName!.isNotEmpty) ...[
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.apartment_rounded, size: 13.5, color: AppColors.ssGoldDark),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              item.projectName!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        item.formattedDate,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Row 3: Agent Remarks / Customer Notes (if any)
              if (item.notes != null && item.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes_rounded, size: 13, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.notes!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF334155),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // Row 4: Action Buttons (Direct Call & WhatsApp)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _callNumber(item.customerPhone),
                      icon: const Icon(Icons.call_rounded, size: 14, color: Color(0xFF16A34A)),
                      label: const Text(
                        'Call Customer',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF0FDF4),
                        side: const BorderSide(color: Color(0xFF86EFAC)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openWhatsApp(item.customerPhone),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF059669)),
                      label: const Text(
                        'WhatsApp',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFECFDF5),
                        side: const BorderSide(color: Color(0xFF6EE7B7)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCallLogsSection() {
    final calls = _data?.allCallLogs ?? [];
    if (calls.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_in_talk_rounded, size: 36, color: Color(0xFF2563EB)),
              ),
              const SizedBox(height: 12),
              const Text(
                '📞 Customer Call History',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              Text(
                'No recorded calls placed yet by ${widget.agent.name}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      itemCount: calls.length,
      itemBuilder: (context, index) {
        final call = calls[index];
        final isConnected = call.durationSeconds > 0 || (!call.disposition.toLowerCase().contains('not') && !call.disposition.toLowerCase().contains('miss'));

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isConnected ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isConnected ? Icons.call_made_rounded : Icons.call_missed_rounded,
                  size: 16,
                  color: isConnected ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      call.customerName,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${call.customerPhone} • ${call.disposition}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isConnected ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                      ),
                    ),
                    if (call.notes != null && call.notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          call.notes!,
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    call.durationFormatted,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${call.callTime.hour.toString().padLeft(2, '0')}:${call.callTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
