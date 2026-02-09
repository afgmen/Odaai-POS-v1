import 'dart:convert';

import '../../../database/daos/sync_dao.dart';
import 'mock_api_client.dart';

/// 동기화 상태
enum SyncStatus {
  idle,       // 대기 중
  syncing,    // 동기화 중
  success,    // 완료
  error,      // 오류
  offline,    // 오프라인
}

/// 동기화 결과
class SyncResult {
  final int totalItems;
  final int syncedItems;
  final int failedItems;
  final List<String> errors;
  final DateTime syncedAt;

  const SyncResult({
    required this.totalItems,
    required this.syncedItems,
    required this.failedItems,
    required this.errors,
    required this.syncedAt,
  });

  bool get isFullySuccessful => failedItems == 0 && totalItems > 0;

  @override
  String toString() =>
      'SyncResult(total: $totalItems, synced: $syncedItems, failed: $failedItems)';
}

/// 동기화 서비스
/// SyncQueue의 pending 항목을 가져와 Mock API로 전송
class SyncService {
  final SyncDao _syncDao;
  final MockApiClient _apiClient;

  SyncService({
    required SyncDao syncDao,
    MockApiClient? apiClient,
  })  : _syncDao = syncDao,
        _apiClient = apiClient ?? MockApiClient();

  /// 대기 중인 항목 모두 동기화
  Future<SyncResult> syncAll() async {
    final pendingItems = await _syncDao.getPendingItems();

    if (pendingItems.isEmpty) {
      return SyncResult(
        totalItems: 0,
        syncedItems: 0,
        failedItems: 0,
        errors: [],
        syncedAt: DateTime.now(),
      );
    }

    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final item in pendingItems) {
      try {
        final payload = jsonDecode(item.payload) as Map<String, dynamic>;
        final response = await _syncEntity(item.entityType, payload);

        if (response.success) {
          await _syncDao.markSynced(item.id);
          synced++;
        } else {
          await _syncDao.markFailed(item.id);
          failed++;
          errors.add('${item.entityType}#${item.entityId}: ${response.errorMessage}');
        }
      } catch (e) {
        await _syncDao.markFailed(item.id);
        failed++;
        errors.add('${item.entityType}#${item.entityId}: $e');
      }
    }

    // 성공 항목 정리
    if (synced > 0) {
      await _syncDao.clearSynced();
    }

    return SyncResult(
      totalItems: pendingItems.length,
      syncedItems: synced,
      failedItems: failed,
      errors: errors,
      syncedAt: DateTime.now(),
    );
  }

  /// 대기 중인 항목 수 조회
  Future<int> getPendingCount() async {
    final items = await _syncDao.getPendingItems();
    return items.length;
  }

  /// 서버 연결 확인
  Future<bool> checkServerConnection() async {
    try {
      return await _apiClient.ping();
    } catch (_) {
      return false;
    }
  }

  /// 엔티티 타입별 API 호출
  Future<ApiResponse> _syncEntity(String entityType, Map<String, dynamic> payload) {
    return switch (entityType) {
      'sale' => _apiClient.syncSale(payload),
      'product' => _apiClient.syncProduct(payload),
      'employee' => _apiClient.syncEmployee(payload),
      _ => Future.value(ApiResponse.error(message: '알 수 없는 엔티티 타입: $entityType')),
    };
  }
}
