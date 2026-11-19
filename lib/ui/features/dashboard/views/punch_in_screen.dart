import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../auth/data/sources/local/local_auth_source_impl.dart';
import '../view_models/dashboard_view_model.dart';

class PunchInScreen extends StatefulWidget {
  const PunchInScreen({
    super.key,
    required this.viewModel,
  });

  final DashboardViewModel viewModel;

  @override
  State<PunchInScreen> createState() => _PunchInScreenState();
}

class _PunchInScreenState extends State<PunchInScreen> {
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.viewModel.fetchAttendanceStatus();
      }
    });
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout Confirmation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Text(
          'Are you sure you want to log out? You will need your email and password to sign in again.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      setState(() => _isLoggingOut = true);
      try {
        await AppRouter.authVm.logout();
        await LocalAuthSourceImpl().clearSession();
      } catch (e) {
        debugPrint('Logout notice: $e');
      }

      if (mounted) {
        context.go(AppRoutes.login);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Color(0xFF8B6914),
          ),
        );
      }
    }
  }

  Future<void> _onBiometricPunchIn() async {
    final vm = widget.viewModel;
    if (vm.isPunchingIn) return;

    await vm.punchIn();
    if (mounted && vm.isPunchedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Shift Punched In Successfully! Welcome back.'),
          backgroundColor: Color(0xFF2E7D32),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;

    if (vm.isExecutive || LocalAuthSourceImpl.isDirectorOrExecutive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
      return const Scaffold(
        backgroundColor: Color(0xFFFDFBF7),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.ssGoldDark),
        ),
      );
    }

    final agentInitials = vm.agentName.trim().isNotEmpty
        ? vm.agentName.trim().split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
        : 'SS';

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Agent Header, Refresh & Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B6914), Color(0xFFC9A227)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFC9A227).withAlpha(60),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            agentInitials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vm.agentName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B6914).withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'ID: ${vm.agentId}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8B6914),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: vm.isSyncingStatus ? null : () => vm.fetchAttendanceStatus(),
                        icon: vm.isSyncingStatus
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF8B6914),
                                ),
                              )
                            : const Icon(Icons.refresh_rounded, size: 22, color: Color(0xFF8B6914)),
                        tooltip: 'Refresh policy',
                      ),
                      const SizedBox(width: 4),
                      OutlinedButton.icon(
                        onPressed: _isLoggingOut ? null : _handleLogout,
                        icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.error),
                        label: const Text('Logout', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.error.withAlpha(80)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFEAE2D5), height: 1),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFB74D)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pause_circle_outline_rounded, size: 16, color: Color(0xFFE65100)),
                          SizedBox(width: 6),
                          Text(
                            'Shift Paused / Punched Out',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Ready to Start Your Shift?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Touch the fingerprint sensor below to record your attendance and unlock the CRM.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Office & Location Details Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadius.borderRadiusLg,
                        border: Border.all(color: const Color(0xFFE8DFD1)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B6914).withAlpha(12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            icon: Icons.business_rounded,
                            iconColor: const Color(0xFF8B6914),
                            title: 'Office Location',
                            value: 'SS Realty Jonapur Office',
                            subtitle: 'Chattarpur / Delhi NCR',
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(color: Color(0xFFF0EAE1), height: 1),
                          ),
                          _buildDetailRow(
                            icon: Icons.access_time_filled_rounded,
                            iconColor: const Color(0xFF2E7D32),
                            title: 'Shift Hours',
                            value: '10:00 AM - 07:00 PM',
                            subtitle: '9 Hours Active Shift',
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(color: Color(0xFFF0EAE1), height: 1),
                          ),
                          _buildDetailRow(
                            icon: (vm.isGeofenceRequired && !vm.isAgentRemoteExempted)
                                ? Icons.location_on_rounded
                                : Icons.public_rounded,
                            iconColor: (vm.isGeofenceRequired && !vm.isAgentRemoteExempted)
                                ? const Color(0xFF1976D2)
                                : const Color(0xFF2E7D32),
                            title: 'Geofence Requirement',
                            value: (vm.isGeofenceRequired && !vm.isAgentRemoteExempted)
                                ? '${vm.allowedRadiusInMeters.round()}m Office Radar Active'
                                : 'Remote Mode Active (Unrestricted)',
                            subtitle: (vm.isGeofenceRequired && !vm.isAgentRemoteExempted)
                                ? 'Live GPS Enforced'
                                : 'Punch In Anywhere',
                          ),
                        ],
                      ),
                    ),

                    if (vm.attendanceError != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFEF9A9A)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_off_rounded, color: Color(0xFFD32F2F), size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                vm.attendanceError!,
                                style: const TextStyle(
                                  color: Color(0xFFC62828),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFC62828)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: vm.clearAttendanceError,
                            ),
                          ],
                        ),
                      ).animate().shake(duration: 400.ms),
                    ],

                    const SizedBox(height: 36),

                    // Biometric Punch In Core
                    GestureDetector(
                      onTap: vm.isPunchingIn ? null : _onBiometricPunchIn,
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer Radar Waves
                              Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFC9A227).withAlpha(15),
                                  border: Border.all(
                                    color: const Color(0xFFC9A227).withAlpha(35),
                                    width: 1.5,
                                  ),
                                ),
                              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                                    begin: const Offset(0.92, 0.92),
                                    end: const Offset(1.08, 1.08),
                                    duration: 2000.ms,
                                  ),

                              // Middle Glowing Ring
                              Container(
                                width: 135,
                                height: 135,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFFC9A227).withAlpha(40),
                                      const Color(0xFF8B6914).withAlpha(15),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFFC9A227).withAlpha(70),
                                    width: 2,
                                  ),
                                ),
                              ),

                              // Core Metallic Biometric Button
                              Container(
                                width: 105,
                                height: 105,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF5C3D0E),
                                      Color(0xFF8B6914),
                                      Color(0xFFC9A227),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF8B6914).withAlpha(120),
                                      blurRadius: 25,
                                      offset: const Offset(0, 10),
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFFC9A227).withAlpha(80),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: const Color(0xFFFFE082),
                                    width: 2.5,
                                  ),
                                ),
                                child: Center(
                                  child: vm.isPunchingIn
                                      ? const SizedBox(
                                          width: 40,
                                          height: 40,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.fingerprint_rounded,
                                          size: 58,
                                          color: Colors.white,
                                        ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Dynamic Action Text
                          Text(
                            vm.isPunchingIn
                                ? 'RECORDING ATTENDANCE...'
                                : 'TAP TO PUNCH IN',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF8B6914),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Touch the biometric sensor to mark attendance',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
            ],
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
