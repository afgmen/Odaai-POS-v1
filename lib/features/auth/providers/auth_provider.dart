import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../../../database/app_database.dart';
import '../../../providers/database_providers.dart';

/// 현재 로그인한 직원
final currentEmployeeProvider = StateProvider<Employee?>((ref) => null);

/// PIN 해시 생성 헬퍼
String hashPin(String pin) {
  final bytes = utf8.encode(pin);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

/// PIN 인증 서비스
class AuthService {
  final AppDatabase db;

  AuthService(this.db);

  /// PIN으로 직원 인증
  Future<Employee?> authenticateWithPin(String pin) async {
    final pinHash = hashPin(pin);

    final employees = await (db.select(db.employees)
          ..where((e) => e.pin.equals(pinHash))
          ..where((e) => e.isActive.equals(true)))
        .get();

    return employees.isNotEmpty ? employees.first : null;
  }

  /// 직원 PIN 설정/변경
  Future<void> setPin(int employeeId, String pin) async {
    final pinHash = hashPin(pin);

    await (db.update(db.employees)..where((e) => e.id.equals(employeeId)))
        .write(EmployeesCompanion(pin: Value(pinHash)));
  }

  /// 직원 PIN 제거
  Future<void> removePin(int employeeId) async {
    await (db.update(db.employees)..where((e) => e.id.equals(employeeId)))
        .write(const EmployeesCompanion(pin: Value(null)));
  }

  /// 모든 활성 직원 조회
  Future<List<Employee>> getActiveEmployees() async {
    return await (db.select(db.employees)
          ..where((e) => e.isActive.equals(true))
          ..orderBy([(e) => OrderingTerm(expression: e.name)]))
        .get();
  }

  /// 직원 추가
  Future<Employee> createEmployee({
    required String username,
    required String name,
    required String role,
    String? pin,
  }) async {
    final companion = EmployeesCompanion.insert(
      username: username,
      name: name,
      passwordHash: 'temp', // TODO: 실제 비밀번호 해시 구현
      role: Value(role),
      pin: pin != null ? Value(hashPin(pin)) : const Value(null),
    );

    final id = await db.into(db.employees).insert(companion);
    return await (db.select(db.employees)..where((e) => e.id.equals(id))).getSingle();
  }

  /// 직원 수정
  Future<void> updateEmployee({
    required int id,
    String? name,
    String? role,
    String? pin,
    bool? isActive,
  }) async {
    await (db.update(db.employees)..where((e) => e.id.equals(id))).write(
      EmployeesCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        role: role != null ? Value(role) : const Value.absent(),
        pin: pin != null ? Value(hashPin(pin)) : const Value.absent(),
        isActive: isActive != null ? Value(isActive) : const Value.absent(),
      ),
    );
  }

  /// 직원 비활성화 (삭제 대신)
  Future<void> deactivateEmployee(int id) async {
    await (db.update(db.employees)..where((e) => e.id.equals(id)))
        .write(const EmployeesCompanion(isActive: Value(false)));
  }
}

/// AuthService Provider
final authServiceProvider = Provider<AuthService>((ref) {
  final db = ref.watch(databaseProvider);
  return AuthService(db);
});

/// 활성 직원 목록 Provider
final activeEmployeesProvider = FutureProvider<List<Employee>>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getActiveEmployees();
});
