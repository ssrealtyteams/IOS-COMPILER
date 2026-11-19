import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/services/permission_service.dart';
import 'core/services/location_tracking_service.dart';
import 'core/services/attendance_record_service.dart';

import 'core/services/new_lead_sync_service.dart';
import 'core/platform/call_channel.dart';
import 'data/repositories/remote_lead_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Flutter error shield to prevent uncaught exceptions from crashing the app
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('🚨 [FlutterError] Caught error: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🚨 [PlatformDispatcher] Uncaught async error: $error\n$stack');
    return true; // Return true to mark handled and prevent app termination
  };

  if (!kIsWeb) {
    // Lock orientation to portrait on mobile
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  
  runApp(const SalesCrmApp());

  // Initialize background services and permissions after runApp
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await RemoteLeadRepository.init();
    await AttendanceRecordService.init();
    if (!kIsWeb) {
      await NotificationService.init();
      await PermissionService.requestAllPermissions();
      await NewLeadSyncService.init();
      LocationTrackingService.instance.startTracking();
    }
  });
}

class SalesCrmApp extends StatelessWidget {
  const SalesCrmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SS REALTY CRM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
