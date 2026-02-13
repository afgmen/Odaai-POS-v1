import 'package:drift/drift.dart';
import '../app_database.dart';

part 'user_roles_dao.g.dart';

@DriftAccessor(tables: [UserRoles])
class UserRolesDao extends DatabaseAccessor<AppDatabase> with _$UserRolesDaoMixin {
  UserRolesDao(AppDatabase db) : super(db);

  /// Get user's role
  Future<UserRole?> getUserRole(int userId) {
    return (select(userRoles)..where((r) => r.userId.equals(userId))).getSingleOrNull();
  }

  /// Get all users with a specific role
  Future<List<UserRole>> getUsersByRole(String role) {
    return (select(userRoles)..where((r) => r.role.equals(role))).get();
  }

  /// Insert user role
  Future<void> insertUserRole(UserRolesCompanion userRole) {
    return into(userRoles).insert(userRole);
  }

  /// Update user role
  Future<void> updateUserRole(UserRole userRole) {
    return update(userRoles).replace(userRole);
  }

  /// Delete user role
  Future<void> deleteUserRole(int userId) {
    return (delete(userRoles)..where((r) => r.userId.equals(userId))).go();
  }

  /// Batch insert user roles
  Future<void> insertUserRoles(List<UserRolesCompanion> userRolesList) {
    return batch((batch) {
      batch.insertAll(userRoles, userRolesList);
    });
  }
}
