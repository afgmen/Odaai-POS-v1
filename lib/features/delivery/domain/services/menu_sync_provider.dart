import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/menu_sync_result.dart';
import 'delivery_service_provider.dart';
import 'menu_sync_service.dart';

// ──────────────────────────────────────────────
// Service provider
// ──────────────────────────────────────────────

final menuSyncServiceProvider = Provider<MenuSyncService>((ref) {
  final url = ref.watch(middlewareUrlProvider);
  return MenuSyncService(middlewareUrl: url);
});

// ──────────────────────────────────────────────
// Sync state — AsyncNotifier
// ──────────────────────────────────────────────

/// Tracks the in-progress / last-result state of a menu sync.
///
/// Usage:
/// ```dart
/// final state = ref.watch(menuSyncNotifierProvider);
/// ref.read(menuSyncNotifierProvider.notifier).sync(menuData);
/// ```
class MenuSyncNotifier extends AsyncNotifier<MenuSyncResult?> {
  @override
  Future<MenuSyncResult?> build() async => null; // idle

  Future<void> sync(Map<String, dynamic> menuData) async {
    state = const AsyncLoading();
    final service = ref.read(menuSyncServiceProvider);
    state = await AsyncValue.guard(() => service.syncMenu(menuData));
  }
}

final menuSyncNotifierProvider =
    AsyncNotifierProvider<MenuSyncNotifier, MenuSyncResult?>(
  MenuSyncNotifier.new,
);
