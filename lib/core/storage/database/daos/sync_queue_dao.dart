import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sync_queue_table.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueueTable])
class SyncQueueDao extends DatabaseAccessor<AppDatabase> with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  Future<int> addToQueue(SyncQueueTableCompanion entry) {
    return into(syncQueueTable).insert(entry);
  }

  Future<List<SyncQueueEntity>> getPendingEntries({int limit = 50}) {
    return (select(syncQueueTable)
          ..where((t) => t.status.equals('pending') | t.status.equals('failed'))
          ..orderBy([(t) => OrderingTerm(expression: t.queuedAt)])
          ..limit(limit))
        .get();
  }

  Future<bool> markAsProcessing(int id) {
    return update(syncQueueTable)
        .replace(SyncQueueTableCompanion(id: Value(id), status: const Value('processing')));
  }

  Future<bool> markAsFailed(int id, String error, int currentRetryCount) {
    return update(syncQueueTable).replace(
      SyncQueueTableCompanion(
        id: Value(id),
        status: const Value('failed'),
        lastError: Value(error),
        retryCount: Value(currentRetryCount + 1),
      ),
    );
  }

  Future<int> removeCompletedEntry(int id) {
    return (delete(syncQueueTable)..where((t) => t.id.equals(id))).go();
  }
}
