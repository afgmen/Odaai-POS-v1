import 'package:drift/drift.dart';
import '../app_database.dart';

part 'store_assignments_dao.g.dart';

@DriftAccessor(tables: [StoreAssignments])
class StoreAssignmentsDao extends DatabaseAccessor<AppDatabase> with _$StoreAssignmentsDaoMixin {
  StoreAssignmentsDao(AppDatabase db) : super(db);

  /// Get all store assignments for a user
  Future<List<StoreAssignment>> getUserStoreAssignments(int userId) {
    return (select(storeAssignments)..where((sa) => sa.userId.equals(userId))).get();
  }

  /// Get specific store assignment
  Future<StoreAssignment?> getStoreAssignment(int userId, String storeId) {
    return (select(storeAssignments)
      ..where((sa) => sa.userId.equals(userId) & sa.storeId.equals(storeId)))
      .getSingleOrNull();
  }

  /// Check if user has access to store
  Future<bool> hasStoreAccess(int userId, String storeId) async {
    final assignment = await getStoreAssignment(userId, storeId);
    return assignment != null;
  }

  /// Get all assigned store IDs for a user
  Future<List<String>> getUserStoreIds(int userId) async {
    final assignments = await getUserStoreAssignments(userId);
    return assignments.map((a) => a.storeId).toList();
  }

  /// Insert store assignment
  Future<void> insertStoreAssignment(StoreAssignmentsCompanion assignment) {
    return into(storeAssignments).insert(assignment);
  }

  /// Delete store assignment
  Future<void> deleteStoreAssignment(String id) {
    return (delete(storeAssignments)..where((sa) => sa.id.equals(id))).go();
  }

  /// Delete all store assignments for a user
  Future<void> deleteUserStoreAssignments(int userId) {
    return (delete(storeAssignments)..where((sa) => sa.userId.equals(userId))).go();
  }

  /// Batch insert store assignments
  Future<void> insertStoreAssignments(List<StoreAssignmentsCompanion> assignmentsList) {
    return batch((batch) {
      batch.insertAll(storeAssignments, assignmentsList);
    });
  }
}
