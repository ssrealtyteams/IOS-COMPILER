import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

class PermissionService {
  static final Logger _logger = Logger();

  /// Essential permissions required for Sales CRM operation
  static final List<Permission> essentialPermissions = [
    Permission.location,
    Permission.locationWhenInUse,
    Permission.phone,
    Permission.contacts,
    Permission.notification,
    Permission.microphone,
  ];

  /// Checks if all essential permissions are currently granted
  static Future<bool> hasAllEssentialPermissions() async {
    if (kIsWeb) return true;
    try {
      for (final permission in [
        Permission.location,
        Permission.phone,
        Permission.contacts,
        Permission.notification,
      ]) {
        final status = await permission.status;
        if (!status.isGranted && !status.isLimited) {
          return false;
        }
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  /// Requests all essential permissions directly via native system dialogs
  static Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    if (kIsWeb) return {};

    _logger.i('[PermissionService] Requesting essential app permissions directly via OS dialogs...');

    try {
      final List<Permission> permissionsToRequest = [];

      // Check location
      final locStatus = await Permission.location.status;
      if (!locStatus.isGranted) permissionsToRequest.add(Permission.location);

      // Check phone & calls
      final phoneStatus = await Permission.phone.status;
      if (!phoneStatus.isGranted) permissionsToRequest.add(Permission.phone);

      // Check contacts
      final contactStatus = await Permission.contacts.status;
      if (!contactStatus.isGranted) permissionsToRequest.add(Permission.contacts);

      // Check notifications
      final notifStatus = await Permission.notification.status;
      if (!notifStatus.isGranted) permissionsToRequest.add(Permission.notification);

      // Check microphone (for voice notes / audio)
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) permissionsToRequest.add(Permission.microphone);

      if (permissionsToRequest.isEmpty) {
        _logger.i('[PermissionService] All essential permissions already granted.');
        return {};
      }

      // Request permissions natively in batch (opens standard Android OS dialogs)
      final statuses = await permissionsToRequest.request();

      // Log status for each
      statuses.forEach((permission, status) {
        _logger.i('[PermissionService] ${permission.toString()}: ${status.name}');
      });

      return statuses;
    } catch (e) {
      _logger.w('[PermissionService] Permission request warning: $e');
      return {};
    }
  }

  /// Requests system permissions directly without any custom in-app modal UI
  static Future<bool> checkAndPromptPermissions(BuildContext context) async {
    if (kIsWeb) return true;
    final hasAll = await hasAllEssentialPermissions();
    if (hasAll) return true;

    // Directly trigger native Android system prompts one by one
    final statuses = await requestAllPermissions();
    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }
}
