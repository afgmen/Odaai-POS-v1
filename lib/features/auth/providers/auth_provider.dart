import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import '../../../database/daos/employees_dao.dart';
import '../../../providers/database_providers.dart';
import '../domain/session.dart';
import '../domain/auth_error.dart';
import '../utils/pin_hasher.dart';
import 'audit_logging_provider.dart';

/// 인증 상태
class AuthState {
  final Session? session;
  final bool isLoading;
  final AuthError? error;

  AuthState({
    this.session,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => session != null && session!.isValid;

  AuthState copyWith({
    Session? Function()? session,
    bool? isLoading,
    AuthError? Function()? error,
  }) {
    return AuthState(
      session: session != null ? session() : this.session,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
    );
  }
}

/// 인증 Provider
class AuthNotifier extends StateNotifier<AuthState> {
  final EmployeesDao _employeesDao;
  final Ref _ref;

  // 브루트포스 방지
  final Map<int, int> _failedAttempts = {};
  final Map<int, DateTime> _lockoutUntil = {};

  AuthNotifier(this._employeesDao, this._ref) : super(AuthState());

  /// 로그인
  ///
  /// [employeeId] 직원 ID
  /// [pin] 평문 PIN
  Future<void> login(int employeeId, String pin) async {
    try {
      state = state.copyWith(isLoading: true, error: () => null);

      // 1. PIN 형식 검증
      if (!PinHasher.isValidPinFormat(pin)) {
        throw AuthErrors.invalidPinFormat();
      }

      // 2. 계정 잠금 확인
      if (_isLocked(employeeId)) {
        final lockoutTime = _lockoutUntil[employeeId]!;
        final remaining = lockoutTime.difference(DateTime.now());
        throw AuthErrors.accountLocked(duration: remaining);
      }

      // 3. PIN 검증
      final isValid = await _employeesDao.verifyPIN(employeeId, pin);

      if (!isValid) {
        // 실패 카운트 증가
        final attempts = (_failedAttempts[employeeId] ?? 0) + 1;
        _failedAttempts[employeeId] = attempts;

        if (attempts >= 5) {
          // 5회 실패 시 1분 잠금
          _lockoutUntil[employeeId] =
              DateTime.now().add(const Duration(minutes: 1));
          throw AuthErrors.accountLocked(
              duration: const Duration(minutes: 1));
        }

        throw AuthErrors.invalidPin(attemptsLeft: 5 - attempts);
      }

      // 4. 성공 시 실패 카운트 초기화
      _failedAttempts.remove(employeeId);
      _lockoutUntil.remove(employeeId);

      // 5. 세션 생성
      await _employeesDao.createSession(employeeId);
      final session = await _employeesDao.getSessionInfo(employeeId);

      if (session == null) {
        throw AuthError(
          code: 'SYS_001',
          message: '세션 생성에 실패했습니다.',
        );
      }

      // 6. 로그 기록
      await _ref
          .read(auditLoggingProvider)
          .logLogin(employeeId, success: true);

      state = state.copyWith(
        session: () => session,
        isLoading: false,
      );
    } on AuthError catch (e) {
      // 로그인 실패 로그 기록
      await _ref
          .read(auditLoggingProvider)
          .logLogin(employeeId, success: false, errorCode: e.code);

      state = state.copyWith(
        isLoading: false,
        error: () => e,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: () => AuthError(
          code: 'SYS_999',
          message: '알 수 없는 오류가 발생했습니다: $e',
        ),
      );
      rethrow;
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    final session = state.session;
    if (session == null) return;

    try {
      // 세션 삭제
      await _employeesDao.clearSession(session.employeeId);

      // 로그아웃 로그 기록
      await _ref
          .read(auditLoggingProvider)
          .logLogout(session.employeeId);

      state = AuthState();
    } catch (e) {
      // 로그아웃 실패 시에도 상태는 초기화
      state = AuthState();
    }
  }

  /// 세션 복원 (앱 시작 시)
  Future<void> restoreSession(String token) async {
    try {
      final session = await _employeesDao.getSessionByToken(token);

      if (session != null && session.isValid) {
        state = state.copyWith(session: () => session);
      }
    } catch (e) {
      // 세션 복원 실패 시 무시
    }
  }

  /// 세션 활동 갱신
  Future<void> updateActivity() async {
    final session = state.session;
    if (session == null) return;

    try {
      await _employeesDao.updateSessionActivity(session.employeeId);

      // 세션 객체 갱신
      final updatedSession = session.copyWithActivity();
      state = state.copyWith(session: () => updatedSession);
    } catch (e) {
      // 활동 갱신 실패 시 무시
    }
  }

  /// 관리자 PIN 검증 (Manager Override용)
  Future<bool> validateManagerPIN(String pin) async {
    try {
      // 관리자 목록 조회
      final managers = await _employeesDao.getManagers();

      if (managers.isEmpty) {
        throw AuthErrors.employeeNotFound();
      }

      // 모든 관리자 PIN 확인
      for (final manager in managers) {
        if (manager.pinHash == null) continue;
        final isValid = await _employeesDao.verifyPIN(manager.id, pin);
        if (isValid) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// 관리자 ID 조회 (Manager Override용)
  Future<int?> getManagerIdByPIN(String pin) async {
    try {
      final managers = await _employeesDao.getManagers();

      for (final manager in managers) {
        if (manager.pinHash == null) continue;
        final isValid = await _employeesDao.verifyPIN(manager.id, pin);
        if (isValid) {
          return manager.id;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// 계정 잠금 여부 확인
  bool _isLocked(int employeeId) {
    final lockoutTime = _lockoutUntil[employeeId];
    if (lockoutTime == null) return false;
    return DateTime.now().isBefore(lockoutTime);
  }

  /// 에러 초기화
  void clearError() {
    state = state.copyWith(error: () => null);
  }
}

// ============================================================
// Providers
// ============================================================

/// EmployeesDao Provider
final employeesDaoProvider = Provider<EmployeesDao>((ref) {
  final db = ref.watch(databaseProvider);
  return db.employeesDao;
});

/// Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final employeesDao = ref.watch(employeesDaoProvider);
  return AuthNotifier(employeesDao, ref);
});

/// 현재 세션 Provider (편의용)
final currentSessionProvider = Provider<Session?>((ref) {
  return ref.watch(authProvider).session;
});

/// 인증 여부 Provider (편의용)
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

// ============================================================
// 레거시 호환성 (기존 코드와의 호환)
// ============================================================

/// 현재 로그인한 직원 (레거시 호환)
final currentEmployeeProvider = Provider<Employee?>((ref) {
  final session = ref.watch(currentSessionProvider);
  if (session == null) return null;

  // Session에서 Employee 객체 생성
  return Employee(
    id: session.employeeId,
    name: session.employeeName,
    pin: '', // PIN은 보안상 노출하지 않음
    role: session.role,
    isActive: true,
    createdAt: DateTime.now(),
    pinHash: null,
    defaultRole: 'STAFF', // 기본값
    storeScope: 'OWN_STORE', // 기본값
    primaryStoreId: null,
  );
});

/// 활성 직원 목록 조회
final activeEmployeesProvider = FutureProvider<List<Employee>>((ref) async {
  final db = ref.watch(databaseProvider);
  return await db.employeesDao.getAllEmployees();
});
