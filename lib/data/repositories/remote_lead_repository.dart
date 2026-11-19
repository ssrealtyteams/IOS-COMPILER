import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/contact_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/error/result.dart';
import '../../domain/entities/lead.dart';
import '../../ui/features/leads/view_models/lead_list_view_model.dart';
import '../../ui/features/auth/data/sources/local/local_auth_source_impl.dart';

class RemoteLeadRepository implements LeadRepository {
  RemoteLeadRepository({this.isNewLeadsOnly = false});

  final bool isNewLeadsOnly;

  static List<Lead> _cachedLeads = [];
  static final Map<String, List<Activity>> _activities = {};
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  static List<Lead> get currentLeads => List.unmodifiable(_cachedLeads);

  static List<Activity> getAllActivities() {
    final list = <Activity>[];
    _activities.forEach((_, acts) {
      list.addAll(acts);
    });
    return list;
  }

  static List<Activity> getActivitiesForAgent(String agentName, String? employeeId) {
    final list = <Activity>[];
    final cleanName = agentName.trim().toLowerCase();
    final cleanEmp = employeeId?.trim().toLowerCase();

    _activities.forEach((_, acts) {
      for (final a in acts) {
        final actAgent = a.agentName.trim().toLowerCase();
        if (actAgent.contains(cleanName) || (cleanEmp != null && actAgent.contains(cleanEmp))) {
          list.add(a);
        }
      }
    });
    return list;
  }

  static Future<List<Lead>> getAllLeadsStatic() async {
    try {
      await fetchFromApi();
    } catch (_) {}
    return currentLeads;
  }

  /// Initialize and load leads + call activities from cache, then fetch fresh from API
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLeads = prefs.getString('cached_remote_leads');
      if (savedLeads != null) {
        final List<dynamic> decoded = jsonDecode(savedLeads);
        _cachedLeads = decoded.map((e) {
          final lead = Lead.fromJson(e as Map<String, dynamic>);
          final isManualOrDirect = lead.id.startsWith('manual-') ||
              lead.id.startsWith('call_') ||
              lead.source == 'Manual Dial' ||
              lead.source == 'Direct Call' ||
              lead.projectName == 'Direct Dial' ||
              lead.projectName == 'Manual Dial';

          if (isManualOrDirect) {
            return lead.copyWith(
              source: 'Manual Dial',
              status: lead.status == LeadStatus.newLead ? LeadStatus.notConnected : lead.status,
              unitType: (lead.unitType == '2/3/4 BHK' || lead.propertyType == '2/3/4 BHK') ? null : lead.unitType,
              propertyType: (lead.unitType == '2/3/4 BHK' || lead.propertyType == '2/3/4 BHK') ? null : lead.propertyType,
            );
          }
          return lead;
        }).toList();
      }

      final savedActivities = prefs.getString('cached_lead_activities');
      if (savedActivities != null) {
        final Map<String, dynamic> decodedActs = jsonDecode(savedActivities);
        decodedActs.forEach((key, val) {
          if (val is List) {
            _activities[key] = val.map((a) {
              final aMap = a as Map<String, dynamic>;
              return Activity(
                id: aMap['id']?.toString() ?? key,
                date: aMap['date'] != null ? DateTime.tryParse(aMap['date'].toString()) ?? DateTime.now() : DateTime.now(),
                outcome: aMap['outcome']?.toString() ?? 'Connected',
                duration: aMap['duration']?.toString() ?? '0s',
                agentName: aMap['agentName']?.toString() ?? 'Agent',
                notes: aMap['notes']?.toString(),
                recordingUrl: aMap['recordingUrl']?.toString(),
                recordingPath: aMap['recordingPath']?.toString(),
              );
            }).toList();
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading cached data: $e');
    }

    // Attempt to fetch fresh leads & call histories from Next.js backend
    await fetchFromApi();
  }

  /// Sync all leads and activities from the Next.js API
  static Future<void> fetchFromApi() async {
    try {
      final token = await LocalAuthSourceImpl().getAccessToken();
      final options = Options(
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 8),
        headers: {
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

      final endpoints = [
        'https://ssrealty.org/api/mobile/leads',
        if (ApiConstants.baseUrl != 'https://ssrealty.org/api/mobile')
          '${ApiConstants.baseUrl}/leads',
      ];

      for (final endpoint in endpoints) {
        try {
          final response = await _dio.get(endpoint, options: options);
          if (response.statusCode == 200 && response.data != null) {
            final dynamic rawData = response.data;
            List<dynamic> leadsList = [];
            if (rawData is List) {
              leadsList = rawData;
            } else if (rawData is Map && rawData['leads'] is List) {
              leadsList = rawData['leads'];
            } else if (rawData is Map && rawData['items'] is List) {
              leadsList = rawData['items'];
            }

            if (leadsList.isNotEmpty) {
              final remoteLeads = leadsList.map((json) => Lead.fromJson(json as Map<String, dynamic>)).toList();
              
              // Merge with local cached leads preserving local status updates
              final Map<String, Lead> mergedMap = {};
              for (final cLead in _cachedLeads) {
                mergedMap[cLead.id] = cLead;
              }
              for (final rLead in remoteLeads) {
                if (!mergedMap.containsKey(rLead.id)) {
                  mergedMap[rLead.id] = rLead;
                } else {
                  final existing = mergedMap[rLead.id]!;
                  // If locally updated, preserve local status
                  if (existing.status != LeadStatus.newLead) {
                    mergedMap[rLead.id] = rLead.copyWith(
                      status: existing.status,
                      lastActivityAt: existing.lastActivityAt ?? rLead.lastActivityAt,
                      unitType: existing.unitType ?? rLead.unitType,
                      projectName: existing.projectName ?? rLead.projectName,
                    );
                  } else {
                    mergedMap[rLead.id] = rLead;
                  }
                }
              }
              _cachedLeads = mergedMap.values.toList();
              await _saveToCache();
              debugPrint('✅ Loaded ${_cachedLeads.length} leads from API: $endpoint');
              break;
            }
          }
        } catch (e) {
          debugPrint('Failed to load leads from $endpoint: $e');
        }
      }
    } catch (e) {
      debugPrint('Error syncing leads from API: $e');
    }
  }

  static Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedLeads = jsonEncode(_cachedLeads.map((e) => e.toJson()).toList());
      await prefs.setString('cached_remote_leads', encodedLeads);

      final Map<String, dynamic> actsToSave = {};
      _activities.forEach((key, list) {
        actsToSave[key] = list.map((a) => {
          'id': a.id,
          'date': a.date.toIso8601String(),
          'outcome': a.outcome,
          'duration': a.duration,
          'agentName': a.agentName,
          'notes': a.notes,
          'recordingUrl': a.recordingUrl,
          'recordingPath': a.recordingPath,
        }).toList();
      });
      await prefs.setString('cached_lead_activities', jsonEncode(actsToSave));
    } catch (e) {
      debugPrint('Error saving to local cache: $e');
    }
  }

  /// Immediately log any call made to the backend and cache so live metrics update instantly
  static Future<void> logCallImmediately({
    required String phoneNumber,
    String? leadName,
    int durationSeconds = 0,
    String durationDisplay = '0s',
    String? recordingPath,
    String? recordingUrl,
    bool isManual = false,
  }) async {
    try {
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanPhone.isEmpty) return;

      final lead = await findOrCreateLead(phoneNumber, customName: leadName);
      final outcome = durationSeconds > 0 ? 'Connected' : 'Not Connected';

      // If lead was in New Leads status, immediately transition to Contacted so it leaves New Leads tab
      final leadIdx = _findLeadIndex(lead.id);
      if (leadIdx != -1 && _cachedLeads[leadIdx].status == LeadStatus.newLead) {
        _cachedLeads[leadIdx] = _cachedLeads[leadIdx].copyWith(
          status: LeadStatus.contacted,
          lastActivityAt: DateTime.now(),
        );
      }

      String agentName = 'Agent';

      try {
        final user = await LocalAuthSourceImpl().getCurrentUser();
        if (user != null) {
          agentName = user.fullName;
        }
      } catch (_) {}

      final activity = Activity(
        id: '${lead.id}_${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        outcome: outcome,
        duration: durationDisplay,
        agentName: agentName,
        notes: 'Call placed from CRM Dialer',
        recordingPath: recordingPath,
        recordingUrl: recordingUrl,
      );

      _insertOrUpdateActivity(lead.id, activity);
      _insertOrUpdateActivity(cleanPhone, activity);
      if (cleanPhone.length >= 10) {
        _insertOrUpdateActivity(cleanPhone.substring(cleanPhone.length - 10), activity);
      }

      await _saveToCache();

      // Sync disposition and call history to Next.js backend
      _syncDispositionToBackend(
        leadId: lead.id,
        disposition: durationSeconds > 0 ? 'connected' : 'not_connected',
        duration: durationDisplay,
        durationSeconds: durationSeconds,
        recordingPath: recordingPath,
        recordingUrl: recordingUrl,
        phoneNumber: phoneNumber,
        leadName: lead.fullName,
        propertyInterest: lead.projectName,
        isManual: isManual,
      );
    } catch (e) {
      debugPrint('Error logging call immediately: $e');
    }
  }

  /// Find or create a lead when manually dialled
  static Future<Lead> findOrCreateLead(String phoneNumber, {String? customName}) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final last10 = cleanPhone.length >= 10 ? cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;

    // Resolve Contact Name via Device Address Book / PhoneLookup
    String? resolvedName = customName;
    if (resolvedName == null || resolvedName.isEmpty || resolvedName.startsWith('Lead ')) {
      resolvedName = await ContactService.lookupContactNameAsync(phoneNumber);
    }

    // 1. Check if already exists in loaded leads
    final idx = _cachedLeads.indexWhere((l) {
      final pClean = l.phone.replaceAll(RegExp(r'[^0-9]'), '');
      return pClean == cleanPhone || (pClean.length >= 10 && pClean.endsWith(last10));
    });

    if (idx != -1) {
      Lead matchedLead = _cachedLeads[idx];
      if (resolvedName != null && resolvedName.isNotEmpty && (matchedLead.fullName.startsWith('Lead ') || matchedLead.fullName == 'Unknown Contact' || matchedLead.fullName == phoneNumber)) {
        matchedLead = matchedLead.copyWith(fullName: resolvedName);
      }
      matchedLead = matchedLead.copyWith(lastActivityAt: DateTime.now());
      // Move to top of cache immediately
      _cachedLeads.removeAt(idx);
      _cachedLeads.insert(0, matchedLead);
      await _saveToCache();
      return matchedLead;
    }

    // 2. Create a clean manual lead
    final newLead = Lead(
      id: 'manual-${DateTime.now().millisecondsSinceEpoch}',
      fullName: (resolvedName != null && resolvedName.isNotEmpty) ? resolvedName : 'Lead $phoneNumber',
      phone: phoneNumber,
      status: LeadStatus.notConnected,
      priority: LeadPriority.medium,
      source: 'Manual Dial',
      createdAt: DateTime.now(),
      projectName: 'Direct Dial',
      propertyType: null,
      unitType: null,
      location: null,
      leadAge: 'Just now',
      formattedDate: '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      formattedTime: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      lastActivityAt: DateTime.now(),
    );

    _cachedLeads.insert(0, newLead);
    await _saveToCache();
    return newLead;
  }

  static Future<void> updateLeadInRepo(Lead updatedLead) async {
    final idx = _cachedLeads.indexWhere((l) => l.id == updatedLead.id);
    if (idx != -1) {
      _cachedLeads.removeAt(idx);
      _cachedLeads.insert(0, updatedLead);
      await _saveToCache();
    } else {
      _cachedLeads.insert(0, updatedLead);
      await _saveToCache();
    }
  }

  @override
  Future<Result<PaginatedList<Lead>, AppError>> getLeads({
    required int page,
    required int limit,
    required LeadFilter filter,
  }) async {
    try {
      var filtered = List<Lead>.from(_cachedLeads);

      if (isNewLeadsOnly) {
        // "New Leads" tab ONLY shows freshly assigned leads from backend CRM / API that are uncontacted
        filtered = filtered.where((l) {
          if (l.status != LeadStatus.newLead) return false;
          if (l.id.startsWith('manual-') || l.id.startsWith('call_') || l.id.startsWith('contact_')) return false;
          if (l.projectName == 'Direct Dial' || l.projectName == 'Manual Dial') return false;
          final src = l.source.toLowerCase();
          if (src.contains('manual') || src.contains('direct') || src.contains('incoming') || src.contains('dialpad')) return false;
          return true;
        }).toList();
      } else if (filter.status != null) {
        filtered = filtered.where((l) => l.status == filter.status).toList();
      }

      if (filter.priority != null) {
        filtered = filtered.where((l) => l.priority == filter.priority).toList();
      }

      if (filter.search != null && filter.search!.isNotEmpty) {
        final q = filter.search!.toLowerCase();
        filtered = filtered.where((l) =>
            l.fullName.toLowerCase().contains(q) ||
            l.phone.contains(q) ||
            (l.projectName?.toLowerCase().contains(q) ?? false) ||
            (l.location?.toLowerCase().contains(q) ?? false)).toList();
      }

      // Always sort so that the most recently dialed / active lead is at the very top
      filtered.sort((a, b) {
        final aTime = a.lastActivityAt ?? a.createdAt;
        final bTime = b.lastActivityAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });

      final start = (page - 1) * limit;
      final end = (start + limit) > filtered.length ? filtered.length : (start + limit);
      final pageItems = start < filtered.length ? filtered.sublist(start, end) : <Lead>[];

      return Result.success(
        PaginatedList(
          items: pageItems,
          total: filtered.length,
          page: page,
          limit: limit,
        ),
      );
    } catch (e) {
      return Result.failure(AppError.server('Error fetching leads: $e'));
    }
  }

  static int _findLeadIndex(String leadId) {
    if (leadId.isEmpty) return -1;
    int idx = _cachedLeads.indexWhere((l) => l.id == leadId);
    if (idx != -1) return idx;

    final clean = leadId.replaceAll('manual-', '').replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isNotEmpty) {
      final last10 = clean.length >= 10 ? clean.substring(clean.length - 10) : clean;
      idx = _cachedLeads.indexWhere((l) {
        final p = l.phone.replaceAll(RegExp(r'[^0-9]'), '');
        return p == clean || (p.length >= 10 && p.endsWith(last10));
      });
      if (idx != -1) return idx;
    }

    return -1;
  }

  @override
  Future<Result<Lead, AppError>> getLeadById(String id) async {
    try {
      final idx = _findLeadIndex(id);
      if (idx != -1) {
        return Result.success(_cachedLeads[idx]);
      }
      return Result.failure(AppError.notFound('Lead $id'));
    } catch (e) {
      return Result.failure(AppError.notFound('Lead $id'));
    }
  }

  static void _insertOrUpdateActivity(String key, Activity activity) {
    final list = _activities.putIfAbsent(key, () => []);
    final idx = list.indexWhere((a) {
      final diff = activity.date.difference(a.date).abs().inSeconds;
      return diff < 60 && (
        (activity.recordingPath != null && activity.recordingPath == a.recordingPath) ||
        a.notes == 'Call placed from CRM Dialer' ||
        a.id.split('_').first == activity.id.split('_').first
      );
    });

    if (idx != -1) {
      // Merge/update existing activity in place
      list[idx] = list[idx].copyWith(
        outcome: activity.outcome,
        duration: activity.duration.isNotEmpty ? activity.duration : list[idx].duration,
        notes: (activity.notes != null && activity.notes != 'Call placed from CRM Dialer') ? activity.notes : list[idx].notes,
        recordingPath: activity.recordingPath ?? list[idx].recordingPath,
        recordingUrl: activity.recordingUrl ?? list[idx].recordingUrl,
      );
    } else {
      list.insert(0, activity);
    }
  }

  @override
  Future<Result<List<Activity>, AppError>> getLeadTimeline(String leadId) async {
    List<Activity>? list = _activities[leadId];

    if (list == null || list.isEmpty) {
      // Lookup by phone number
      final idx = _findLeadIndex(leadId);
      if (idx != -1) {
        final lead = _cachedLeads[idx];
        final clean = lead.phone.replaceAll(RegExp(r'[^0-9]'), '');
        final last10 = clean.length >= 10 ? clean.substring(clean.length - 10) : clean;
        list = _activities[clean] ?? _activities[last10];
      }
    }

    if (list == null) return Result.success([]);

    // Deduplicate activities by unique ID / time proximity
    final unique = <Activity>[];
    final seenTimes = <String>{};

    for (final act in list) {
      final timeKey = '${act.date.year}-${act.date.month}-${act.date.day}_${act.date.hour}:${act.date.minute}_${act.recordingPath ?? act.outcome}';
      if (!seenTimes.contains(timeKey) && !unique.any((u) => u.id == act.id)) {
        seenTimes.add(timeKey);
        unique.add(act);
      }
    }

    return Result.success(unique);
  }

  @override
  Future<Result<void, AppError>> addNote(String leadId, String content) async {
    final idx = _findLeadIndex(leadId);
    if (idx != -1) {
      _cachedLeads[idx] = _cachedLeads[idx].copyWith(
        lastActivityAt: DateTime.now(),
      );
      await _saveToCache();
    }
    return Result.success(null);
  }

  @override
  Future<Result<void, AppError>> updateStatus(String leadId, LeadStatus status) async {
    final idx = _findLeadIndex(leadId);
    if (idx != -1) {
      _cachedLeads[idx] = _cachedLeads[idx].copyWith(
        status: status,
        lastActivityAt: DateTime.now(),
      );
      await _saveToCache();
    }
    return Result.success(null);
  }

  @override
  Future<Result<void, AppError>> updateLead(Lead updatedLead) async {
    final idx = _findLeadIndex(updatedLead.id);
    if (idx != -1) {
      _cachedLeads[idx] = updatedLead;
      await _saveToCache();
    }
    return Result.success(null);
  }

  @override
  Future<Result<void, AppError>> addActivity(String leadId, Activity activity) async {
    _insertOrUpdateActivity(leadId, activity);

    final idx = _findLeadIndex(leadId);
    if (idx != -1) {
      final clean = _cachedLeads[idx].phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.isNotEmpty) {
        _insertOrUpdateActivity(clean, activity);
        if (clean.length >= 10) {
          _insertOrUpdateActivity(clean.substring(clean.length - 10), activity);
        }
      }

      // Map outcome to status
      LeadStatus? newStatus;
      switch (activity.outcome.toLowerCase()) {
        case 'interested':
          newStatus = LeadStatus.interested;
          break;
        case 'call back':
        case 'callback':
          newStatus = LeadStatus.warm;
          break;
        case 'visit scheduled':
          newStatus = LeadStatus.visitScheduled;
          break;
        case 'visit done':
          newStatus = LeadStatus.visitDone;
          break;
        case 'closed':
        case 'closed won':
        case 'booking done':
          newStatus = LeadStatus.closedWon;
          break;
        case 'not interested':
          newStatus = LeadStatus.cold;
          break;
        case 'not connected':
          newStatus = LeadStatus.notConnected;
          break;
      }

      if (newStatus == null && _cachedLeads[idx].status == LeadStatus.newLead) {
        newStatus = LeadStatus.contacted;
      }

      _cachedLeads[idx] = _cachedLeads[idx].copyWith(
        status: newStatus ?? _cachedLeads[idx].status,
        lastActivityAt: activity.date,
      );
      await _saveToCache();

      _syncDispositionToBackend(
        leadId: _cachedLeads[idx].id,
        disposition: activity.outcome,
        notes: activity.notes,
        duration: activity.duration,
        recordingUrl: activity.recordingUrl,
        recordingPath: activity.recordingPath,
        phoneNumber: _cachedLeads[idx].phone,
        leadName: _cachedLeads[idx].fullName,
        propertyInterest: _cachedLeads[idx].projectName,
      );
    }

    return Result.success(null);
  }

  static final Map<String, int> _lastSyncTimestamps = {};

  static void _syncDispositionToBackend({
    required String leadId,
    required String disposition,
    String? notes,
    String? duration,
    int? durationSeconds,
    String? recordingUrl,
    String? recordingPath,
    String? phoneNumber,
    String? leadName,
    String? propertyInterest,
    Map<String, dynamic>? visitDetails,
    String? followUpDate,
    bool isManual = false,
  }) async {
    final cleanPhone = (phoneNumber ?? leadId).replaceAll(RegExp(r'[^0-9]'), '');
    final syncKey = cleanPhone.isNotEmpty ? cleanPhone : leadId;
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastTime = _lastSyncTimestamps[syncKey] ?? 0;
    if (now - lastTime < 5000) {
      debugPrint('⚠️ [RemoteLeadRepository] Suppressing duplicate disposition sync for $syncKey (${now - lastTime}ms ago)');
      return;
    }
    _lastSyncTimestamps[syncKey] = now;
    String agentId = 'mobile_agent';
    String agentName = 'Agent';
    String employeeId = 'SSR001';

    try {
      final user = await LocalAuthSourceImpl().getCurrentUser();
      if (user != null) {
        agentId = user.id;
        agentName = user.fullName;
        employeeId = user.employeeId ?? 'SSR001';
      }
    } catch (_) {}

    final urls = [
      '${ApiConstants.fallbackLocalUrl}/leads/disposition',
      '${ApiConstants.baseUrl}/leads/disposition',
      'https://ssrealty.org/api/mobile/leads/disposition',
    ];

    final body = {
      'leadId': leadId,
      'disposition': disposition,
      'notes': notes ?? '',
      'duration': duration ?? '0s',
      'durationSeconds': durationSeconds ?? 0,
      if (recordingUrl != null) 'recordingUrl': recordingUrl,
      if (recordingPath != null) 'recordingPath': recordingPath,
      'phoneNumber': phoneNumber ?? '',
      'leadName': leadName ?? '',
      'propertyInterest': propertyInterest ?? '',
      'agentId': agentId,
      'agentName': agentName,
      'employeeId': employeeId,
      'source': isManual ? 'manual' : 'mobile',
      if (visitDetails != null) 'visitDetails': visitDetails,
      if (followUpDate != null) 'followUpDate': followUpDate,
    };

    for (final url in urls) {
      try {
        final res = await _dio.post(url, data: body);
        if (res.statusCode == 200) {
          debugPrint('Synced disposition with recording to Next.js at $url for $agentName');
          return;
        }
      } catch (e) {
        debugPrint('Could not sync disposition to $url: $e');
      }
    }
  }
}
