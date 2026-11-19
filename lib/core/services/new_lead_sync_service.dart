import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sales_crm_dialer/data/repositories/remote_lead_repository.dart';
import 'package:sales_crm_dialer/domain/entities/lead.dart';
import 'notification_service.dart';

class NewLeadSyncService {
  static const String _kKnownLeadsKey = 'known_lead_ids';
  static final Set<String> _knownLeadIds = {};
  static Timer? _syncTimer;
  static bool _isChecking = false;
  static bool _isInitialized = false;

  /// Initializes known lead IDs and starts real-time background sync
  static Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_kKnownLeadsKey);

      if (savedJson != null && savedJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(savedJson);
        _knownLeadIds.addAll(decoded.map((e) => e.toString()));
      } else {
        // First run: seed with existing cached leads so we don't alert on historical leads
        for (final lead in RemoteLeadRepository.currentLeads) {
          _knownLeadIds.add(lead.id);
        }
        await _saveKnownLeads();
      }

      debugPrint('🔥 [NewLeadSyncService] Initialized with ${_knownLeadIds.length} known leads');

      // Start periodic real-time sync (every 10 seconds)
      _syncTimer?.cancel();
      _syncTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        checkForNewLeads();
      });

      // Run immediate check
      checkForNewLeads();
    } catch (e) {
      debugPrint('Error initializing NewLeadSyncService: $e');
    }
  }

  /// Checks API for newly assigned leads and triggers notification
  static Future<void> checkForNewLeads() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      // Fetch latest leads from backend
      await RemoteLeadRepository.fetchFromApi();

      final currentLeads = RemoteLeadRepository.currentLeads;
      final List<Lead> brandNewLeads = [];

      for (final lead in currentLeads) {
        if (!_knownLeadIds.contains(lead.id)) {
          _knownLeadIds.add(lead.id);
          brandNewLeads.add(lead);
        }
      }

      if (brandNewLeads.isNotEmpty) {
        await _saveKnownLeads();

        for (final newLead in brandNewLeads) {
          debugPrint('🔥 [NewLeadSyncService] Found newly assigned lead: ${newLead.fullName} (${newLead.phone})');
          await NotificationService.showNewLeadNotification(newLead);
        }
      }
    } catch (e) {
      debugPrint('Error in checkForNewLeads: $e');
    } finally {
      _isChecking = false;
    }
  }

  static Future<void> _saveKnownLeads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_knownLeadIds.toList());
      await prefs.setString(_kKnownLeadsKey, encoded);
    } catch (e) {
      debugPrint('Error saving known leads: $e');
    }
  }

  /// Disposes sync timer on logout
  static void dispose() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _isInitialized = false;
  }
}
