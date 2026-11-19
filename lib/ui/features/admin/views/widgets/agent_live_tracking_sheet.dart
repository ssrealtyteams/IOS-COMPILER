import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sales_crm_dialer/core/theme/app_colors.dart';
import 'package:sales_crm_dialer/core/theme/app_typography.dart';
import 'package:sales_crm_dialer/data/models/admin_models.dart';
import 'package:sales_crm_dialer/ui/features/admin/view_models/admin_view_model.dart';
import 'package:sales_crm_dialer/ui/features/admin/views/widgets/agent_interactive_map_view.dart';

class AgentLiveTrackingSheet extends StatefulWidget {
  final TelecallerOverview agent;
  final AdminViewModel viewModel;
  final AgentRadarLocation? radarLocation;

  const AgentLiveTrackingSheet({
    super.key,
    required this.agent,
    required this.viewModel,
    this.radarLocation,
  });

  static void show(
    BuildContext context,
    TelecallerOverview agent,
    AdminViewModel viewModel, {
    AgentRadarLocation? radarLocation,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AgentLiveTrackingSheet(
        agent: agent,
        viewModel: viewModel,
        radarLocation: radarLocation,
      ),
    );
  }

  @override
  State<AgentLiveTrackingSheet> createState() => _AgentLiveTrackingSheetState();
}

class _AgentLiveTrackingSheetState extends State<AgentLiveTrackingSheet> {
  AgentGpsRouteHistory? _routeHistory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    setState(() => _isLoading = true);
    final route = await widget.viewModel.fetchAgentRouteHistory(
      widget.agent.id,
      agentName: widget.agent.name,
      employeeId: widget.agent.employeeId,
    );
    if (mounted) {
      setState(() {
        _routeHistory = route;
        _isLoading = false;
      });
    }
  }

  void _callAgent(String phone) async {
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

          // Header: Agent Info, Live Status & Controls
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(
              children: [
                // Avatar
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
                                  ? (agent.firstPunchIn != null ? 'Active • Shift: ${agent.firstPunchIn}' : 'Active on Field')
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
                      onTap: () => _callAgent(agent.phone),
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

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Main Body
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.ssGoldDark),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
                    children: [
                      // 1. Interactive Real Google Maps Component (Large Viewport)
                      if (_routeHistory != null)
                        AgentInteractiveMapView(
                          route: _routeHistory!,
                          height: 420,
                          showControls: true,
                        ),

                      const SizedBox(height: 14),

                      // 2. Real-Time Telemetry Summary Strip
                      if (_routeHistory != null)
                        _buildTelemetryKPIs(_routeHistory!),

                      const SizedBox(height: 16),

                      // 3. Movement Timeline & Punch-In Trail Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.timeline_rounded, size: 18, color: AppColors.ssGoldDark),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'GPS Movement & Punch Trail',
                                    style: AppTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_routeHistory?.waypoints.length ?? 0} Route Points',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // 4. Step-by-Step Waypoints Timeline
                      if (_routeHistory != null && _routeHistory!.waypoints.isNotEmpty)
                        ...List.generate(_routeHistory!.waypoints.length, (idx) {
                          final wp = _routeHistory!.waypoints[idx];
                          final isFirst = idx == 0;
                          final isLast = idx == _routeHistory!.waypoints.length - 1;
                          return _buildTimelineItem(wp, idx + 1, isFirst, isLast);
                        })
                      else
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Center(
                            child: Text(
                              'No location pings recorded for this shift yet.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryKPIs(AgentGpsRouteHistory route) {
    final stoppages = route.waypoints.where((w) => w.stayDurationMinutes > 5).length;
    final shiftDuration = widget.radarLocation?.screenTimeText ??
        (widget.agent.screenTimeMinutes > 0 ? '${widget.agent.screenTimeMinutes} min' : '0 min');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
      child: Row(
        children: [
          _buildKpiCell(
            'TOTAL DISTANCE',
            '${route.totalDistanceTravelledKm.toStringAsFixed(2)} km',
            const Color(0xFF2563EB),
            Icons.route_rounded,
          ),
          _buildKpiDivider(),
          _buildKpiCell(
            'SHIFT DURATION',
            shiftDuration,
            const Color(0xFFD97706),
            Icons.timer_outlined,
          ),
          _buildKpiDivider(),
          _buildKpiCell(
            'GPS WAYPOINTS',
            '${route.waypoints.length} points',
            const Color(0xFF0D9488),
            Icons.near_me_rounded,
          ),
          _buildKpiDivider(),
          _buildKpiCell(
            'STOPPAGES (RUKA)',
            '$stoppages stops',
            const Color(0xFFDC2626),
            Icons.front_hand_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCell(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiDivider() {
    return Container(
      height: 24,
      width: 1,
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildTimelineItem(AgentGpsWaypoint wp, int index, bool isFirst, bool isLast) {
    Color dotColor = const Color(0xFFD97706);
    if (isFirst) dotColor = const Color(0xFF16A34A);
    if (wp.isHalt) dotColor = const Color(0xFFEA580C);
    if (isLast) dotColor = const Color(0xFFDC2626);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Line & Dot Indicator
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withAlpha(80),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isFirst
                        ? const Icon(Icons.check, size: 8, color: Colors.white)
                        : Text(
                            '$index',
                            style: const TextStyle(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Right Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: wp.isHalt
                      ? const Color(0xFFFDBA74)
                      : isLast
                          ? const Color(0xFFFECDD3)
                          : const Color(0xFFE2E8F0),
                  width: wp.isHalt ? 1.4 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isFirst
                              ? const Color(0xFFDCFCE7)
                              : wp.isHalt
                                  ? const Color(0xFFFFF7ED)
                                  : isLast
                                      ? const Color(0xFFFFE4E6)
                                      : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          wp.isHalt ? '⏳ HALT / STOP' : wp.activityTag,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: isFirst
                                ? const Color(0xFF15803D)
                                : wp.isHalt
                                    ? const Color(0xFFC2410C)
                                    : isLast
                                        ? const Color(0xFF9F1239)
                                        : const Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                      Text(
                        wp.timeFormatted,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  if (wp.isHalt) ...[
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.pause_circle_filled_rounded, size: 12, color: Color(0xFFD97706)),
                          const SizedBox(width: 4),
                          Text(
                            'Stay Duration: ${wp.stayDurationFormatted} (${wp.haltIntervalFormatted})',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    wp.address,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '${(wp.distanceFromOfficeMeters / 1000).toStringAsFixed(2)} km from Jonapur Base',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                      ),
                      if (wp.speedKmh > 0) ...[
                        const Text(' • ', style: TextStyle(color: Color(0xFF94A3B8))),
                        Text(
                          'Speed: ${wp.speedKmh.toStringAsFixed(0)} km/h',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
