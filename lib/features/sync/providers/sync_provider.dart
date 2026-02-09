import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/database_providers.dart';
import '../services/mock_api_client.dart';
import '../services/sync_service.dart';

/// ── 연결 상태 Provider ────────────────────────────
/// 실시간 네트워크 연결 상태 스트림
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    return results.any((r) => r != ConnectivityResult.none);
  });
});

/// ── Mock API 클라이언트 Provider ───────────────────
final mockApiClientProvider = Provider<MockApiClient>((ref) {
  return MockApiClient(successRate: 0.95, latencyMs: 300);
});

/// ── Sync 서비스 Provider ──────────────────────────
final syncServiceProvider = Provider<SyncService>((ref) {
  final syncDao = ref.watch(syncDaoProvider);
  final apiClient = ref.watch(mockApiClientProvider);
  return SyncService(syncDao: syncDao, apiClient: apiClient);
});

/// ── 동기화 상태 Provider ──────────────────────────
final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, SyncState>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  final isOnline = ref.watch(connectivityProvider).value ?? false;
  return SyncStatusNotifier(syncService: syncService, isOnline: isOnline);
});

/// 동기화 상태 모델
class SyncState {
  final SyncStatus status;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final String? lastError;

  const SyncState({
    this.status = SyncStatus.idle,
    this.pendingCount = 0,
    this.lastSyncedAt,
    this.lastError,
  });

  SyncState copyWith({
    SyncStatus? status,
    int? pendingCount,
    DateTime? lastSyncedAt,
    String? lastError,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastError: lastError,
    );
  }
}

/// 동기화 상태 Notifier
class SyncStatusNotifier extends StateNotifier<SyncState> {
  final SyncService syncService;
  final bool isOnline;
  Timer? _autoSyncTimer;

  SyncStatusNotifier({
    required this.syncService,
    required this.isOnline,
  }) : super(SyncState(
          status: isOnline ? SyncStatus.idle : SyncStatus.offline,
        )) {
    _init();
  }

  Future<void> _init() async {
    await refreshPendingCount();

    // 온라인이면 자동 동기화 시작 (5분 간격)
    if (isOnline) {
      _startAutoSync();
    }
  }

  /// 대기 중인 항목 수 갱신
  Future<void> refreshPendingCount() async {
    final count = await syncService.getPendingCount();
    state = state.copyWith(pendingCount: count);
  }

  /// 수동 동기화 실행
  Future<void> syncNow() async {
    if (!isOnline) {
      state = state.copyWith(
        status: SyncStatus.offline,
        lastError: '오프라인 상태입니다',
      );
      return;
    }

    state = state.copyWith(status: SyncStatus.syncing, lastError: null);

    try {
      final result = await syncService.syncAll();

      if (result.totalItems == 0) {
        state = state.copyWith(
          status: SyncStatus.success,
          pendingCount: 0,
          lastSyncedAt: result.syncedAt,
        );
      } else if (result.isFullySuccessful) {
        state = state.copyWith(
          status: SyncStatus.success,
          pendingCount: 0,
          lastSyncedAt: result.syncedAt,
        );
      } else {
        state = state.copyWith(
          status: SyncStatus.error,
          pendingCount: result.failedItems,
          lastSyncedAt: result.syncedAt,
          lastError: result.errors.isNotEmpty ? result.errors.first : null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        lastError: e.toString(),
      );
    }
  }

  /// 자동 동기화 타이머 시작
  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (state.pendingCount > 0) {
        syncNow();
      }
    });
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}
