import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../common/widgets/app_text_field.dart';
import '../../common/widgets/primary_button.dart';

import '../../auth/data/sources/local/local_auth_source_impl.dart';
import '../../../../domain/entities/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _isSaving = false;
  bool _isLoggingOut = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await LocalAuthSourceImpl().getCurrentUser();
    if (mounted && user != null) {
      setState(() => _currentUser = user);
    }
  }

  @override
  void dispose() {
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (_oldPasswordCtrl.text.isEmpty || _newPasswordCtrl.text.isEmpty) return;
    
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
    setState(() => _isSaving = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      _oldPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
    }
  }

  Future<void> _handleLogout() async {
    final isDirector = LocalAuthSourceImpl.isDirectorOrExecutive;
    final isPunchedIn = AppRouter.dashVm.isPunchedIn;

    if (!isDirector && isPunchedIn) {
      // Prompt Mandatory Punch-Out Before Logout
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.pause_circle_filled_rounded, color: Color(0xFFE65100), size: 24),
              SizedBox(width: 8),
              Text('Punch Out Required', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17.5)),
            ],
          ),
          content: const Text(
            'Your work shift is currently active (Punched In).\n\nYou must punch out first to record your shift completion before logging out.',
            style: TextStyle(fontSize: 14.5, height: 1.4),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Stay In App', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.exit_to_app_rounded, size: 18),
              onPressed: () => Navigator.pop(ctx, true),
              label: const Text('Punch Out & Logout', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (proceed != true) return;

      setState(() => _isLoggingOut = true);
      try {
        await AppRouter.dashVm.punchOut(auto: false);
        await AppRouter.authVm.logout();
        await LocalAuthSourceImpl().clearSession();
      } catch (e) {
        debugPrint('Punch out & logout notice: $e');
      }

      if (mounted) {
        context.go(AppRoutes.login);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Punched out & Logged out successfully'),
            backgroundColor: Color(0xFF8B6914),
          ),
        );
      }
      return;
    }

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Logout Confirmation', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of your account?',
          style: TextStyle(fontSize: 15),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
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
        debugPrint('Logout cleanup notice: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
        backgroundColor: const Color(0xFF8B6914),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Logout',
            onPressed: _isLoggingOut ? null : _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Image
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: AppColors.primary,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Image picker will open here')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ).animate().scale(delay: 100.ms, duration: 300.ms),
            
            const SizedBox(height: 24),
            
            // User Details
            Text(
              _currentUser?.fullName ?? 'CRM User',
              style: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.bold),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _currentUser?.employeeId != null
                    ? 'EMP: ${_currentUser!.employeeId}'
                    : 'ROLE: ${_currentUser?.role.name ?? "Agent"}',
                style: AppTypography.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ).animate().fadeIn(delay: 250.ms),
            const SizedBox(height: 8),
            Text(
              _currentUser?.email ?? 'crm.user@ssrealty.org',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ).animate().fadeIn(delay: 300.ms),
            
            const SizedBox(height: 40),
            
            // Change Password Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Change Password',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ).animate().slideX(delay: 300.ms),
            const SizedBox(height: 16),
            
            AppTextField(
              controller: _oldPasswordCtrl,
              label: 'Current Password',
              hint: 'Enter your current password',
              obscureText: true,
              prefixIcon: Icons.lock_outline_rounded,
            ).animate().slideX(delay: 350.ms),
            const SizedBox(height: 16),
            
            AppTextField(
              controller: _newPasswordCtrl,
              label: 'New Password',
              hint: 'Enter new password',
              obscureText: true,
              prefixIcon: Icons.lock_outline_rounded,
            ).animate().slideX(delay: 400.ms),
            const SizedBox(height: 16),
            
            AppTextField(
              controller: _confirmPasswordCtrl,
              label: 'Confirm New Password',
              hint: 'Re-enter new password',
              obscureText: true,
              prefixIcon: Icons.lock_outline_rounded,
            ).animate().slideX(delay: 450.ms),
            const SizedBox(height: 24),
            
            PrimaryButton(
              label: 'Update Password',
              onPressed: _updatePassword,
              isLoading: _isSaving,
            ).animate().slideY(delay: 500.ms, begin: 0.5),

            const SizedBox(height: 36),
            const Divider(color: AppColors.border),
            const SizedBox(height: 24),

            // Logout Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _isLoggingOut ? null : _handleLogout,
                icon: _isLoggingOut 
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                      )
                    : const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
                label: Text(
                  _isLoggingOut ? 'Logging out...' : 'Logout',
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: AppColors.error.withValues(alpha: 0.06),
                ),
              ),
            ).animate().fadeIn(delay: 550.ms),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
