import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sales_crm_dialer/core/theme/app_colors.dart';
import 'package:sales_crm_dialer/data/models/admin_models.dart';
import 'package:sales_crm_dialer/data/repositories/admin_repository.dart';
import 'package:sales_crm_dialer/ui/features/admin/view_models/admin_view_model.dart';
import 'package:sales_crm_dialer/ui/features/admin/views/widgets/agent_drilldown_sheet.dart';

class AdminAutomationView extends StatefulWidget {
  final AdminViewModel? adminViewModel;
  const AdminAutomationView({super.key, this.adminViewModel});

  @override
  State<AdminAutomationView> createState() => _AdminAutomationViewState();
}

class _AdminAutomationViewState extends State<AdminAutomationView> {
  final AdminRepository _repo = AdminRepository();
  late final AdminViewModel _adminViewModel = widget.adminViewModel ?? AdminViewModel();
  final TextEditingController _searchCtrl = TextEditingController();

  String _selectedPeriod = 'month'; // 'today', 'week', 'month', 'all'
  int _selectedPieIndex = -1;
  bool _isLoading = true;
  List<TelecallerOverview> _associates = [];

  @override
  void initState() {
    super.initState();
    if (widget.adminViewModel != null && widget.adminViewModel!.telecallers.isNotEmpty) {
      _associates = widget.adminViewModel!.telecallers;
      _isLoading = false;
    }
    _loadPerformanceData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPerformanceData() async {
    setState(() => _isLoading = true);
    try {
      final list = await _repo.fetchTelecallers(period: _selectedPeriod);
      if (mounted) {
        setState(() {
          _associates = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<TelecallerOverview> get _filteredAssociates {
    var list = List<TelecallerOverview>.from(_associates);

    if (_searchCtrl.text.isNotEmpty) {
      final q = _searchCtrl.text.toLowerCase();
      list = list.where((a) =>
          a.name.toLowerCase().contains(q) ||
          a.employeeId.toLowerCase().contains(q)).toList();
    }

    // Sort by bookings (desc), then visits done (desc), then assigned
    list.sort((a, b) {
      if (b.bookedLeads != a.bookedLeads) {
        return b.bookedLeads.compareTo(a.bookedLeads);
      }
      if (b.visitDoneLeads != a.visitDoneLeads) {
        return b.visitDoneLeads.compareTo(a.visitDoneLeads);
      }
      return b.visitScheduledLeads.compareTo(a.visitScheduledLeads);
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredAssociates;

    int totalAssigned = 0;
    int totalNotInt = 0;
    int totalSched = 0;
    int totalDone = 0;
    int totalBooked = 0;

    for (final a in list) {
      totalAssigned += a.assignedLeads;
      totalNotInt += a.notInterestedLeads;
      totalSched += a.visitScheduledLeads;
      totalDone += a.visitDoneLeads;
      totalBooked += a.bookedLeads;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          '📊 Associate Conversion & Graph Hub',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF5C3D0E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh performance data',
            onPressed: _loadPerformanceData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.ssGoldDark))
          : RefreshIndicator(
              onRefresh: _loadPerformanceData,
              color: AppColors.ssGoldDark,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
                children: [
                  // 1. Period Selector (Today, Week, Month, All Time)
                  _buildPeriodSelector(),

                  const SizedBox(height: 12),

                  // 2. 🟢 Live Associates Punched In & Team Total Work / Productivity KPIs (Sabka Total)
                  _buildLiveTeamPulseKPIs(
                    list: list,
                    totalAssigned: totalAssigned,
                    totalNotInt: totalNotInt,
                    totalSched: totalSched,
                    totalDone: totalDone,
                    totalBooked: totalBooked,
                  ),

                  const SizedBox(height: 14),

                  // 3. Search Associate
                  _buildSearchBar(),

                  const SizedBox(height: 14),

                  // 4. 📊 Master Employee Performance Grouped Bar Chart
                  _buildBarChartSection(list),

                  const SizedBox(height: 16),

                  // 5. 🥧 Pipeline & Conversion Funnel Chart
                  _buildPipelineFunnelSection(
                    totalAssigned: totalAssigned,
                    totalNotInt: totalNotInt,
                    totalSched: totalSched,
                    totalDone: totalDone,
                    totalBooked: totalBooked,
                  ),

                  const SizedBox(height: 16),

                  // 6. 👥 Detailed Associate Conversion Scorecards List
                  _buildAssociatesScorecardsList(list),
                ],
              ),
            ),
    );
  }

  // ─── 1. Period Selector ───────────────────────────────────────────────────
  Widget _buildPeriodSelector() {
    const periods = [
      ('today', 'Today'),
      ('week', 'This Week'),
      ('month', 'This Month'),
      ('all', 'All Time'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: periods.map((p) {
          final isSelected = _selectedPeriod == p.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedPeriod = p.$1);
                _loadPerformanceData();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [AppColors.ssGoldDark, AppColors.ssGold],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  p.$2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── 2. Live Team Pulse & Productivity KPIs ──────────────────────────────
  Widget _buildLiveTeamPulseKPIs({
    required List<TelecallerOverview> list,
    required int totalAssigned,
    required int totalNotInt,
    required int totalSched,
    required int totalDone,
    required int totalBooked,
  }) {
    // Dynamic live count of all associates (auto-adapts when new associates are created in future)
    final totalAgents = _associates.length;
    final punchedInCount = _associates.where((a) => a.isOnline || (a.firstPunchIn != null && a.firstPunchIn!.isNotEmpty)).length;

    // Total screen time / logged work time & calls
    int totalMinutes = 0;
    int totalCalls = 0;
    int totalConnected = 0;
    for (final a in _associates) {
      totalMinutes += a.screenTimeMinutes > 0 ? a.screenTimeMinutes : 0;
      totalCalls += a.totalCalls;
      totalConnected += a.connectedCalls;
    }
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    final teamTimeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
    final connRate = totalCalls > 0 ? ((totalConnected / totalCalls) * 100).toStringAsFixed(0) : '0';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Live Punched-In Indicator + Dynamic Total Agents + Team Time
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ).animate(onPlay: (c) => c.repeat()).fade(duration: 700.ms).then().fade(duration: 700.ms, begin: 1.0, end: 0.3),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        '$punchedInCount / $totalAgents Associates Punched In',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_rounded, size: 13, color: Color(0xFFD97706)),
                    const SizedBox(width: 4),
                    Text(
                      'Team: $teamTimeStr',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Row 2: 5 KPI Boxes (Team Total Assigned Leads & Work Distribution)
          Row(
            children: [
              _buildPulseBadge('Assigned', '$totalAssigned', const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
              const SizedBox(width: 5),
              _buildPulseBadge('Not Int.', '$totalNotInt', const Color(0xFFDC2626), const Color(0xFFFEF2F2)),
              const SizedBox(width: 5),
              _buildPulseBadge('V. Sched', '$totalSched', const Color(0xFFD97706), const Color(0xFFFFFBEB)),
              const SizedBox(width: 5),
              _buildPulseBadge('V. Done', '$totalDone', const Color(0xFF0D9488), const Color(0xFFF0FDFA)),
              const SizedBox(width: 5),
              _buildPulseBadge('Booked', '$totalBooked', const Color(0xFFB45309), const Color(0xFFFFF8E1)),
            ],
          ),

          const SizedBox(height: 10),

          // Row 3: Team Calls Summary Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone_in_talk_rounded, size: 14, color: Color(0xFF2563EB)),
                    const SizedBox(width: 5),
                    Text(
                      'Total Team Calls: $totalCalls',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                    ),
                  ],
                ),
                Text(
                  'Connected: $totalConnected ($connRate%)',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseBadge(String label, String value, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: color.withAlpha(200),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── 3. Search Bar ────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search associate name, SSR ID in graph...',
          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() {});
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ─── 3. Master Multi-Bar Comparison Chart ─────────────────────────────────
  Widget _buildBarChartSection(List<TelecallerOverview> list) {
    final associates = list.take(8).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 Associate Lead Breakdown Graph',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Multi-metric comparison for all team members',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  '${associates.length} Associates',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Legend Bar
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              _buildLegendPill('Assigned', const Color(0xFF2563EB)),
              _buildLegendPill('Not Int.', const Color(0xFFEF4444)),
              _buildLegendPill('V. Sched', const Color(0xFFF59E0B)),
              _buildLegendPill('V. Done', const Color(0xFF10B981)),
              _buildLegendPill('Booked', const Color(0xFFD97706)),
            ],
          ),

          const SizedBox(height: 20),

          // Bar Chart Container (Horizontally scrollable for all screen widths)
          SizedBox(
            height: 230,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: (associates.length * 64.0).clamp(320.0, 900.0),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 12,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF0F172A),
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final agent = associates[group.x.toInt()];
                      final labels = ['Assigned', 'Not Int', 'V. Sched', 'V. Done', 'Booked'];
                      final colors = [
                        const Color(0xFF2563EB),
                        const Color(0xFFEF4444),
                        const Color(0xFFF59E0B),
                        const Color(0xFF10B981),
                        const Color(0xFFD97706),
                      ];
                      return BarTooltipItem(
                        '${agent.name.split(' ').first}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: '${labels[rodIndex]}: ${rod.toY.toInt()}',
                            style: TextStyle(
                              color: colors[rodIndex],
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 3,
                      getTitlesWidget: (val, meta) {
                        return Text(
                          val.toInt().toString(),
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= associates.length) return const SizedBox();
                        final name = associates[idx].name.split(' ').first;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 3,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0xFFF1F5F9),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(associates.length, (i) {
                  final a = associates[i];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      // 1. Assigned Leads
                      BarChartRodData(
                        toY: a.assignedLeads.toDouble(),
                        color: const Color(0xFF2563EB),
                        width: 4.5,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                      // 2. Not Interested
                      BarChartRodData(
                        toY: a.notInterestedLeads.toDouble(),
                        color: const Color(0xFFEF4444),
                        width: 4.5,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                      // 3. Visit Scheduled
                      BarChartRodData(
                        toY: a.visitScheduledLeads.toDouble(),
                        color: const Color(0xFFF59E0B),
                        width: 4.5,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                      // 4. Visit Done
                      BarChartRodData(
                        toY: a.visitDoneLeads.toDouble(),
                        color: const Color(0xFF10B981),
                        width: 4.5,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                      // 5. Bookings
                      BarChartRodData(
                        toY: a.bookedLeads.toDouble(),
                        color: const Color(0xFFD97706),
                        width: 4.5,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    ],
  ),
);
}

  Widget _buildLegendPill(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  // ─── 4. Pipeline & Conversion Funnel Section ──────────────────────────────
  Widget _buildPipelineFunnelSection({
    required int totalAssigned,
    required int totalNotInt,
    required int totalSched,
    required int totalDone,
    required int totalBooked,
  }) {
    final total = totalAssigned;
    final openLeads = (totalAssigned - totalNotInt - totalSched - totalDone - totalBooked).clamp(0, totalAssigned);

    final List<PieChartSectionData> pieSections;
    if (total == 0) {
      pieSections = [
        PieChartSectionData(
          value: 1,
          color: const Color(0xFFE2E8F0),
          radius: 16,
          showTitle: false,
        ),
      ];
    } else {
      pieSections = [
        if (openLeads > 0)
          PieChartSectionData(
            value: openLeads.toDouble(),
            color: const Color(0xFF2563EB),
            radius: _selectedPieIndex == 0 ? 22 : 18,
            showTitle: false,
          ),
        if (totalNotInt > 0)
          PieChartSectionData(
            value: totalNotInt.toDouble(),
            color: const Color(0xFFEF4444),
            radius: _selectedPieIndex == 1 ? 22 : 18,
            showTitle: false,
          ),
        if (totalSched > 0)
          PieChartSectionData(
            value: totalSched.toDouble(),
            color: const Color(0xFFF59E0B),
            radius: _selectedPieIndex == 2 ? 22 : 18,
            showTitle: false,
          ),
        if (totalDone > 0)
          PieChartSectionData(
            value: totalDone.toDouble(),
            color: const Color(0xFF10B981),
            radius: _selectedPieIndex == 3 ? 22 : 18,
            showTitle: false,
          ),
        if (totalBooked > 0)
          PieChartSectionData(
            value: totalBooked.toDouble(),
            color: const Color(0xFFD97706),
            radius: _selectedPieIndex == 4 ? 22 : 18,
            showTitle: false,
          ),
      ];
      if (pieSections.isEmpty) {
        pieSections.add(
          PieChartSectionData(
            value: 1,
            color: const Color(0xFFE2E8F0),
            radius: 16,
            showTitle: false,
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 Team Pipeline & Conversion Distribution',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Overall lead lifecycle progress & conversion stages',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 16),

          // Donut Chart + Stage Breakdown Row
          Row(
            children: [
              // Donut Chart
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        pieTouchData: PieTouchData(
                          touchCallback: (event, pieResponse) {
                            setState(() {
                              if (pieResponse?.touchedSection != null &&
                                  event is! FlTapUpEvent &&
                                  event is! FlPanEndEvent) {
                                _selectedPieIndex = pieResponse!.touchedSection!.touchedSectionIndex;
                              } else {
                                _selectedPieIndex = -1;
                              }
                            });
                          },
                        ),
                        sections: pieSections,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Text(
                          'Total Leads',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Conversion Funnel Steps
              Expanded(
                child: Column(
                  children: [
                    _buildFunnelStage('1. Assigned Leads', '$totalAssigned', total > 0 ? '100%' : '0%', const Color(0xFF2563EB)),
                    const SizedBox(height: 6),
                    _buildFunnelStage('2. Not Interested', '$totalNotInt', total > 0 ? '${((totalNotInt / total) * 100).toStringAsFixed(1)}%' : '0.0%', const Color(0xFFEF4444)),
                    const SizedBox(height: 6),
                    _buildFunnelStage('3. Visit Scheduled', '$totalSched', total > 0 ? '${((totalSched / total) * 100).toStringAsFixed(1)}%' : '0.0%', const Color(0xFFF59E0B)),
                    const SizedBox(height: 6),
                    _buildFunnelStage('4. Visit Done', '$totalDone', total > 0 ? '${((totalDone / total) * 100).toStringAsFixed(1)}%' : '0.0%', const Color(0xFF10B981)),
                    const SizedBox(height: 6),
                    _buildFunnelStage('5. Bookings Closed', '$totalBooked', total > 0 ? '${((totalBooked / total) * 100).toStringAsFixed(1)}%' : '0.0%', const Color(0xFFD97706)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFunnelStage(String stage, String count, String pct, Color color) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            stage,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          count,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            pct,
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: color),
          ),
        ),
      ],
    );
  }

  // ─── 5. Detailed Associate Conversion Scorecards List ─────────────────────
  Widget _buildAssociatesScorecardsList(List<TelecallerOverview> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '👥 Individual Performance Scorecards (${list.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Ranked by Deals',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ...List.generate(list.length, (idx) {
          final a = list[idx];
          return _buildAssociateScorecard(a, idx + 1);
        }),
      ],
    );
  }

  Widget _buildAssociateScorecard(TelecallerOverview agent, int rank) {
    final rankColor = rank == 1
        ? const Color(0xFFFBBF24)
        : rank == 2
            ? const Color(0xFF94A3B8)
            : rank == 3
                ? const Color(0xFFF97316)
                : const Color(0xFF64748B);

    final total = agent.assignedLeads > 0 ? agent.assignedLeads : 1;
    final convPct = ((agent.bookedLeads + agent.visitDoneLeads) / total * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rank == 1 ? const Color(0xFFFBBF24).withAlpha(120) : const Color(0xFFE2E8F0),
          width: rank == 1 ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          AgentDrilldownSheet.show(context, agent, _adminViewModel);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
          children: [
            // Top Row: Rank + Avatar + Name + SSR ID + Conv. Badge
            Row(
              children: [
                // Rank Circle
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: rankColor.withAlpha(30),
                    shape: BoxShape.circle,
                    border: Border.all(color: rankColor),
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: rankColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Avatar
                Container(
                  width: 38,
                  height: 38,
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
                      agent.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Name & Employee ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              agent.name,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Text(
                              agent.employeeId,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${agent.totalCalls} Calls • ${agent.connectedCalls} Connected (${((agent.connectedCalls / (agent.totalCalls > 0 ? agent.totalCalls : 1)) * 100).round()}%)',
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),

                // Conversion Rate Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: convPct > 0 ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: convPct > 0 ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$convPct%',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: convPct > 0 ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                        ),
                      ),
                      const Text(
                        'Conversion',
                        style: TextStyle(fontSize: 8.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 5-Metric Breakdown Badges
            Row(
              children: [
                _buildCardMetricBadge('Assigned', '${agent.assignedLeads}', const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
                const SizedBox(width: 4),
                _buildCardMetricBadge('Not Int.', '${agent.notInterestedLeads}', const Color(0xFFDC2626), const Color(0xFFFEF2F2)),
                const SizedBox(width: 4),
                _buildCardMetricBadge('V. Sched', '${agent.visitScheduledLeads}', const Color(0xFFD97706), const Color(0xFFFFFBEB)),
                const SizedBox(width: 4),
                _buildCardMetricBadge('V. Done', '${agent.visitDoneLeads}', const Color(0xFF0D9488), const Color(0xFFF0FDFA)),
                const SizedBox(width: 4),
                _buildCardMetricBadge('Booked', '${agent.bookedLeads}', const Color(0xFFB45309), const Color(0xFFFFF8E1)),
              ],
            ),

            const SizedBox(height: 10),

            // Multi-segment Visual Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: [
                    // Booked
                    if (agent.bookedLeads > 0)
                      Expanded(
                        flex: agent.bookedLeads,
                        child: Container(color: const Color(0xFFD97706)),
                      ),
                    // Visit Done
                    if (agent.visitDoneLeads > 0)
                      Expanded(
                        flex: agent.visitDoneLeads,
                        child: Container(color: const Color(0xFF10B981)),
                      ),
                    // Visit Sched
                    if (agent.visitScheduledLeads > 0)
                      Expanded(
                        flex: agent.visitScheduledLeads,
                        child: Container(color: const Color(0xFFF59E0B)),
                      ),
                    // Not Int
                    if (agent.notInterestedLeads > 0)
                      Expanded(
                        flex: agent.notInterestedLeads,
                        child: Container(color: const Color(0xFFEF4444)),
                      ),
                    // Remaining In Progress
                    Expanded(
                      flex: (agent.assignedLeads -
                              agent.bookedLeads -
                              agent.visitDoneLeads -
                              agent.visitScheduledLeads -
                              agent.notInterestedLeads)
                          .clamp(1, 999),
                      child: Container(color: const Color(0xFFE2E8F0)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildCardMetricBadge(String label, String val, Color textCol, Color bgCol) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 1),
        decoration: BoxDecoration(
          color: bgCol,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: textCol.withAlpha(40)),
        ),
        child: Column(
          children: [
            Text(
              val,
              style: TextStyle(
                color: textCol,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: textCol.withAlpha(200),
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
