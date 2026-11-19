import 'package:flutter/foundation.dart';
import '../../../../core/services/permission_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../view_models/auth_view_model.dart';
import '../../common/widgets/app_text_field.dart';
import '../../common/widgets/primary_button.dart';
import '../../common/widgets/loading_overlay.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.viewModel});
  final AuthViewModel viewModel;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  AuthViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PermissionService.checkAndPromptPermissions(context);
      });
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ));
    }
    _vm.addListener(_onStateChange);
  }

  void _onStateChange() {
    if (!mounted) return;
    if (_vm.state == AuthState.authenticated) {
      if (_vm.currentUser != null) {
        AppRouter.dashVm.setUser(_vm.currentUser!);
      }
      if (mounted) context.go('/home');
    }
    if (_vm.state == AuthState.error && _vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_vm.errorMessage!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderRadiusMd),
        ),
      );
      _vm.clearError();
    }
  }

  void _onLogin() {
    if (!_formKey.currentState!.validate()) return;
    _vm.login(
      identifier: _identifierCtrl.text,
      password: _passwordCtrl.text,
    );
  }

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    _vm.removeListener(_onStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          return LoadingOverlay(
            isLoading: _vm.state == AuthState.loading,
            child: _buildBody(),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildForm()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.borderRadiusXl,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: AppRadius.borderRadiusXl,
              child: Image.asset(
                'assets/images/app_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.business_rounded, size: 40, color: AppColors.primary),
              ),
            ),
          )
              .animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 400.ms),
          const SizedBox(height: 20),
          Text(
            'SS REALTY CRM',
            style: AppTypography.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          const SizedBox(height: 6),
          Text(
            'We Dig What You Dream',
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white.withAlpha(200),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: AppRadius.xl),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: AppRadius.borderRadiusFull,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text('Welcome Back', style: AppTypography.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'Sign in to your account to continue',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 32),
              AppTextField(
                controller: _identifierCtrl,
                label: 'Email',
                hint: 'user@example.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter your email';
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              ListenableBuilder(
                listenable: _vm,
                builder: (_, __) => AppTextField(
                  controller: _passwordCtrl,
                  label: 'Password',
                  hint: '••••••••',
                  obscureText: !_vm.isPasswordVisible,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: _vm.isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  onSuffixTap: _vm.togglePasswordVisibility,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter your password';
                    if (v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _onLogin(),
                ),
              ),
              const SizedBox(height: 16),
              ListenableBuilder(
                listenable: _vm,
                builder: (_, __) => Row(
                  children: [
                    Checkbox(
                      value: _vm.rememberMe,
                      onChanged: (_) => _vm.toggleRememberMe(),
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.borderRadiusXs,
                      ),
                    ),
                    Text('Remember me', style: AppTypography.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Sign In',
                onPressed: _onLogin,
                icon: Icons.arrow_forward_rounded,
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Contact your admin if you forgot your password.',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 0.3, duration: 500.ms, curve: Curves.easeOut);
  }
}
