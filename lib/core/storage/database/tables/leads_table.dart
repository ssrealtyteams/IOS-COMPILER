import 'package:drift/drift.dart';

@DataClassName('LeadEntity')
class LeadsTable extends Table {
  TextColumn get id => text()();
  TextColumn get fullName => text()();
  TextColumn get phone => text()();
  TextColumn get status => text()();
  TextColumn get priority => text()();
  TextColumn get source => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  TextColumn get projectName => text().nullable()();
  RealColumn get budgetMin => real().nullable()();
  RealColumn get budgetMax => real().nullable()();
  TextColumn get location => text().nullable()();
  DateTimeColumn get lastActivityAt => dateTime().nullable()();
  TextColumn get tags => text().map(const ListStringConverter()).nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

// Custom converter for List<String>
class ListStringConverter extends TypeConverter<List<String>, String> {
  const ListStringConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    return fromDb.split(',');
  }

  @override
  String toSql(List<String> value) {
    if (value.isEmpty) return '';
    return value.join(',');
  }
}
