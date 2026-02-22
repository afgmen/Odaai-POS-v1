import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/delivery_orders_providers.dart';
import 'delivery_service.dart';
import 'websocket_service.dart';
import '../../../kds/domain/services/kitchen_service_provider.dart';
import '../../../user_guide/presentation/providers/tutorial_preference_provider.dart';

// ──────────────────────────────────────────────
// Middleware server URL (persisted in SharedPreferences)
// ──────────────────────────────────────────────

const _kMiddlewareUrlKey = 'delivery_middleware_url';
const _kDefaultMiddlewareUrl = 'ws://localhost:3000';

final middlewareUrlProvider =
    StateNotifierProvider<MiddlewareUrlNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return MiddlewareUrlNotifier(prefs);
});

class MiddlewareUrlNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;

  MiddlewareUrlNotifier(this._prefs)
      : super(
          _prefs.getString(_kMiddlewareUrlKey) ?? _kDefaultMiddlewareUrl,
        );

  Future<void> setUrl(String url) async {
    state = url;
    await _prefs.setString(_kMiddlewareUrlKey, url);
  }

  void reset() {
    setUrl(_kDefaultMiddlewareUrl);
  }
}

// ──────────────────────────────────────────────
// WebSocket service (singleton, auto-connects)
// ──────────────────────────────────────────────

final deliveryWebSocketServiceProvider =
    Provider<DeliveryWebSocketService>((ref) {
  final url = ref.watch(middlewareUrlProvider);
  final service = DeliveryWebSocketService(serverUrl: url);
  service.connect();
  ref.onDispose(service.dispose);
  return service;
});

/// Stream of WebSocket connection status.
final wsConnectionStatusProvider =
    StreamProvider<WsConnectionStatus>((ref) {
  final ws = ref.watch(deliveryWebSocketServiceProvider);
  return ws.statusStream;
});

// ──────────────────────────────────────────────
// Delivery service
// ──────────────────────────────────────────────

final deliveryServiceProvider = Provider<DeliveryService>((ref) {
  final repo = ref.watch(deliveryOrdersRepositoryProvider);
  final ws = ref.watch(deliveryWebSocketServiceProvider);
  final kitchen = ref.watch(kitchenServiceProvider);

  final service = DeliveryService(
    repository: repo,
    wsService: ws,
    kitchenService: kitchen,
  );

  ref.onDispose(service.dispose);
  return service;
});
