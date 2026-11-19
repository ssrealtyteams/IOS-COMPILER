import 'package:flutter/material.dart';
import 'package:sales_crm_dialer/data/models/admin_models.dart';
import 'package:sales_crm_dialer/ui/features/admin/view_models/admin_view_model.dart';
import 'package:sales_crm_dialer/ui/features/admin/views/widgets/agent_live_tracking_sheet.dart';
import 'package:sales_crm_dialer/ui/features/admin/views/widgets/agent_drilldown_sheet.dart';

class AgentRadarCard extends StatelessWidget {
  final AgentRadarLocation radar;
  final int index;
  final AdminViewModel? viewModel;
  final VoidCallback? onViewDrilldown;

  const AgentRadarCard({
    super.key,
    required this.radar,
    required this.index,
    this.viewModel,
    this.onViewDrilldown,
  });

  void _openLiveTracking(BuildContext context) {
    final telecaller = TelecallerOverview(
      id: radar.id,
      name: radar.name,
      employeeId: radar.employeeId,
      email: '${radar.name.toLowerCase().replaceAll(' ', '')}@ssrealty.org',
      phone: radar.phone,
      isOnline: radar.isPunchedIn,
      firstPunchIn: radar.punchInTime,
    );

    if (viewModel != null) {
      AgentLiveTrackingSheet.show(context, telecaller, viewModel!, radarLocation: radar);
    } else {
      AgentDrilldownSheet.show(context, telecaller, AdminViewModel(), initialTabIndex: 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOffice = radar.status.toLowerCase() == 'inoffice' || radar.isInOffice;
    final isField = radar.status.toLowerCase().contains('field') || radar.status.toLowerCase() == 'onfieldvisit';
    final isOnDuty = isOffice || isField || radar.isPunchedIn;

    final dutyText = isOffice
        ? 'IN OFFICE'
        : (isField || radar.isPunchedIn ? 'ON FIELD' : 'OFF DUTY');

    final dutyBg = isOffice
        ? const Color(0xFFDCFCE7)
        : (isOnDuty ? const Color(0xFFE0F2FE) : const Color(0xFFFEF3C7));

    final dutyBorder = isOffice
        ? const Color(0xFF86EFAC)
        : (isOnDuty ? const Color(0xFFBAE6FD) : const Color(0xFFFDE68A));

    final dutyColor = isOffice
        ? const Color(0xFF15803D)
        : (isOnDuty ? const Color(0xFF0369A1) : const Color(0xFF92400E));

    final dutyIcon = isOffice
        ? Icons.business_rounded
        : (isOnDuty ? Icons.directions_car_rounded : Icons.nights_stay_rounded);

    final initial = radar.name.isNotEmpty ? radar.name[0].toUpperCase() : 'A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _openLiveTracking(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Left Avatar Circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: dutyBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: dutyBorder),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: dutyColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // 2. Middle Main Info Body
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Name & Status Badges
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            radar.name,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),

                          // Duty Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: dutyBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: dutyBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  dutyIcon,
                                  size: 11,
                                  color: dutyColor,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  dutyText,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: dutyColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Geofence / Distance Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isOffice ? const Color(0xFFCCFBF1) : const Color(0xFFFEF9C3),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isOffice ? const Color(0xFF99F6E4) : const Color(0xFFFEF08A),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOffice ? Icons.near_me_rounded : Icons.navigation_rounded,
                                  size: 11,
                                  color: isOffice ? const Color(0xFF0F766E) : const Color(0xFF854D0E),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  isOffice ? 'In Office (${radar.distanceFormatted})' : '${radar.distanceFormatted} away',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: isOffice ? const Color(0xFF0F766E) : const Color(0xFF854D0E),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Punch In / Not Punched Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: radar.isPunchedIn ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: radar.isPunchedIn ? const Color(0xFF86EFAC) : const Color(0xFFFECDD3),
                              ),
                            ),
                            child: Text(
                              radar.isPunchedIn ? (radar.punchInTime != null && radar.punchInTime!.isNotEmpty ? 'Punched In (${radar.punchInTime})' : 'Punched In') : 'Not Punched In',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: radar.isPunchedIn ? const Color(0xFF166534) : const Color(0xFF9F1239),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Row 2: Location Geofence & Metrics
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFEC4899)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              radar.geofenceLocation,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF334155),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Screen Time
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF64748B)),
                              const SizedBox(width: 3),
                              Text(
                                'App: ${radar.screenTimeText}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),

                          // Battery Badge
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.battery_std_rounded, size: 13, color: Color(0xFF16A34A)),
                              const SizedBox(width: 2),
                              Text(
                                '${radar.batteryPercent ?? 100}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Row 3: Address & ETA
                      Row(
                        children: [
                          const Icon(Icons.pin_drop_outlined, size: 13, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              radar.address,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ETA: ${radar.estimatedTravelTime}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // 3. Right Column: Last Signal & In-App View Route Button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'LAST SIGNAL',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      radar.lastSignalFormatted ?? (isOnDuty ? 'Just now' : 'Off-Duty'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () => _openLiveTracking(context),
                      icon: const Icon(Icons.visibility_outlined, size: 12),
                      label: const Text(
                        'View Route',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF334155),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
