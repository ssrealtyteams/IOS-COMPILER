import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sales_crm_dialer/core/theme/app_colors.dart';
import 'package:sales_crm_dialer/core/theme/app_typography.dart';
import 'package:sales_crm_dialer/data/models/admin_models.dart';
import 'package:sales_crm_dialer/ui/features/admin/view_models/admin_view_model.dart';
import 'package:sales_crm_dialer/ui/features/admin/views/widgets/agent_interactive_map_view.dart';
import 'package:sales_crm_dialer/ui/features/admin/views/widgets/employee_attendance_calendar_sheet.dart';

class AgentDrilldownSheet extends StatefulWidget {
  final TelecallerOverview agent;
  final AdminViewModel viewModel;
  final int initialTabIndex;

  const AgentDrilldownSheet({
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
      builder: (ctx) => AgentDrilldownSheet(
        agent: agent,
        viewModel: viewModel,
        initialTabIndex: initialTabIndex,
      ),
    );
  }

  @override
  State<AgentDrilldownSheet> createState() => _AgentDrilldownSheetState();
}

class _AgentDrilldownSheetState extends State<AgentDrilldownSheet> {
  late int _activeTab; // 0: Work & Calls, 1: Live GPS Trail, 2: Attendance Logs
  AgentDrilldownData? _drilldownData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTabIndex;
    _loadDrilldown();
  }

  Future<void> _loadDrilldown() async {
    final data = await widget.viewModel.fetchAgentDrilldown(widget.agent);
    if (mounted) {
      setState(() {
        _drilldownData = data;
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
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
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              agent.employeeId,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
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
                            size: 7,
                            color: agent.isOnline ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              agent.isOnline
                                  ? (agent.firstPunchIn != null ? 'Online • Shift: ${agent.firstPunchIn}' : 'Online Now')
                                  : (agent.firstPunchIn != null ? 'Offline • Shift: ${agent.firstPunchIn}' : 'Offline'),
                              style: TextStyle(
                                fontSize: 10.5,
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
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _callNumber(agent.phone),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(6),
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
                        padding: const EdgeInsets.all(6),
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
                        child: Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 19),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3 Mode Tabs (Work & Performance | Live GPS Trail | Attendance)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTabButton(0, '📊 Work & Calls', Icons.bar_chart_rounded),
                  _buildTabButton(1, '🗺️ GPS Route Map', Icons.map_rounded),
                  _buildTabButton(2, '📅 Attendance', Icons.calendar_month_rounded),
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

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.ssGoldDark : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case 1:
        return _buildGpsRouteTab();
      case 2:
        return _buildAttendanceTab();
      case 0:
      default:
        return _buildWorkPerformanceTab();
    }
  }

  // ─── TAB 1: Work & Performance Report ─────────────────────────────────────
  Widget _buildWorkPerformanceTab() {
    final agent = widget.agent;
    final data = _drilldownData;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
      children: [
        // 1. Top 4 Work KPIs
        Row(
          children: [
            _buildSummaryCard(
              'Total Calls',
              '${data?.todayCalls ?? agent.totalCalls}',
              Icons.phone_in_talk_rounded,
              const Color(0xFF2563EB),
              const Color(0xFFEFF6FF),
            ),
            const SizedBox(width: 8),
            _buildSummaryCard(
              'Connected',
              '${data?.todayConnected ?? agent.connectedCalls}',
              Icons.call_made_rounded,
              const Color(0xFF16A34A),
              const Color(0xFFF0FDF4),
            ),
            const SizedBox(width: 8),
            _buildSummaryCard(
              'Screen Time',
              agent.screenTimeFormatted,
              Icons.timer_rounded,
              const Color(0xFFD97706),
              const Color(0xFFFFFBEB),
            ),
            const SizedBox(width: 8),
            _buildSummaryCard(
              'Bookings',
              '${agent.bookedLeads}',
              Icons.celebration_rounded,
              const Color(0xFFB45309),
              const Color(0xFFFFF8E1),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 1.5 Individual Lead Assignment Toggle Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: agent.isQueueActive ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
              width: agent.isQueueActive ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: agent.isQueueActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_add_rounded,
                  size: 16,
                  color: agent.isQueueActive ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-Assign Leads to ${agent.name.split(" ").first}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      agent.isQueueActive ? 'Queue Active • Receiving leads' : 'Queue Paused • Not receiving leads',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: agent.isQueueActive ? const Color(0xFF166534) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: agent.isQueueActive,
                  activeThumbColor: AppColors.ssGoldDark,
                  activeTrackColor: const Color(0xFFFDE68A),
                  onChanged: (val) {
                    widget.viewModel.toggleTelecallerQueue(agent.id, val);
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. Lead Conversion Funnel
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lead Pipeline Performance',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildFunnelItem('Assigned', '${agent.assignedLeads}', const Color(0xFF2563EB)),
                  _buildFunnelItem('Not Int.', '${agent.notInterestedLeads}', const Color(0xFFDC2626)),
                  _buildFunnelItem('V. Sched', '${agent.visitScheduledLeads}', const Color(0xFFD97706)),
                  _buildFunnelItem('V. Done', '${agent.visitDoneLeads}', const Color(0xFF0D9488)),
                  _buildFunnelItem('Booked', '${agent.bookedLeads}', const Color(0xFFB45309)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 3. Customer Call Logs Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Customer Call Logs & Notes',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${data?.callLogs.length ?? 0} Calls',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if ((data?.callLogs ?? []).isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              children: [
                Icon(Icons.phone_missed_rounded, size: 36, color: Color(0xFF94A3B8)),
                SizedBox(height: 8),
                Text(
                  'No calls logged for this period yet',
                  style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          )
        else
          ...(data!.callLogs).map((call) => _buildCallLogItem(call)),
      ],
    );
  }

  // ─── TAB 2: Live GPS Route Trail Map ───────────────────────────────────────
  Widget _buildGpsRouteTab() {
    final route = _drilldownData?.routeHistory;

    if (route == null) {
      return const Center(child: Text('Loading GPS telemetry...'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
      children: [
        // Interactive Real Google Maps Component (Large Viewport)
        AgentInteractiveMapView(
          route: route,
          height: 420,
          showControls: true,
        ),

        const SizedBox(height: 12),

        // Live Telemetry Stats
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              _buildMiniMetric('Dist from Base', route.distanceFormatted, const Color(0xFFD97706)),
              _buildMiniMetric('ETA to Office', route.estimatedTimeToOffice, const Color(0xFF2563EB)),
              _buildMiniMetric('Total Trail', '${route.totalDistanceTravelledKm.toStringAsFixed(1)} km', const Color(0xFFB45309)),
              _buildMiniMetric('Battery', '${route.batteryPercent}%', const Color(0xFF16A34A)),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Movement Timeline Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Route Timeline (Where Agent Went)',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${route.waypoints.length} Stops',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ],
        ),

        const SizedBox(height: 10),

        ...List.generate(route.waypoints.length, (idx) {
          final wp = route.waypoints[idx];
          final isFirst = idx == 0;
          final isLast = idx == route.waypoints.length - 1;
          return _buildWaypointRow(wp, idx + 1, isFirst, isLast);
        }),
      ],
    );
  }

  // ─── TAB 3: Attendance & Punch-In/Out History ──────────────────────────────
  Widget _buildAttendanceTab() {
    final reports = _drilldownData?.dailyWorkReports ?? [];
    final agent = widget.agent;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
      children: [
        // Attendance Overview Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Monthly Attendance Summary',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      EmployeeAttendanceCalendarSheet.show(context, agent);
                    },
                    icon: const Icon(Icons.calendar_month_rounded, size: 14),
                    label: const Text('Full Calendar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ssGoldDark,
                      side: const BorderSide(color: AppColors.ssGoldDark),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildMiniMetric('Present', '21 Days', const Color(0xFF16A34A)),
                  _buildMiniMetric('Late In', '2 Days', const Color(0xFFD97706)),
                  _buildMiniMetric('Absent', '1 Day', const Color(0xFFDC2626)),
                  _buildMiniMetric('Grace Rule', '10:10 AM', const Color(0xFF2563EB)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'Daily Punch-In & Punch-Out Logs',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),

        const SizedBox(height: 10),

        if (reports.isEmpty)
          const Center(child: Text('No attendance records available.'))
        else
          ...reports.map((r) => _buildDailyReportCard(r)),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: color.withAlpha(200),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunnelItem(String label, String count, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String title, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCallLogItem(AgentCallLog call) {
    final timeStr = DateFormat('hh:mm a').format(call.callTime);

    Color dispColor = const Color(0xFF2563EB);
    Color dispBg = const Color(0xFFEFF6FF);

    switch (call.disposition.toLowerCase()) {
      case 'visit scheduled':
      case 'visit done':
        dispColor = const Color(0xFF0D9488);
        dispBg = const Color(0xFFF0FDFA);
        break;
      case 'interested':
      case 'call back scheduled':
        dispColor = const Color(0xFF2563EB);
        dispBg = const Color(0xFFEFF6FF);
        break;
      case 'closed':
      case 'booking done':
        dispColor = const Color(0xFFB45309);
        dispBg = const Color(0xFFFFF8E1);
        break;
      case 'not interested':
        dispColor = const Color(0xFFDC2626);
        dispBg = const Color(0xFFFEF2F2);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                      call.customerName,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '📞 ${call.customerPhone} • $timeStr (${call.durationFormatted})',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: dispBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: dispColor.withAlpha(60)),
                ),
                child: Text(
                  call.disposition,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: dispColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (call.notes != null && call.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '📝 ${call.notes!}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWaypointRow(AgentGpsWaypoint wp, int index, bool isFirst, bool isLast) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isFirst
                  ? const Color(0xFFDCFCE7)
                  : isLast
                      ? const Color(0xFFFFE4E6)
                      : const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFirst
                  ? Icons.flag_rounded
                  : isLast
                      ? Icons.location_on_rounded
                      : Icons.pin_drop_rounded,
              size: 14,
              color: isFirst
                  ? const Color(0xFF16A34A)
                  : isLast
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        wp.isHalt ? '⏳ HALT / STOP' : wp.activityTag,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: wp.isHalt ? const Color(0xFFC2410C) : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      wp.timeFormatted,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                if (wp.isHalt) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '⏳ Stayed for ${wp.stayDurationFormatted} (${wp.haltIntervalFormatted})',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  wp.address,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 2),
                Text(
                  '${(wp.distanceFromOfficeMeters / 1000).toStringAsFixed(2)} km from Jonapur Base • Speed: ${wp.speedKmh.toStringAsFixed(0)} km/h',
                  style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyReportCard(AgentDailyWorkReport report) {
    final dateStr = DateFormat('EEE, d MMM').format(report.date);
    final isPresent = report.attendanceStatus.toLowerCase() == 'present';
    final isLate = report.attendanceStatus.toLowerCase() == 'late in';

    Color statusColor = const Color(0xFF16A34A);
    Color statusBg = const Color(0xFFF0FDF4);
    if (isLate) {
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFFFBEB);
    } else if (!isPresent) {
      statusColor = const Color(0xFFDC2626);
      statusBg = const Color(0xFFFEF2F2);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withAlpha(60)),
                ),
                child: Text(
                  report.attendanceStatus,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (report.punchInTime != null) ...[
            Row(
              children: [
                const Icon(Icons.login_rounded, size: 13, color: Color(0xFF16A34A)),
                const SizedBox(width: 4),
                Text('In: ${report.punchInTime}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                const Icon(Icons.logout_rounded, size: 13, color: Color(0xFFDC2626)),
                const SizedBox(width: 4),
                Text('Out: ${report.punchOutTime ?? "Shift On"}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('Work: ${report.totalWorkHours}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ssGoldDark)),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Row(
            children: [
              Text(
                '📞 ${report.totalCalls} Calls (${report.connectedCalls} connected) • ⏱️ App: ${report.screenTimeMinutes}m',
                style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  report.gpsTrailSummary,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
