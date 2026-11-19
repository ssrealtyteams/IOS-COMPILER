import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sales_crm_dialer/core/theme/app_colors.dart';
import 'package:sales_crm_dialer/data/models/admin_models.dart';
import 'package:sales_crm_dialer/ui/features/admin/view_models/admin_view_model.dart';
import 'package:sales_crm_dialer/ui/features/admin/views/widgets/agent_radar_card.dart';
import 'package:sales_crm_dialer/ui/features/admin/views/widgets/agent_interactive_map_view.dart';
import 'package:sales_crm_dialer/ui/features/admin/views/widgets/agent_live_tracking_sheet.dart';

class AdminRadarView extends StatefulWidget {
  final AdminViewModel adminViewModel;

  const AdminRadarView({
    super.key,
    required this.adminViewModel,
  });

  @override
  State<AdminRadarView> createState() => _AdminRadarViewState();
}

class _AdminRadarViewState extends State<AdminRadarView> {
  final TextEditingController _searchCtrl = TextEditingController();
  int _viewMode = 0; // 0: Feed List View, 1: Interactive Multi-Agent Map View

  AdminViewModel get _vm => widget.adminViewModel;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AgentRadarLocation> get _filteredLocations {
    final all = _vm.radarLocations;
    if (_searchCtrl.text.isEmpty) return all;
    final q = _searchCtrl.text.toLowerCase();
    return all.where((r) {
      return r.name.toLowerCase().contains(q) ||
          r.employeeId.toLowerCase().contains(q) ||
          r.address.toLowerCase().contains(q) ||
          r.geofenceLocation.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          '🗺️ Field GPS Radar',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17.5),
        ),
        backgroundColor: const Color(0xFF5C3D0E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh live GPS telemetry',
            onPressed: () => _vm.loadData(),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final list = _filteredLocations;

          int inOfficeCount = 0;
          int onFieldCount = 0;
          int offDutyCount = 0;

          for (final r in list) {
            final st = r.status.toLowerCase();
            if (st == 'inoffice' || r.isInOffice) {
              inOfficeCount++;
            } else if (st.contains('field') || st == 'onfieldvisit' || st == 'active' || r.isPunchedIn) {
              onFieldCount++;
            } else {
              offDutyCount++;
            }
          }

          return Column(
            children: [
              // Top View Mode Switcher Strip
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _buildModeToggle(0, '📋 Live Intel Feed', Icons.view_list_rounded),
                      _buildModeToggle(1, '🗺️ Interactive Full Map', Icons.map_rounded),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Main Body depending on mode
              Expanded(
                child: _viewMode == 0
                    ? _buildFeedListView(list, inOfficeCount, onFieldCount, offDutyCount)
                    : _buildInteractiveFullMapView(list),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModeToggle(int mode, String label, IconData icon) {
    final isSelected = _viewMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _viewMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? AppColors.ssGoldDark : const Color(0xFF64748B),
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? AppColors.ssGoldDark : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Mode 0: Feed List View ───────────────────────────────────────────────
  Widget _buildFeedListView(
    List<AgentRadarLocation> list,
    int inOfficeCount,
    int onFieldCount,
    int offDutyCount,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 80),
      children: [
        // 1. Top 4 Status Summary Cards (Matching Web Tracking Portal)
        _buildTopSummaryCards(
          inOfficeCount: inOfficeCount,
          onFieldCount: onFieldCount,
          offDutyCount: offDutyCount,
        ),

        const SizedBox(height: 14),

        // 2. Search Box
        _buildSearchBar(),

        const SizedBox(height: 12),

        // 3. Live Field Intel Feed Header
        _buildFeedHeader(list.length),

        const SizedBox(height: 10),

        // 4. Live Field Intel Feed Items
        if (list.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Text(
                'No associates found matching search query.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ),
          )
        else
          ...List.generate(list.length, (idx) {
            final item = list[idx];
            return AgentRadarCard(
              radar: item,
              index: idx,
              viewModel: _vm,
            );
          }),
      ],
    );
  }

  // ─── Mode 1: Interactive Multi-Agent Full Map View ────────────────────────
  Widget _buildInteractiveFullMapView(List<AgentRadarLocation> list) {
    // Generate master route referencing Jonapur base with all agents
    const masterRoute = AgentGpsRouteHistory(
      agentId: 'all',
      agentName: 'All Field Associates',
      employeeId: 'SSR-ALL',
      phone: '',
      status: 'active',
      currentAddress: 'Jonapur Dalmia Farm Hub',
      distanceFromOfficeMeters: 0.0,
      officeLat: 28.4624272,
      officeLng: 77.1515298,
      waypoints: [],
    );

    return Stack(
      children: [
        // 1. Full Screen Vector Canvas Map
        AgentInteractiveMapView(
          route: masterRoute,
          height: double.infinity,
          showControls: true,
          isMultiAgent: true,
          allAgents: list,
          onAgentSelected: (agent) {
            final telecaller = TelecallerOverview(
              id: agent.id,
              name: agent.name,
              employeeId: agent.employeeId,
              email: '${agent.name.toLowerCase().replaceAll(' ', '')}@ssrealty.org',
              phone: agent.phone,
              isOnline: agent.isPunchedIn,
              firstPunchIn: agent.punchInTime,
            );
            AgentLiveTrackingSheet.show(context, telecaller, _vm, radarLocation: agent);
          },
        ),

        // 2. Bottom Floating Agents Quick Carousel
        Positioned(
          left: 10,
          right: 10,
          bottom: 14,
          child: Container(
            height: 90,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final agent = list[idx];
                final isOffice = agent.status.toLowerCase() == 'inoffice' || agent.isInOffice;

                return GestureDetector(
                  onTap: () {
                    final telecaller = TelecallerOverview(
                      id: agent.id,
                      name: agent.name,
                      employeeId: agent.employeeId,
                      email: '${agent.name.toLowerCase().replaceAll(' ', '')}@ssrealty.org',
                      phone: agent.phone,
                      isOnline: agent.isPunchedIn,
                      firstPunchIn: agent.punchInTime,
                    );
                    AgentLiveTrackingSheet.show(context, telecaller, _vm, radarLocation: agent);
                  },
                  child: Container(
                    width: 170,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isOffice ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isOffice ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                agent.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isOffice ? 'In Office (Base)' : '${agent.distanceFormatted} away',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isOffice ? const Color(0xFF15803D) : const Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ETA: ${agent.estimatedTravelTime}',
                              style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.ssGoldDark),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ─── Top 4 Summary Cards ──────────────────────────────────────────────────
  Widget _buildTopSummaryCards({
    required int inOfficeCount,
    required int onFieldCount,
    required int offDutyCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 650;
        final cardWidth = isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildSummaryCard(
              width: cardWidth,
              title: 'BASE GEOFENCE',
              value: 'Dalmia farm',
              subtitle: '28.4624, 77.1515 • 200m',
              icon: Icons.account_balance_rounded,
              iconBg: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFD97706),
              cardBg: Colors.white,
              borderColor: const Color(0xFFE2E8F0),
            ),
            _buildSummaryCard(
              width: cardWidth,
              title: 'IN OFFICE (PRESENT)',
              value: '$inOfficeCount',
              subtitle: 'At Jonapur Farm',
              icon: Icons.check_circle_outline_rounded,
              iconBg: const Color(0xFFDCFCE7),
              iconColor: const Color(0xFF16A34A),
              cardBg: const Color(0xFFF0FDF4),
              borderColor: const Color(0xFF86EFAC),
            ),
            _buildSummaryCard(
              width: cardWidth,
              title: 'ON FIELD VISIT',
              value: '$onFieldCount',
              subtitle: 'Live GPS (10 AM - 7 PM)',
              icon: Icons.directions_car_rounded,
              iconBg: const Color(0xFFDBEAFE),
              iconColor: const Color(0xFF2563EB),
              cardBg: const Color(0xFFEFF6FF),
              borderColor: const Color(0xFFBFDBFE),
            ),
            _buildSummaryCard(
              width: cardWidth,
              title: 'OFF DUTY',
              value: '$offDutyCount',
              subtitle: 'Outside Shift Hours',
              icon: Icons.access_time_rounded,
              iconBg: const Color(0xFFF1F5F9),
              iconColor: const Color(0xFF64748B),
              cardBg: const Color(0xFFF8FAFC),
              borderColor: const Color(0xFFE2E8F0),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required double width,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color cardBg,
    required Color borderColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
        ],
      ),
    );
  }

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
          hintText: 'Search associates, SSR ID, or location...',
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

  Widget _buildFeedHeader(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD97706),
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .fade(duration: 700.ms)
                    .then()
                    .fade(duration: 700.ms, begin: 1.0, end: 0.2),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Live Field Intel Feed',
                    style: TextStyle(
                      fontSize: 13.5,
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
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Text(
              '$count Team Members',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
