import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../view_models/dashboard_view_model.dart';
import 'widgets/booking_details_sheet.dart';
import '../../../../core/services/location_tracking_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.viewModel,
    required this.onLeadsTap,
    required this.onDialpadTap,
    required this.onFollowupsTap,
    required this.onReportsTap,
  });

  final DashboardViewModel viewModel;
  final VoidCallback onLeadsTap;
  final VoidCallback onDialpadTap;
  final VoidCallback onFollowupsTap;
  final VoidCallback onReportsTap;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  DashboardViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _vm.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Lifecycle state observer
  }

  Future<void> _handlePunchOut() async {
    final shouldPunchOut = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.pause_circle_outline_rounded, color: Color(0xFFE65100), size: 24),
            SizedBox(width: 8),
            Text('Punch Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to punch out / pause your shift? You will need to punch in again from the Punch In screen to access the CRM dashboard.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Punch Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldPunchOut == true && mounted) {
      _vm.punchOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _vm,
        builder: (_, __) {
          if (_vm.attendanceError != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _vm.attendanceError != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_vm.attendanceError!),
                    backgroundColor: AppColors.error,
                  ),
                );
                _vm.clearAttendanceError();
              }
            });
          }

          return RefreshIndicator(
            onRefresh: _vm.loadStats,
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildFieldTrackingBanner(),
                      _buildPeriodSelector(),
                      _buildStatsGrid(),
                      _buildCallsChart(),
                      _buildLeaderboard(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 170,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF8B6914),
      titleSpacing: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(
          start: 16,
          bottom: 14,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _greeting(),
              style: TextStyle(
                color: Colors.white.withAlpha(200),
                fontSize: 10,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              _vm.agentName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        background: _buildHeaderBackground(),
      ),
      actions: [
        if (_vm.isPunchedIn)
          TextButton.icon(
            onPressed: _handlePunchOut,
            icon: const Icon(Icons.pause_circle_filled_rounded, color: Colors.white, size: 16),
            label: const Text('Punch Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withAlpha(35),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
          onPressed: () {
            context.push('/profile');
          },
        ),
      ],
    );
  }

  Widget _buildHeaderBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base gradient (dark brown to gold)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF5C3D0E),
                Color(0xFF8B6914),
                Color(0xFFC9A227),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Decorative circles (pattern)
        Positioned(
          top: -30,
          right: -20,
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(20), width: 2),
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 50,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(15), width: 1.5),
            ),
          ),
        ),
        Positioned(
          bottom: -20,
          left: -10,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(12), width: 1.5),
            ),
          ),
        ),
        Positioned(
          top: 30,
          left: 120,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 60,
          right: 100,
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(35),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Diagonal shimmer line
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: CustomPaint(
            painter: _DiagonalLinePainter(),
          ),
        ),
        // Content: only Agent ID badge on right (name + greeting handled by FlexibleSpaceBar.title)
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Agent ID Badge (only visible in expanded state, fades on collapse)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(30),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFEDD98A).withAlpha(100),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEDD98A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _vm.agentId,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEDD98A),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldTrackingBanner() {
    return ValueListenableBuilder<AgentTrackingStatus>(
      valueListenable: LocationTrackingService.instance.statusNotifier,
      builder: (context, status, _) {
        Color bgColor;
        Color textColor;
        IconData icon;
        String statusText;
        String subText;

        switch (status) {
          case AgentTrackingStatus.inOffice:
            bgColor = const Color(0xFFE8F5E9);
            textColor = const Color(0xFF2E7D32);
            icon = Icons.business_rounded;
            statusText = 'In Office (Jonapur Farm)';
            subText = 'Office Geofence Active • Auto Punch-In';
            break;
          case AgentTrackingStatus.onFieldVisit:
            bgColor = const Color(0xFFE3F2FD);
            textColor = const Color(0xFF1565C0);
            icon = Icons.directions_car_rounded;
            statusText = 'On Field / Site Visit';
            subText = 'Live GPS Tracking Active (10:00 AM - 07:00 PM)';
            break;
          case AgentTrackingStatus.offDuty:
            bgColor = const Color(0xFFF5F5F5);
            textColor = const Color(0xFF757575);
            icon = Icons.nightlight_round;
            statusText = 'Shift Inactive (Off Duty)';
            subText = 'Tracking resumes at 10:00 AM working shift';
            break;
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: textColor.withValues(alpha: 0.25), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: textColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          statusText,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (status != AgentTrackingStatus.offDuty)
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: textColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subText,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms);
      },
    );
  }

  Widget _buildPeriodSelector() {
    final periods = [
      (DashboardPeriod.today, 'Today'),
      (DashboardPeriod.week, 'This Week'),
      (DashboardPeriod.month, 'This Month'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: periods.map((p) {
          final isSelected = _vm.period == p.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => _vm.setPeriod(p.$1),
              child: AnimatedContainer(
                duration: 200.ms,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: AppRadius.borderRadiusMd,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  p.$2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.textOnPrimary
                        : AppColors.textSecondary,
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

  Widget _buildStatsGrid() {
    final stats = _vm.stats;
    final cards = [
      _StatData('Total Calls', stats.totalCalls.toString(), Icons.phone_rounded,
          AppColors.primary, AppColors.primarySurface),
      _StatData('Unique Contacts', stats.uniqueCalls.toString(),
          Icons.contacts_rounded, AppColors.info, AppColors.infoSurface),
      _StatData('Manual Calls', stats.manualCalls.toString(),
          Icons.dialpad_rounded, AppColors.secondary, AppColors.secondarySurface),
      _StatData('Connected', stats.connectedCalls.toString(),
          Icons.call_made_rounded, AppColors.success, AppColors.successSurface),
      _StatData('Not Connected', stats.missedCalls.toString(),
          Icons.phone_missed_rounded, AppColors.error, AppColors.errorSurface),
      _StatData('Visit Scheduled', stats.scheduledVisits.toString(),
          Icons.calendar_month_rounded, const Color(0xFFE65100), const Color(0xFFFFF3E0)),
      _StatData('Visit Done', stats.completedVisits.toString(),
          Icons.event_available_rounded, const Color(0xFF00897B), const Color(0xFFE0F2F1)),
      _StatData(
        'Bookings',
        stats.conversions > 0
            ? '${stats.conversions}'
            : (stats.totalBookingAmount > 0
                ? _formatBookingAmount(stats.totalBookingAmount)
                : '0'),
        Icons.celebration_rounded,
        const Color(0xFFC9A227),
        const Color(0xFFFFF8E1),
        onTap: () {
          showBookingDetailsSheet(context, bookings: _vm.bookings);
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 6,
        mainAxisSpacing: 8,
        childAspectRatio: 0.82,
        children: cards.asMap().entries.map((entry) {
          return _StatCard(data: entry.value, index: entry.key);
        }).toList(),
      ),
    );
  }



  Widget _buildCallsChart() {
    final chartData = _vm.stats.callsChart;
    if (chartData.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Call Trends', style: AppTypography.titleSmall),
              Row(
                children: [
                  _LegendDot(color: AppColors.primary, label: 'Total'),
                  const SizedBox(width: 12),
                  _LegendDot(color: AppColors.success, label: 'Connected'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartData.map((e) => e.total.toDouble()).fold<double>(0.0, (a, b) => a > b ? a : b) > 0
                    ? (chartData.map((e) => e.total.toDouble()).fold<double>(0.0, (a, b) => a > b ? a : b) * 1.3).ceilToDouble()
                    : 10.0,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) => Text(
                        chartData[value.toInt()].date,
                        style: AppTypography.labelSmall,
                      ),
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.borderLight,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: chartData.asMap().entries.map((entry) {
                  final i = entry.key;
                  final d = entry.value;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: d.total.toDouble(),
                        color: AppColors.primary.withAlpha(180),
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: AppRadius.xs,
                        ),
                      ),
                      BarChartRodData(
                        toY: d.connected.toDouble(),
                        color: AppColors.success.withAlpha(180),
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: AppRadius.xs,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }



  Widget _buildLeaderboard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.ssGold.withAlpha(30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.ssGold.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.emoji_events_rounded, size: 18, color: AppColors.ssGoldDark),
                  ),
                  const SizedBox(width: 8),
                  Text('Leaderboard', style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  )),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'This Week',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.ssGoldDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_vm.leaderboard.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.ssGold.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.emoji_events_outlined, size: 32, color: AppColors.ssGoldDark),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No Bookings Recorded Yet',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rankings activate automatically as soon as a confirmed booking is updated. The agent with the highest booking value claims the #1 Top Rank!',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ..._vm.leaderboard.asMap().entries.map((entry) {
              return _LeaderboardRow(
                entry: entry.value,
                index: entry.key,
              );
            }),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  String _formatBookingAmount(double amount) {
    if (amount <= 0) return '₹ 0';
    if (amount >= 1.0) {
      final formatted = amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
      return '₹ $formatted Cr';
    } else if (amount >= 0.01) {
      final lakhs = (amount * 100).toStringAsFixed(0);
      return '₹ $lakhs Lakhs';
    } else {
      return '₹ ${amount.toStringAsFixed(0)}';
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️ Good morning,';
    if (hour < 17) return '🌤️ Good afternoon,';
    return '🌙 Good evening,';
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _StatData {
  const _StatData(this.label, this.value, this.icon, this.color, this.bg, {this.onTap});
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback? onTap;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data, required this.index});
  final _StatData data;
  final int index;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.borderRadiusMd,
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: data.bg,
                borderRadius: AppRadius.borderRadiusSm,
              ),
              child: Icon(data.icon, size: 14, color: data.color),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    data.value,
                    style: AppTypography.titleMedium.copyWith(
                      color: data.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.label,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 40))
        .fadeIn()
        .slideY(begin: 0.1);
  }
}



class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry, required this.index});
  final LeaderboardEntry entry;
  final int index;

  @override
  Widget build(BuildContext context) {
    final rankBgColors = [const Color(0xFFFFF8E1), const Color(0xFFF5F5F5), const Color(0xFFFBE9E7)];
    final rankIconColors = [const Color(0xFFC9A227), const Color(0xFF78909C), const Color(0xFFBF360C)];
    final rankIcons = [Icons.looks_one_rounded, Icons.looks_two_rounded, Icons.looks_3_rounded];
    final rowBg = index < 3 ? rankBgColors[index] : const Color(0xFFF9F7F2);
    final rankColor = index < 3 ? rankIconColors[index] : AppColors.textTertiary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: AppRadius.borderRadiusMd,
        border: Border.all(
          color: index == 0 ? AppColors.ssGold.withAlpha(60) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rankColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: index < 3
                  ? Icon(rankIcons[index], size: 16, color: rankColor)
                  : Text(
                      '#${entry.rank}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: rankColor,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.agentName,
              style: AppTypography.titleSmall.copyWith(
                color: const Color(0xFF3E2723),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.bookings} Bookings',
                style: AppTypography.labelSmall.copyWith(
                  color: const Color(0xFF5D4037),
                ),
              ),
              Text(
                entry.totalBookingAmount > 0
                    ? (entry.totalBookingAmount >= 1.0
                        ? '₹ ${entry.totalBookingAmount.toStringAsFixed(entry.totalBookingAmount.truncateToDouble() == entry.totalBookingAmount ? 0 : 2)} Cr'
                        : '₹ ${(entry.totalBookingAmount * 100).toStringAsFixed(0)} Lakhs')
                    : '₹ 0',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 100)).fadeIn().slideX(begin: 0.1);
  }
}

class _DiagonalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(10)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const spacing = 28.0;
    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
