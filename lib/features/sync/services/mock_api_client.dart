import 'dart:math';

/// Mock API 클라이언트
/// 실제 백엔드가 없는 상태에서 동기화 플로우를 시뮬레이션
/// 나중에 실제 API로 교체 가능
class MockApiClient {
  final _random = Random();

  /// 성공률 (0.0 ~ 1.0) — 테스트용, 실제로는 네트워크 상황에 따라 달라짐
  final double successRate;

  /// 응답 지연 (밀리초)
  final int latencyMs;

  MockApiClient({
    this.successRate = 0.95,
    this.latencyMs = 300,
  });

  /// 매출 데이터 동기화 (업로드)
  Future<ApiResponse> syncSale(Map<String, dynamic> saleData) async {
    await _simulateLatency();
    if (_shouldSucceed()) {
      return ApiResponse.success(data: {
        'serverId': 'srv_${DateTime.now().millisecondsSinceEpoch}',
        'syncedAt': DateTime.now().toIso8601String(),
      });
    }
    return ApiResponse.error(message: '서버 연결 실패. 나중에 다시 시도합니다.');
  }

  /// 상품 데이터 동기화 (업로드)
  Future<ApiResponse> syncProduct(Map<String, dynamic> productData) async {
    await _simulateLatency();
    if (_shouldSucceed()) {
      return ApiResponse.success(data: {
        'serverId': 'srv_prd_${DateTime.now().millisecondsSinceEpoch}',
        'syncedAt': DateTime.now().toIso8601String(),
      });
    }
    return ApiResponse.error(message: '상품 동기화 실패');
  }

  /// 직원 데이터 동기화 (업로드)
  Future<ApiResponse> syncEmployee(Map<String, dynamic> employeeData) async {
    await _simulateLatency();
    if (_shouldSucceed()) {
      return ApiResponse.success(data: {
        'serverId': 'srv_emp_${DateTime.now().millisecondsSinceEpoch}',
        'syncedAt': DateTime.now().toIso8601String(),
      });
    }
    return ApiResponse.error(message: '직원 동기화 실패');
  }

  /// 서버 상태 확인 (ping)
  Future<bool> ping() async {
    await _simulateLatency();
    return _shouldSucceed();
  }

  /// 서버에서 최신 데이터 가져오기 (다운로드)
  Future<ApiResponse> fetchUpdates({required DateTime since}) async {
    await _simulateLatency();
    if (_shouldSucceed()) {
      // Mock: 빈 업데이트 (서버 변경사항 없음)
      return ApiResponse.success(data: {
        'products': <dynamic>[],
        'employees': <dynamic>[],
        'lastSync': DateTime.now().toIso8601String(),
      });
    }
    return ApiResponse.error(message: '업데이트 가져오기 실패');
  }

  // ── 내부 유틸리티 ──────────────────────

  Future<void> _simulateLatency() async {
    final delay = latencyMs + _random.nextInt(200);
    await Future.delayed(Duration(milliseconds: delay));
  }

  bool _shouldSucceed() => _random.nextDouble() < successRate;
}

/// API 응답 모델
class ApiResponse {
  final bool success;
  final Map<String, dynamic>? data;
  final String? errorMessage;

  const ApiResponse._({
    required this.success,
    this.data,
    this.errorMessage,
  });

  factory ApiResponse.success({Map<String, dynamic>? data}) =>
      ApiResponse._(success: true, data: data);

  factory ApiResponse.error({required String message}) =>
      ApiResponse._(success: false, errorMessage: message);
}
