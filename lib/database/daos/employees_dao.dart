import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/employees.dart';

part 'employees_dao.g.dart';

@DriftAccessor(tables: [Employees])
class EmployeesDao extends DatabaseAccessor<AppDatabase>
    with _$EmployeesDaoMixin {
  EmployeesDao(super.db);

  /// 직원 조회
  Future<Employee?> getEmployee(int id) {
    return (select(employees)..where((e) => e.id.equals(id)))
        .getSingleOrNull();
  }

  /// 모든 직원 조회
  Future<List<Employee>> getAllEmployees() {
    return (select(employees)..where((e) => e.isActive.equals(true)))
        .get();
  }

  /// 직원 생성
  Future<int> createEmployee(EmployeesCompanion entry) {
    return into(employees).insert(entry);
  }

  /// 직원 업데이트
  Future<bool> updateEmployee(int id, EmployeesCompanion updates) {
    return (update(employees)..where((e) => e.id.equals(id)))
        .write(updates)
        .then((rows) => rows > 0);
  }
}
