// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lead_dao.dart';

// ignore_for_file: type=lint
mixin _$LeadDaoMixin on DatabaseAccessor<AppDatabase> {
  $LeadsTableTable get leadsTable => attachedDatabase.leadsTable;
  LeadDaoManager get managers => LeadDaoManager(this);
}

class LeadDaoManager {
  final _$LeadDaoMixin _db;
  LeadDaoManager(this._db);
  $$LeadsTableTableTableManager get leadsTable =>
      $$LeadsTableTableTableManager(_db.attachedDatabase, _db.leadsTable);
}
