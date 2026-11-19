import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sales_crm_dialer/core/theme/app_colors.dart';
import 'package:sales_crm_dialer/data/models/admin_models.dart';
import 'package:sales_crm_dialer/ui/features/admin/view_models/admin_view_model.dart';
import 'package:sales_crm_dialer/ui/features/admin/views/widgets/agent_performance_drilldown_sheet.dart';

import 'package:sales_crm_dialer/ui/features/admin/views/widgets/director_profile_sheet.dart';

class AdminDashboardScreen extends StatefulWidget {
  final AdminViewModel viewModel;
  final VoidCallback? onSwitchToTelecallerMode;

  const AdminDashboardScreen({
    super.key,
    required this.viewModel,
    this.onSwitchToTelecallerMode,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  AdminViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    _vm.init();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final telecallers = _vm.telecallers;

          // Compute Sabka Total live from associates list / stats
          int teamSched = 0;
          int teamDone = 0;
          int teamBooked = 0;

          for (final a in telecallers) {
            teamSched += a.visitScheduledLeads;
            teamDone += a.visitDoneLeads;
            teamBooked += a.bookedLeads;
          }

          if (teamSched == 0 && _vm.stats.visitScheduledLeads > 0) teamSched = _vm.stats.visitScheduledLeads;
          if (teamDone == 0 && _vm.stats.visitDoneLeads > 0) teamDone = _vm.stats.visitDoneLeads;
          if (teamBooked == 0 && _vm.stats.bookedLeads > 0) teamBooked = _vm.stats.bookedLeads;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                _buildExecutiveAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // 1. Period Selector (Today, This Week, This Month, All Time)
                      _buildPeriodSelector(),

                      // 2. 3 High-Impact Executive Performance KPI Cards (Sabka Total)
                      _buildDepthSummaryCards(
                        schedCount: teamSched,
                        doneCount: teamDone,
                        bookedCount: teamBooked,
                      ),

                      // 3. 📊 Team Visits & Bookings Comparative Graph
                      if (telecallers.isNotEmpty)
                        _buildVisitsBookingsBarChart(telecallers),

                      // 4. Search Associate
                      _buildSearchBar(),

                      // 5. Header for Ranked Associates List
                      _buildTelecallersHeader(telecallers.length),
                    ],
                  ),
                ),
              ];
            },
            body: _buildTelecallersList(telecallers),
          );
        },
      ),
    );
  }

  // ─── 1. Executive App Bar ─────────────────────────────────────────────────
  SliverAppBar _buildExecutiveAppBar() {
    return SliverAppBar(
      expandedHeight: 110,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF5C3D0E),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 14),
        title: GestureDetector(
          onTap: () => DirectorProfileSheet.show(context, _vm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDD98A),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'DIRECTOR SUITE',
                      style: TextStyle(
                        color: Color(0xFF5C3D0E),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '• Profile & Intelligence',
                    style: TextStyle(
                      color: Color(0xFFEDD98A),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Row(
                children: [
                  Text(
                    'Yogesh Tanwar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down_rounded, color: Color(0xFFEDD98A), size: 18),
                ],
              ),
            ],
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3E2723), Color(0xFF5C3D0E), Color(0xFF8B6914)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          tooltip: 'Refresh performance data',
          onPressed: () => _vm.loadData(),
        ),
        GestureDetector(
          onTap: () => DirectorProfileSheet.show(context, _vm),
          child: Container(
            margin: const EdgeInsets.only(right: 14, left: 4),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEDD98A), Color(0xFFD4AF37)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'YT',
                style: TextStyle(
                  color: Color(0xFF3E2723),
                  fontWeight: FontWeight.w900,
                  fontSize: 11.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── 2. Period Filter Selector ────────────────────────────────────────────
  Widget _buildPeriodSelector() {
    const periods = [
      ('today', 'Today'),
      ('week', 'This Week'),
      ('month', 'This Month'),
      ('all', 'All Time'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Container(
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
            final isSelected = _vm.selectedPeriod == p.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () => _vm.setPeriod(p.$1),
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
      ),
    );
  }

  // ─── 3. 3 High-Impact Executive Performance KPI Cards ──────────────────────
  Widget _buildDepthSummaryCards({
    required int schedCount,
    required int doneCount,
    required int bookedCount,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Row(
        children: [
          _buildDepthCard(
            title: 'Visit Sched',
            value: '$schedCount',
            subtitle: 'Site Visits Planned',
            icon: Icons.calendar_month_rounded,
            color: const Color(0xFFD97706),
            bg: const Color(0xFFFFFBEB),
            borderColor: const Color(0xFFFDE68A),
          ),
          const SizedBox(width: 8),
          _buildDepthCard(
            title: 'Visit Done',
            value: '$doneCount',
            subtitle: 'Visits Completed',
            icon: Icons.directions_car_rounded,
            color: const Color(0xFF0D9488),
            bg: const Color(0xFFF0FDFA),
            borderColor: const Color(0xFF99F6E4),
          ),
          const SizedBox(width: 8),
          _buildDepthCard(
            title: 'Bookings',
            value: '$bookedCount',
            subtitle: 'Deals Closed',
            icon: Icons.celebration_rounded,
            color: const Color(0xFFB45309),
            bg: const Color(0xFFFFF8E1),
            borderColor: const Color(0xFFFCD34D),
          ),
        ],
      ),
    );
  }

  Widget _buildDepthCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bg,
    required Color borderColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
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

  // ─── 4. Team Visits & Bookings Comparative Graph ──────────────────────────
  Widget _buildVisitsBookingsBarChart(List<TelecallerOverview> list) {
    final topAssociates = list.take(6).toList();

    double maxVal = 5.0;
    for (final a in topAssociates) {
      if (a.visitScheduledLeads > maxVal) maxVal = a.visitScheduledLeads.toDouble();
      if (a.visitDoneLeads > maxVal) maxVal = a.visitDoneLeads.toDouble();
      if (a.bookedLeads > maxVal) maxVal = a.bookedLeads.toDouble();
    }
    maxVal = (maxVal + 2).ceilToDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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
                        '📊 Visits & Deals Comparison',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Site Visits Sched vs Done vs Bookings',
                        style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
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
                  ),
                  child: Text(
                    '${topAssociates.length} Agents',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Legend Row
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _buildGraphLegend('Visit Sched', const Color(0xFFD97706)),
                _buildGraphLegend('Visit Done', const Color(0xFF0D9488)),
                _buildGraphLegend('Booked Deal', const Color(0xFFB45309)),
              ],
            ),

            const SizedBox(height: 16),

            // FlChart Grouped Bar Chart
            SizedBox(
              height: 140,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxVal,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final agent = topAssociates[groupIndex];
                        final type = rodIndex == 0 ? 'Visit Sched' : (rodIndex == 1 ? 'Visit Done' : 'Booked');
                        return BarTooltipItem(
                          '${agent.name.split(" ").first}\n$type: ${rod.toY.toInt()}',
                          const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
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
                        reservedSize: 20,
                        getTitlesWidget: (val, meta) {
                          if (val == 0 || val == maxVal || val == (maxVal / 2).roundToDouble()) {
                            return Text(
                              '${val.toInt()}',
                              style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < topAssociates.length) {
                            final name = topAssociates[idx].name.trim().split(' ').first;
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                name,
                                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxVal / 3).clamp(1.0, 50.0),
                    getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(topAssociates.length, (idx) {
                    final a = topAssociates[idx];
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: a.visitScheduledLeads.toDouble(),
                          color: const Color(0xFFD97706),
                          width: 7,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        BarChartRodData(
                          toY: a.visitDoneLeads.toDouble(),
                          color: const Color(0xFF0D9488),
                          width: 7,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        BarChartRodData(
                          toY: a.bookedLeads.toDouble(),
                          color: const Color(0xFFB45309),
                          width: 7,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
        ),
      ],
    );
  }

  // ─── 5. Search Bar ────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: _vm.setSearchQuery,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Search associates, SSR ID...',
            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                    onPressed: () {
                      _searchCtrl.clear();
                      _vm.setSearchQuery('');
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  // ─── 6. Associates Header ─────────────────────────────────────────────────
  Widget _buildTelecallersHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '👥 Associates Performance ($count)',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Tap for Customer breakdown',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.ssGoldDark,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 7. Ranked Associates Performance List ────────────────────────────────
  Widget _buildTelecallersList(List<TelecallerOverview> telecallers) {
    if (_vm.isLoading && telecallers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.ssGoldDark),
      );
    }

    if (telecallers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline_rounded, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 10),
            Text(
              _vm.searchQuery.isNotEmpty ? 'No associates match "${_vm.searchQuery}"' : 'No associates found',
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    // Sort ranked by bookings (desc), then visits done (desc), then visits scheduled
    final rankedList = List<TelecallerOverview>.from(telecallers);
    rankedList.sort((a, b) {
      if (b.bookedLeads != a.bookedLeads) return b.bookedLeads.compareTo(a.bookedLeads);
      if (b.visitDoneLeads != a.visitDoneLeads) return b.visitDoneLeads.compareTo(a.visitDoneLeads);
      return b.visitScheduledLeads.compareTo(a.visitScheduledLeads);
    });

    return RefreshIndicator(
      onRefresh: () => _vm.loadData(),
      color: AppColors.ssGoldDark,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 90),
        itemCount: rankedList.length,
        itemBuilder: (context, idx) {
          final agent = rankedList[idx];
          return _buildAgentPerformanceCard(agent, idx);
        },
      ),
    );
  }

  Widget _buildAgentPerformanceCard(TelecallerOverview agent, int rankIndex) {
    final initials = agent.name.trim().isNotEmpty
        ? agent.name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : 'AG';

    final isTop3 = rankIndex < 3;
    final rankBadgeColor = rankIndex == 0
        ? const Color(0xFFF59E0B) // Gold
        : (rankIndex == 1
            ? const Color(0xFF94A3B8) // Silver
            : (rankIndex == 2 ? const Color(0xFFB45309) : const Color(0xFF64748B)));

    final connRate = agent.totalCalls > 0
        ? ((agent.connectedCalls / agent.totalCalls) * 100).toStringAsFixed(0)
        : '0';

    return GestureDetector(
      onTap: () {
        AgentPerformanceDrilldownSheet.show(context, agent, _vm);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isTop3 ? rankBadgeColor.withAlpha(80) : const Color(0xFFE2E8F0),
            width: isTop3 ? 1.2 : 1,
          ),
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
            // Row 1: Rank Badge + Avatar + Name + SSR ID + Online Status
            Row(
              children: [
                // Rank Circle
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isTop3 ? rankBadgeColor.withAlpha(30) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(color: rankBadgeColor.withAlpha(100)),
                  ),
                  child: Center(
                    child: Text(
                      '${rankIndex + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: rankBadgeColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Avatar
                Stack(
                  children: [
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
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: agent.isOnline ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
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
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
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
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              agent.employeeId,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        agent.isOnline
                            ? (agent.firstPunchIn != null ? 'Online • Shift: ${agent.firstPunchIn}' : 'Online Now')
                            : (agent.firstPunchIn != null ? 'Shift: ${agent.firstPunchIn}' : 'Offline'),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: agent.isOnline ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow indicator
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
              ],
            ),

            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),

            // Row 2: 3 Depth Metrics Chips (Visit Sched, Visit Done, Bookings)
            Row(
              children: [
                _buildAgentMetricChip('📅 Visit Sched', '${agent.visitScheduledLeads}', const Color(0xFFD97706), const Color(0xFFFFFBEB)),
                const SizedBox(width: 6),
                _buildAgentMetricChip('🚗 Visit Done', '${agent.visitDoneLeads}', const Color(0xFF0D9488), const Color(0xFFF0FDFA)),
                const SizedBox(width: 6),
                _buildAgentMetricChip('🏆 Bookings', '${agent.bookedLeads}', const Color(0xFFB45309), const Color(0xFFFFF8E1)),
              ],
            ),

            const SizedBox(height: 8),

            // Row 3: Activity Summary Footer Strip
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
                      const Icon(Icons.phone_in_talk_rounded, size: 13, color: Color(0xFF2563EB)),
                      const SizedBox(width: 4),
                      Text(
                        '${agent.totalCalls} Calls (${agent.connectedCalls} Conn • $connRate%)',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                  const Row(
                    children: [
                      Icon(Icons.touch_app_rounded, size: 13, color: AppColors.ssGoldDark),
                      SizedBox(width: 3),
                      Text(
                        'Customer List ›',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.ssGoldDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentMetricChip(String label, String value, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color.withAlpha(220),
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
}
