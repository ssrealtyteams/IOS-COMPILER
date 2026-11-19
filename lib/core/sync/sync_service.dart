import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../storage/database/app_database.dart';
import '../storage/database/daos/sync_queue_dao.dart';
import '../network/dio_client.dart';
import '../network/network_info.dart';

class SyncService {
  final SyncQueueDao _syncQueueDao;
  final DioClient _apiClient;
  final NetworkInfo _networkInfo;
  
  bool _isSyncing = false;
  Timer? _syncTimer;

  SyncService(this._syncQueueDao, this._apiClient, this._networkInfo);

  void startPeriodicSync({Duration interval = const Duration(minutes: 5)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) => syncPendingData());
  }

  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> syncPendingData() async {
    if (_isSyncing) return;
    
    final hasConnection = await _networkInfo.isConnected;
    if (!hasConnection) return;

    _isSyncing = true;
    try {
      final pendingEntries = await _syncQueueDao.getPendingEntries();
      
      for (final entry in pendingEntries) {
        if (entry.retryCount > 3) continue; // Skip max retried items

        await _syncQueueDao.markAsProcessing(entry.id);
        
        try {
          await _processEntry(entry);
          await _syncQueueDao.removeCompletedEntry(entry.id);
        } catch (e) {
          debugPrint('Sync failed for entry ${entry.id}: $e');
          await _syncQueueDao.markAsFailed(entry.id, e.toString(), entry.retryCount);
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processEntry(SyncQueueEntity entry) async {
    final payload = jsonDecode(entry.payloadJson);
    
    switch (entry.entityType) {
      case 'lead':
        if (entry.operation == 'create') {
          await _apiClient.dio.post('/leads', data: payload);
        } else if (entry.operation == 'update') {
          await _apiClient.dio.put('/leads/${entry.entityId}', data: payload);
        }
        break;
      case 'call':
        if (entry.operation == 'create') {
          await _apiClient.dio.post('/calls/log', data: payload);
        }
        break;
      case 'disposition':
        if (entry.operation == 'create' || entry.operation == 'update') {
          await _apiClient.dio.post('/calls/${entry.entityId}/disposition', data: payload);
        }
        break;
      default:
        throw UnimplementedError('Sync for ${entry.entityType} not implemented');
    }
  }
}
