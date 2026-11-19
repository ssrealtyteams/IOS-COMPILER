import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../ui/features/auth/views/login_screen.dart';
import '../../ui/features/auth/view_models/auth_view_model.dart';
import '../../ui/shell/main_shell.dart';
import '../../ui/features/dashboard/view_models/dashboard_view_model.dart';
import '../../ui/features/calling/views/dialpad_screen.dart';
import '../../ui/features/calling/view_models/call_view_model.dart';
import '../../ui/features/calling/view_models/disposition_view_model.dart';
import '../../ui/features/auth/data/sources/remote/remote_auth_source_impl.dart';
import '../../ui/features/auth/data/sources/local/local_auth_source_impl.dart';
import '../../ui/features/profile/views/profile_screen.dart';
import '../../ui/features/calling/views/followup_alarm_screen.dart';
import '../../data/repositories/remote_lead_repository.dart';

// ─── Route Names ─────────────────────────────────────────────────────────────
abstract class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const leads = '/leads';
  static const leadDetail = '/leads/:id';
  static const dialpad = '/dialpad';
  static const followups = '/followups';
  static const projects = '/projects';
  static const profile = '/profile';
}

// ─── Router ──────────────────────────────────────────────────────────────────
// NOTE: In production this would use get_it for DI.
// Simplified here for direct ViewModel access.
class AppRouter {
  static final AuthViewModel _authVm = AuthViewModel(
    remoteSource: RemoteAuthSourceImpl(),
    localSource: LocalAuthSourceImpl(),
  );

  static final DashboardViewModel _dashVm = DashboardViewModel();
  static final CallViewModel _callVm = CallViewModel()..initialize();
  static final DispositionViewModel _dispositionVm = DispositionViewModel(
    RemoteLeadRepository(isNewLeadsOnly: false),
  );

  static AuthViewModel get authVm => _authVm;
  static DashboardViewModel get dashVm => _dashVm;
  static CallViewModel get callVm => _callVm;
  static DispositionViewModel get dispositionVm => _dispositionVm;

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.splash,
    redirect: (context, state) async {
      // Auth guard logic handled in splash
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => LoginScreen(viewModel: _authVm),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => MainShell(
          dashboardViewModel: _dashVm,
          callViewModel: _callVm,
          dispositionViewModel: _dispositionVm,
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/alarm',
        builder: (context, state) {
          final leadJson = state.extra as String?;
          return FollowupAlarmScreen(leadJson: leadJson ?? '{}');
        },
      ),
      GoRoute(
        path: AppRoutes.dialpad,
        builder: (context, state) {
          final initialNumber = state.extra as String?;
          return CustomDialpad(
            callViewModel: _callVm,
            initialNumber: initialNumber,
          );
        },
      ),
    ],
  );
}

// ─── Splash Screen ───────────────────────────────────────────────────────────
class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final local = LocalAuthSourceImpl();
      final hasSession = await local.hasValidSession();
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        if (hasSession) {
          context.go(AppRoutes.home);
        } else {
          context.go(AppRoutes.login);
        }
      }
    } catch (_) {
      if (mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Rich Brand Theme Gradient (Warm Royal Gold)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF8B6914), // Deep Gold Dark
                  Color(0xFFB8860B), // Classic Gold
                  Color(0xFFC9A227), // Primary Brand Gold
                  Color(0xFFE5C058), // Gold Shimmer
                ],
                stops: [0.0, 0.35, 0.75, 1.0],
              ),
            ),
          ),

          // 2. Geometric Luxury Pattern Overlay
          const CustomPaint(
            painter: _SplashPatternPainter(),
          ),

          // 3. Center Radial Ambient Glow
          Positioned(
            top: size.height * 0.28,
            left: size.width * 0.15,
            right: size.width * 0.15,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withAlpha(50),
                    blurRadius: 90,
                    spreadRadius: 25,
                  ),
                ],
              ),
            ),
          ),

          // 4. Center Brand Icon & Typography
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glassmorphic Golden Icon Card
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(35),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: Colors.white.withAlpha(90),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.apartment_rounded,
                          size: 52,
                          color: Colors.white.withAlpha(45),
                        ),
                        const Icon(
                          Icons.phone_in_talk_rounded,
                          size: 42,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .scale(duration: 650.ms, curve: Curves.elasticOut)
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 24),

                  // App Title
                  const Text(
                    'Sales CRM Dialer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 10),

                  // Subtitle Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withAlpha(60), width: 0.8),
                    ),
                    child: const Text(
                      'SS REALTY SALES PLATFORM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 350.ms, duration: 400.ms)
                      .slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          ),

          // 5. Bottom Brand Tag & Smooth Progress
          Positioned(
            left: 0,
            right: 0,
            bottom: 44,
            child: Column(
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 16),
                Text(
                  'REAL ESTATE SALES AUTOMATION',
                  style: TextStyle(
                    color: Colors.white.withAlpha(190),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                  ),
                ).animate().fadeIn(delay: 600.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Geometric Pattern Painter ──────────────────────────────────────────────
class _SplashPatternPainter extends CustomPainter {
  const _SplashPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withAlpha(18)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = Colors.white.withAlpha(45)
      ..style = PaintingStyle.fill;

    // 1. Draw subtle diagonal geometric mesh pattern
    const step = 44.0;
    for (double x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        gridPaint,
      );
      canvas.drawLine(
        Offset(x + size.height, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    // 2. Draw intersection accent dots
    for (double x = 0; x <= size.width; x += step) {
      for (double y = 0; y <= size.height; y += step) {
        if ((x / step + y / step).round() % 2 == 0) {
          canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
        }
      }
    }

    // 3. Draw ambient glowing concentric rings around center logo
    final center = Offset(size.width / 2, size.height / 2 - 30);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 4; i++) {
      ringPaint.color = Colors.white.withAlpha(16 - (i * 3));
      canvas.drawCircle(center, 65.0 * i, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
