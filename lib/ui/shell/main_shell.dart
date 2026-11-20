import '../../core/services/permission_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../features/dashboard/views/dashboard_screen.dart';
import '../features/dashboard/views/punch_in_screen.dart';
import '../features/dashboard/view_models/dashboard_view_model.dart';
import '../features/leads/views/lead_list_screen.dart';
import '../features/leads/views/new_leads_screen.dart';
import '../features/leads/view_models/lead_list_view_model.dart';
import '../features/calling/views/custom_dialpad_sheet.dart';
import '../features/calling/views/disposition_sheet.dart';
import '../features/calling/views/in_call_screen.dart';
import '../features/calling/view_models/call_view_model.dart';
import '../features/calling/view_models/disposition_view_model.dart';
import '../features/share/views/share_details_sheet.dart';
import '../features/admin/view_models/admin_view_model.dart';
import '../features/admin/views/admin_dashboard_screen.dart';
import '../features/admin/views/admin_radar_view.dart';
import '../features/admin/views/admin_automation_view.dart';
import '../features/admin/views/admin_attendance_view.dart';
import '../features/reports/views/analytics_report_screen.dart';
import '../../domain/entities/call.dart';
import '../../domain/entities/lead.dart';
import '../features/auth/data/sources/local/local_auth_source_impl.dart';
import '../../domain/entities/project.dart';
import '../../data/repositories/remote_lead_repository.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.dashboardViewModel,
    required this.callViewModel,
    required this.dispositionViewModel,
  });

  final DashboardViewModel dashboardViewModel;
  final CallViewModel callViewModel;
  final DispositionViewModel dispositionViewModel;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  late final _dashVm = widget.dashboardViewModel;
  final _leadVm = AppLeadListViewModel(isNewLeadsOnly: false);
  final _newLeadVm = AppLeadListViewModel(isNewLeadsOnly: true);
  final _adminVm = AdminViewModel();
  late final _dispositionVm = widget.dispositionViewModel;
  late final _callVm = widget.callViewModel;

  bool _isDispositionShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionService.checkAndPromptPermissions(context);
    });
    WidgetsBinding.instance.addObserver(this);
    _callVm.addListener(_onCallStateChange);
    _dashVm.init();
    RemoteLeadRepository.init().then((_) {
      _leadVm.init();
      _newLeadVm.init();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user returns to app after a call, auto-trigger disposition
    if (state == AppLifecycleState.resumed) {
      if (!_dashVm.isPunchedIn) {
        _dashVm.fetchAttendanceStatus();
      }
      _callVm.onAppResumed();
      PermissionService.hasAllEssentialPermissions().then((hasAll) {
        if (!hasAll && mounted) {
          PermissionService.checkAndPromptPermissions(context);
        }
      });
    }
  }

  void _onCallStateChange() {
    // Guard: only show disposition once per call
    if (_callVm.showDisposition && _callVm.lastCall != null && !_isDispositionShowing) {
      _isDispositionShowing = true;
      final activeLead = _callVm.activeLead;
      final call = _callVm.lastCall!;

      if (activeLead != null) {
        // Update existing lead's last activity
        final updatedLead = activeLead.copyWith(
          lastActivityAt: DateTime.now(),
        );
        // Persist to static repo so data survives tab switches
        RemoteLeadRepository.updateLeadInRepo(updatedLead);
        _leadVm.updateLead(updatedLead);
        _newLeadVm.updateLead(updatedLead);
      }

      _showDispositionSheet(call);
    }
  }


  void _showDispositionSheet(call) {
    _dispositionVm.reset();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: DispositionSheet(
          call: call,
          lead: _callVm.activeLead,
          viewModel: _dispositionVm,
          initialRemarks: _callVm.liveNotes.isNotEmpty ? _callVm.liveNotes : null,
          onDismiss: () {
            Navigator.pop(context);
            _isDispositionShowing = false;
            
            // Record call for Dashboard metrics using the saved disposition status
            if (_dispositionVm.selectedDisposition != null) {
              final activeLead = _callVm.activeLead;
              _dashVm.recordCall(
                phoneNumber: call.phoneNumber,
                isConnected: _dispositionVm.wasConnected ?? (call.durationSeconds > 0),
                isManual: activeLead == null || activeLead.fullName == 'Unknown Contact', // heuristic for manual
              );

              // If Booking Done, immediately update dashboard total bookings & revenue & leaderboard
              if (_dispositionVm.selectedDisposition == CallDisposition.closed) {
                _dashVm.recordBooking(
                  clientName: activeLead?.fullName ?? 'Client ${call.phoneNumber}',
                  phone: call.phoneNumber,
                  dealAmountDisplay: '₹ ${_dispositionVm.bookingDealAmount} ${_dispositionVm.bookingDealUnit}',
                  dealAmountInCr: _dispositionVm.bookingDealAmountInCr,
                  projectName: activeLead?.projectName ?? 'SS Realty Project',
                  unitType: activeLead?.unitType ?? 'Apartment',
                );
              }
            }

            _callVm.dismissDisposition();
            // Refresh both lists when a call finishes
            _leadVm.loadLeads(refresh: true);
            _newLeadVm.loadLeads(refresh: true);
          },
        ),
      ),
    );
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callVm.removeListener(_onCallStateChange);
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_dashVm, _callVm]),
      builder: (context, _) {
        final isExecutive = _dashVm.isExecutive || LocalAuthSourceImpl.isDirectorOrExecutive;

        if (!isExecutive && !_dashVm.isPunchedIn) {
          return PunchInScreen(viewModel: _dashVm);
        }

        final isFullCalling = _callVm.isCallActive && !_callVm.isMinimized;

        if (isFullCalling) {
          return Scaffold(
            backgroundColor: const Color(0xFF090D16),
            body: InCallScreen(callViewModel: _callVm),
          );
        }

        return Scaffold(
          body: Stack(
            children: [
              IndexedStack(
                index: _selectedIndex,
                children: isExecutive
                    ? [
                        AdminDashboardScreen(
                          viewModel: _adminVm,
                        ),
                        AdminRadarView(adminViewModel: _adminVm),
                        AdminAutomationView(adminViewModel: _adminVm),
                        AdminAttendanceView(adminViewModel: _adminVm),
                      ]
                    : [
                        DashboardScreen(
                          viewModel: _dashVm,
                          onLeadsTap: () => setState(() => _selectedIndex = 1),
                          onDialpadTap: () => setState(() => _selectedIndex = 2),
                          onFollowupsTap: () {},
                          onReportsTap: () => setState(() => _selectedIndex = 3),
                        ),
                        LeadListScreen(
                          viewModel: _leadVm,
                          onLeadTap: (lead) => _showLeadDetail(lead),
                          onCall: (lead) async {
                            await _callVm.initiateCall(lead: lead);
                            _newLeadVm.loadLeads(refresh: true);
                            _leadVm.loadLeads(refresh: true);
                          },
                          onWhatsApp: (lead) => _openWhatsApp(lead),
                          onShare: (lead) => _showShareSheet(lead),
                        ),
                        NewLeadsScreen(
                          viewModel: _newLeadVm,
                          onCall: (lead) async {
                            await _callVm.initiateCall(lead: lead);
                            _newLeadVm.loadLeads(refresh: true);
                            _leadVm.loadLeads(refresh: true);
                          },
                          onWhatsApp: (lead) => _openWhatsApp(lead),
                        ),
                        const AnalyticsReportScreen(showBackButton: false),
                      ],
              ),
              if (_callVm.isCallActive && _callVm.isMinimized)
                _buildActiveCallBanner(),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(),
          floatingActionButton: (_selectedIndex == 1 && !isExecutive)
              ? FloatingActionButton.extended(
                  onPressed: () => showCustomDialpadSheet(context, _callVm),
                  backgroundColor: AppColors.success,
                  icon: const Icon(Icons.dialpad_rounded),
                  label: const Text('Dialpad'),
                ).animate().scale(duration: 300.ms)
              : null,
        );
      },
    );
  }

  Widget _buildActiveCallBanner() {
    return ListenableBuilder(
      listenable: _callVm,
      builder: (context, _) {
        if (!_callVm.isCallActive) return const SizedBox.shrink();

        final leadName = _callVm.activeLead?.fullName ?? 'Direct Call';
        final phone = _callVm.activePhoneNumber ?? '';
        final isConnected = _callVm.state == CallViewState.connected;

        return Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          right: 12,
          child: GestureDetector(
            onTap: () => _callVm.toggleMinimized(),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isConnected ? const Color(0xFF22C55E) : const Color(0xFFEAB308),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(80),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Status Icon
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: (isConnected ? const Color(0xFF22C55E) : const Color(0xFFEAB308)).withAlpha(35),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isConnected ? Icons.phone_in_talk_rounded : Icons.phone_forwarded_rounded,
                        color: isConnected ? const Color(0xFF22C55E) : const Color(0xFFEAB308),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Name + Duration / Status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            leadName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isConnected
                                ? 'Connected • ${_formatCallDuration(_callVm.elapsedSeconds)}'
                                : 'Dialing $phone...',
                            style: TextStyle(
                              color: isConnected ? const Color(0xFF86EFAC) : const Color(0xFFFDE047),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Big Red "Cut Call" Button
                    ElevatedButton.icon(
                      onPressed: () => _callVm.hangUpCall(),
                      icon: const Icon(Icons.call_end_rounded, color: Colors.white, size: 16),
                      label: const Text(
                        'Cut Call',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().slideY(begin: -0.5, duration: 250.ms).fadeIn(),
        );
      },
    );
  }

  String _formatCallDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildBottomNav() {
    final isExecutive = _dashVm.isExecutive;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDF6E8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(
          top: BorderSide(
            color: AppColors.ssGold.withAlpha(80),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ssGold.withAlpha(30),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.only(bottom: 12, top: 12),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: isExecutive
              ? [
                  _buildNavItem(0, Icons.insights_outlined, Icons.insights_rounded, 'Performance'),
                  _buildNavItem(1, Icons.radar_outlined, Icons.radar_rounded, 'Field Radar'),
                  _buildNavItem(2, Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Analytics'),
                  _buildNavItem(3, Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Attendance'),
                ]
              : [
                  _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
                  _buildNavItem(1, Icons.people_outline_rounded, Icons.people_rounded, 'Leads'),
                  _buildNavItem(2, Icons.person_add_outlined, Icons.person_add_rounded, 'New Leads', isNewLeadsTab: true),
                  _buildNavItem(3, Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Reports'),
                ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData selectedIcon, String label, {bool isNewLeadsTab = false}) {
    final isSelected = _selectedIndex == index;
    final itemColor = isSelected ? AppColors.ssGoldDark : const Color(0xFF8B7355);
    
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => _selectedIndex = index);
        if (index == 1) {
          _leadVm.loadLeads(refresh: true);
        } else if (index == 2) {
          _newLeadVm.loadLeads(refresh: true);
        }
      },
      child: Container(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.ssGold.withAlpha(40) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSelected ? selectedIcon : icon,
                    color: itemColor,
                    size: 22,
                  ),
                ),
                if (isNewLeadsTab)
                  ListenableBuilder(
                    listenable: _newLeadVm,
                    builder: (context, _) {
                      if (_newLeadVm.leads.isEmpty) return const SizedBox();
                      return Positioned(
                        top: 2,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ).animate(onPlay: (c) => c.repeat()).fade(duration: 800.ms).then().fade(duration: 800.ms, begin: 1.0, end: 0.3),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: itemColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeadDetail(Lead lead) {
    // Navigate to lead detail
  }

  void _openWhatsApp(Lead lead) async {
    final phone = lead.phone.replaceAll(RegExp(r'[^\d+]'), '');
    final url = Uri.parse('whatsapp://send?phone=$phone');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch WhatsApp: $e');
    }
  }

  void _showShareSheet(Lead lead) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ShareDetailsSheet(
        lead: lead,
        projects: _demoprojects,
      ),
    );
  }

  static final _demoprojects = [
    const Project(
      id: 'p1',
      name: 'Orchid',
      location: 'Chattarpur / Delhi NCR',
      pricing: {'Status': 'Ready to Move', 'Price': 'On Request'},
      websiteUrl: 'https://ssrealty.org/properties',
    ),
    const Project(
      id: 'p2',
      name: 'Nivasa III',
      location: 'Chattarpur / Delhi NCR',
      pricing: {'Status': 'Ready to Move', 'Starting': '₹75 Lakhs'},
      websiteUrl: 'https://ssrealty.org/properties/nivasa-iii',
    ),
    const Project(
      id: 'p3',
      name: 'Amaryllis',
      location: 'Chattarpur / Delhi NCR',
      pricing: {'Status': 'Under Construction', 'Possession': 'Jan 2027'},
      websiteUrl: 'https://ssrealty.org/properties',
    ),
    const Project(
      id: 'p4',
      name: 'Vasundhara',
      location: 'Chattarpur / Delhi NCR',
      pricing: {'Status': 'Under Construction', 'Possession': 'May 2027'},
      websiteUrl: 'https://ssrealty.org/properties',
    ),
    const Project(
      id: 'p5',
      name: 'Velora',
      location: 'Chattarpur / Delhi NCR',
      pricing: {'Status': 'Under Construction', 'Possession': 'May 2027'},
      websiteUrl: 'https://ssrealty.org/properties',
    ),
    const Project(
      id: 'p6',
      name: 'The Arch',
      location: 'Chattarpur / Delhi NCR',
      pricing: {'Status': 'Under Construction', 'Possession': 'July 2027'},
      websiteUrl: 'https://ssrealty.org/properties',
    ),
  ];
}

// ─── Live LeadListViewModel connected to Next.js API ─────────────────────────
class AppLeadListViewModel extends LeadListViewModel {
  AppLeadListViewModel({required bool isNewLeadsOnly}) 
      : super(leadRepository: RemoteLeadRepository(isNewLeadsOnly: isNewLeadsOnly));

  @override
  Future<void> init() async {
    await super.init();
  }

  /// Call this when a manual dial lead needs to be added to the list
  Future<void> addManualCallLead(String phoneNumber) async {
    await RemoteLeadRepository.findOrCreateLead(phoneNumber);
    loadLeads(refresh: true);
  }
}
