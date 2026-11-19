import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/leads_table.dart';

part 'lead_dao.g.dart';

@DriftAccessor(tables: [LeadsTable])
class LeadDao extends DatabaseAccessor<AppDatabase> with _$LeadDaoMixin {
  LeadDao(super.db);

  Future<List<LeadEntity>> getAllLeads() => select(leadsTable).get();
  
  Future<LeadEntity?> getLeadById(String id) {
    return (select(leadsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }
  
  Stream<List<LeadEntity>> watchAllLeads() => select(leadsTable).watch();

  Future<int> insertLead(LeadsTableCompanion lead) {
    return into(leadsTable).insert(lead, mode: InsertMode.insertOrReplace);
  }

  Future<void> insertMultipleLeads(List<LeadsTableCompanion> leads) async {
    await batch((batch) {
      batch.insertAll(leadsTable, leads, mode: InsertMode.insertOrReplace);
    });
  }

  Future<bool> updateLead(LeadsTableCompanion lead) {
    return update(leadsTable).replace(lead);
  }

  Future<int> deleteLead(String id) {
    return (delete(leadsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<List<LeadEntity>> getUnsyncedLeads() {
    return (select(leadsTable)..where((t) => t.isSynced.equals(false))).get();
  }
}
