import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:sales_crm_dialer/core/theme/app_colors.dart';
import 'package:sales_crm_dialer/core/router/app_router.dart';
import 'package:sales_crm_dialer/ui/features/auth/data/sources/local/local_auth_source_impl.dart';
import '../../view_models/admin_view_model.dart';

class DirectorProfileSheet extends StatefulWidget {
  final AdminViewModel viewModel;

  const DirectorProfileSheet({
    super.key,
    required this.viewModel,
  });

  static Future<void> show(BuildContext context, AdminViewModel viewModel) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DirectorProfileSheet(viewModel: viewModel),
    );
  }

  @override
  State<DirectorProfileSheet> createState() => _DirectorProfileSheetState();
}

class _DirectorProfileSheetState extends State<DirectorProfileSheet> {
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _isOldObscure = true;
  bool _isNewObscure = true;
  bool _isConfirmObscure = true;

  bool _isChangingPassword = false;
  bool _isLoggingOut = false;

  @override
  void dispose() {
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    final oldPass = _oldPasswordCtrl.text.trim();
    final newPass = _newPasswordCtrl.text.trim();
    final confirmPass = _confirmPasswordCtrl.text.trim();

    if (oldPass.isEmpty) {
      _showToast('Please enter your current password', isError: true);
      return;
    }
    if (newPass.isEmpty) {
      _showToast('Please enter a new password', isError: true);
      return;
    }
    if (newPass.length < 6) {
      _showToast('New password must be at least 6 characters long', isError: true);
      return;
    }
    if (newPass != confirmPass) {
      _showToast('New passwords do not match!', isError: true);
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      final res = await widget.viewModel.changePassword(
        oldPassword: oldPass,
        newPassword: newPass,
        email: 'info@ssrealty.org',
        employeeId: 'SSR000',
      );

      if (!mounted) return;
      setState(() => _isChangingPassword = false);

      if (res.success) {
        _oldPasswordCtrl.clear();
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();
        _showToast(res.message, isError: false);
      } else {
        _showToast(res.message, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isChangingPassword = false);
      _showToast('Error updating password: $e', isError: true);
    }
  }

  void _showToast(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text(
              'Director Logout',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out from Yogesh Tanwar (Director Suite)? You will be returned to the login screen.',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF475569)),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Logout', style: TextStyle(fontWeight: FontWeight.w800)),
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
        Navigator.pop(context); // Close bottom sheet
        context.go(AppRoutes.login);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully from Director Suite'),
            backgroundColor: Color(0xFF8B6914),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_rounded, color: AppColors.ssGoldDark, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Director Profile & Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Scrollable Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Director Profile Card
                  _buildDirectorProfileCard(),

                  const SizedBox(height: 16),

                  // 2. Change Password Card
                  _buildChangePasswordCard(),

                  const SizedBox(height: 16),

                  // 3. Logout Button
                  _buildLogoutButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0, duration: 250.ms);
  }

  // ─── 1. Director Profile Header Card ──────────────────────────────────────
  Widget _buildDirectorProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3E2723), Color(0xFF5C3D0E), Color(0xFF8B6914)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C3D0E).withAlpha(60),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEDD98A), Color(0xFFD4AF37)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Center(
                  child: Text(
                    'YT',
                    style: TextStyle(
                      color: Color(0xFF3E2723),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Name & Role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Yogesh Tanwar',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDD98A),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SSR000',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF3E2723),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '👑 Managing Director & Administrator',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEDD98A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'info@ssrealty.org',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 2. Change Password Card ──────────────────────────────────────────────
  Widget _buildChangePasswordCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_reset_rounded, size: 18, color: AppColors.ssGoldDark),
              SizedBox(width: 8),
              Text(
                'Change Password',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Current Password
          _buildPasswordField(
            label: 'Current Password',
            hint: 'Enter your current password',
            controller: _oldPasswordCtrl,
            isObscure: _isOldObscure,
            onToggleVisibility: () => setState(() => _isOldObscure = !_isOldObscure),
          ),

          const SizedBox(height: 10),

          // 2. New Password
          _buildPasswordField(
            label: 'New Password',
            hint: 'Enter new password (min 6 characters)',
            controller: _newPasswordCtrl,
            isObscure: _isNewObscure,
            onToggleVisibility: () => setState(() => _isNewObscure = !_isNewObscure),
          ),

          const SizedBox(height: 10),

          // 3. Confirm New Password
          _buildPasswordField(
            label: 'Confirm New Password',
            hint: 'Re-enter your new password',
            controller: _confirmPasswordCtrl,
            isObscure: _isConfirmObscure,
            onToggleVisibility: () => setState(() => _isConfirmObscure = !_isConfirmObscure),
          ),

          const SizedBox(height: 16),

          // Update Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ssGoldDark,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isChangingPassword ? null : _handleChangePassword,
              child: _isChangingPassword
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 17),
                        SizedBox(width: 6),
                        Text(
                          'Update Password',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool isObscure,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isObscure,
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(
                  isObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  size: 18,
                  color: const Color(0xFF64748B),
                ),
                onPressed: onToggleVisibility,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── 3. Logout Button ─────────────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
          backgroundColor: const Color(0xFFFEF2F2),
          foregroundColor: const Color(0xFFDC2626),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _isLoggingOut ? null : _confirmLogout,
        child: _isLoggingOut
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Color(0xFFDC2626), strokeWidth: 2),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, size: 18, color: Color(0xFFDC2626)),
                  SizedBox(width: 8),
                  Text(
                    'Log Out from Director Suite',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
