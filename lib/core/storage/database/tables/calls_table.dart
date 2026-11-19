import 'package:drift/drift.dart';

@DataClassName('CallEntity')
class CallsTable extends Table {
  TextColumn get id => text()();
  TextColumn get leadId => text().nullable()();
  TextColumn get phoneNumber => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  TextColumn get status => text()(); // e.g., 'completed', 'missed'
  TextColumn get direction => text()(); // e.g., 'inbound', 'outbound'
  TextColumn get disposition => text().nullable()();
  TextColumn get remarks => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
