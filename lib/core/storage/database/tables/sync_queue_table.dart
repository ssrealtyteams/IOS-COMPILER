import 'package:drift/drift.dart';

@DataClassName('SyncQueueEntity')
class SyncQueueTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()(); // 'lead', 'call', 'disposition'
  TextColumn get entityId => text()();
  TextColumn get operation => text()(); // 'create', 'update', 'delete'
  TextColumn get payloadJson => text()();
  DateTimeColumn get queuedAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // 'pending', 'processing', 'failed'
}
