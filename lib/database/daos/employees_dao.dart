import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/employees.dart';
import '../../features/auth/utils/pin_hasher.dart';
import '../../features/auth/utils/session_manager.dart';
import '../../features/auth/domain/session.dart';
import '../../features/auth/domain/user_role.dart';

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

  // ============================================================
  // 권한 시스템 메서드
  // ============================================================

  /// PIN 설정
  ///
  /// [employeeId] 직원 ID
  /// [plainPin] 평문 PIN (4-6자리 숫자)
  /// Returns: 설정 성공 여부
  Future<bool> setPIN(int employeeId, String plainPin) async {
    // PIN 형식 검증
    if (!PinHasher.isValidPinFormat(plainPin)) {
      return false;
    }

    // PIN 해시 생성
    final hashedPin = PinHasher.hashPin(plainPin);

    // 업데이트
    final updates = EmployeesCompanion(
      pinHash: Value(hashedPin),
      pinChangedAt: Value(DateTime.now()),
    );

    return await updateEmployee(employeeId, updates);
  }

  /// PIN 검증
  ///
  /// [employeeId] 직원 ID
  /// [plainPin] 입력받은 평문 PIN
  /// Returns: 일치 여부
  Future<bool> verifyPIN(int employeeId, String plainPin) async {
    final employee = await getEmployee(employeeId);

    if (employee == null || employee.pinHash == null) {
      return false;
    }

    return PinHasher.verifyPin(plainPin, employee.pinHash!);
  }

  /// 세션 생성
  ///
  /// [employeeId] 직원 ID
  /// Returns: 생성된 세션 토큰
  Future<String> createSession(int employeeId) async {
    final token = SessionManager.generateToken();
    final expiresAt = SessionManager.calculateExpiry();

    final updates = EmployeesCompanion(
      sessionToken: Value(token),
      sessionExpiresAt: Value(expiresAt),
      lastLoginAt: Value(DateTime.now()),
    );

    await updateEmployee(employeeId, updates);
    return token;
  }

  /// 세션 정보 조회
  ///
  /// [employeeId] 직원 ID
  /// Returns: 세션 객체 (없으면 null)
  Future<Session?> getSessionInfo(int employeeId) async {
    final employee = await getEmployee(employeeId);

    if (employee == null ||
        employee.sessionToken == null ||
        employee.sessionExpiresAt == null) {
      return null;
    }

    // 세션 유효성 확인
    if (!SessionManager.isSessionValid(
      employee.sessionExpiresAt,
      employee.lastLoginAt,
    )) {
      // 유효하지 않은 세션은 삭제
      await clearSession(employeeId);
      return null;
    }

    return Session(
      employeeId: employee.id,
      employeeName: employee.name,
      role: UserRoleExtension.fromString(employee.role),
      token: employee.sessionToken!,
      expiresAt: employee.sessionExpiresAt!,
      lastActivityAt: employee.lastLoginAt ?? DateTime.now(),
    );
  }

  /// 토큰으로 세션 조회
  ///
  /// [token] 세션 토큰
  /// Returns: 세션 객체 (없으면 null)
  Future<Session?> getSessionByToken(String token) async {
    final employee = await (select(employees)
          ..where((e) => e.sessionToken.equals(token)))
        .getSingleOrNull();

    if (employee == null) return null;

    return await getSessionInfo(employee.id);
  }

  /// 세션 활동 시간 업데이트
  ///
  /// [employeeId] 직원 ID
  Future<void> updateSessionActivity(int employeeId) async {
    final updates = EmployeesCompanion(
      lastLoginAt: Value(DateTime.now()),
    );

    await updateEmployee(employeeId, updates);
  }

  /// 세션 삭제 (로그아웃)
  ///
  /// [employeeId] 직원 ID
  Future<void> clearSession(int employeeId) async {
    final updates = EmployeesCompanion(
      sessionToken: const Value(null),
      sessionExpiresAt: const Value(null),
    );

    await updateEmployee(employeeId, updates);
  }

  /// 최종 로그인 시간 갱신
  ///
  /// [employeeId] 직원 ID
  Future<void> updateLastLogin(int employeeId) async {
    final updates = EmployeesCompanion(
      lastLoginAt: Value(DateTime.now()),
    );

    await updateEmployee(employeeId, updates);
  }

  /// 역할별 직원 조회
  ///
  /// [role] 직원 역할
  /// Returns: 해당 역할의 직원 목록
  Future<List<Employee>> getEmployeesByRole(String role) {
    return (select(employees)
          ..where((e) => e.role.equals(role))
          ..where((e) => e.isActive.equals(true)))
        .get();
  }

  /// 관리자 직원 조회
  ///
  /// Returns: 관리자 목록
  Future<List<Employee>> getManagers() {
    return getEmployeesByRole('MANAGER');
  }

  /// PIN이 설정되지 않은 직원 조회
  ///
  /// Returns: PIN 미설정 직원 목록
  Future<List<Employee>> getEmployeesWithoutPIN() {
    return (select(employees)
          ..where((e) => e.pinHash.isNull())
          ..where((e) => e.isActive.equals(true)))
        .get();
  }
}
