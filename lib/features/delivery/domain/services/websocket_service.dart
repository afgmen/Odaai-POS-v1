import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../data/models/delivery_order.dart';

/// WebSocket connection status.
enum WsConnectionStatus { disconnected, connecting, connected }

/// WebSocket client that connects to the Odaai delivery middleware server.
///
/// Listens for incoming order events and sends commands (accept, reject,
/// status update) back to the server.
///
/// Auto-reconnects with exponential backoff on connection loss.
class DeliveryWebSocketService {
  DeliveryWebSocketService({String? serverUrl})
      : _serverUrl = serverUrl ?? 'ws://localhost:3000';

  String _serverUrl;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  // Reconnect state
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  static const int _maxReconnectDelay = 30; // seconds

  // Status stream
  final _statusController =
      StreamController<WsConnectionStatus>.broadcast();
  WsConnectionStatus _status = WsConnectionStatus.disconnected;

  // Incoming order event streams
  final _newOrderController =
      StreamController<DeliveryOrder>.broadcast();
  final _orderUpdatedController =
      StreamController<DeliveryOrder>.broadcast();
  final _driverAssignedController =
      StreamController<({String orderId, DeliveryDriverInfo driver})>.broadcast();
  final _orderCancelledController =
      StreamController<({String orderId, String reason})>.broadcast();

  // ──────────────────────────────────────────────
  // Public streams
  // ──────────────────────────────────────────────

  Stream<WsConnectionStatus> get statusStream => _statusController.stream;
  WsConnectionStatus get status => _status;

  Stream<DeliveryOrder> get newOrderStream => _newOrderController.stream;
  Stream<DeliveryOrder> get orderUpdatedStream =>
      _orderUpdatedController.stream;
  Stream<({String orderId, DeliveryDriverInfo driver})> get driverAssignedStream =>
      _driverAssignedController.stream;
  Stream<({String orderId, String reason})> get orderCancelledStream =>
      _orderCancelledController.stream;

  // ──────────────────────────────────────────────
  // Connection lifecycle
  // ──────────────────────────────────────────────

  void updateServerUrl(String url) {
    _serverUrl = url;
    if (_status == WsConnectionStatus.connected) {
      disconnect();
      connect();
    }
  }

  void connect() {
    if (_status == WsConnectionStatus.connecting ||
        _status == WsConnectionStatus.connected) {
      return;
    }

    _setStatus(WsConnectionStatus.connecting);
    debugPrint('[DeliveryWS] Connecting to $_serverUrl...');

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_serverUrl));
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
      // We won't know if the connection succeeded until we receive a message,
      // but set as connected optimistically (channel throws on bad URI).
      _setStatus(WsConnectionStatus.connected);
      _reconnectAttempt = 0;
    } catch (e) {
      debugPrint('[DeliveryWS] Connection error: $e');
      _setStatus(WsConnectionStatus.disconnected);
      _scheduleReconnect();
    }
  }

  void disconnect() {
    _cancelReconnect();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _setStatus(WsConnectionStatus.disconnected);
    debugPrint('[DeliveryWS] Disconnected');
  }

  void dispose() {
    disconnect();
    _statusController.close();
    _newOrderController.close();
    _orderUpdatedController.close();
    _driverAssignedController.close();
    _orderCancelledController.close();
  }

  // ──────────────────────────────────────────────
  // Commands → server
  // ──────────────────────────────────────────────

  void acceptOrder(String orderId) {
    _send({'type': 'ACCEPT_ORDER', 'orderId': orderId});
  }

  void rejectOrder(String orderId, {String? reason}) {
    _send({
      'type': 'REJECT_ORDER',
      'orderId': orderId,
      'reason': reason ?? 'Rejected by merchant',
    });
  }

  void updateStatus(String orderId, String status) {
    _send({'type': 'UPDATE_STATUS', 'orderId': orderId, 'status': status});
  }

  /// Called when a KDS order linked to a delivery order changes status.
  /// [deliveryOrderId] is the delivery order's internal id (from the server).
  /// [kdsStatus] is the KDS OrderStatus value (e.g. 'PREPARING', 'READY', 'SERVED').
  void notifyKdsStatusUpdate(String deliveryOrderId, String kdsStatus) {
    _send({
      'type': 'KDS_STATUS_UPDATE',
      'orderId': deliveryOrderId,
      'kdsStatus': kdsStatus,
    });
  }

  // ──────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────

  void _send(Map<String, dynamic> message) {
    if (_status != WsConnectionStatus.connected || _channel == null) {
      debugPrint('[DeliveryWS] Cannot send — not connected');
      return;
    }
    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      debugPrint('[DeliveryWS] Send error: $e');
    }
  }

  void _onMessage(dynamic raw) {
    Map<String, dynamic> message;
    try {
      message = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[DeliveryWS] Invalid JSON: $e');
      return;
    }

    final type = message['type'] as String?;
    debugPrint('[DeliveryWS] Received: $type');

    switch (type) {
      case 'CONNECTED':
        _setStatus(WsConnectionStatus.connected);
        _reconnectAttempt = 0;
        break;

      case 'NEW_ORDER':
        try {
          final order = DeliveryOrder.fromJson(
              message['order'] as Map<String, dynamic>);
          _newOrderController.add(order);
        } catch (e) {
          debugPrint('[DeliveryWS] NEW_ORDER parse error: $e');
        }
        break;

      case 'ORDER_UPDATED':
        try {
          final order = DeliveryOrder.fromJson(
              message['order'] as Map<String, dynamic>);
          _orderUpdatedController.add(order);
        } catch (e) {
          debugPrint('[DeliveryWS] ORDER_UPDATED parse error: $e');
        }
        break;

      case 'DRIVER_ASSIGNED':
        try {
          final orderId = message['orderId'] as String;
          final driver = DeliveryDriverInfo.fromJson(
              message['driverInfo'] as Map<String, dynamic>);
          _driverAssignedController.add((orderId: orderId, driver: driver));
        } catch (e) {
          debugPrint('[DeliveryWS] DRIVER_ASSIGNED parse error: $e');
        }
        break;

      case 'ORDER_CANCELLED':
        try {
          final orderId = message['orderId'] as String;
          final reason = message['reason'] as String? ?? 'Cancelled';
          _orderCancelledController.add((orderId: orderId, reason: reason));
        } catch (e) {
          debugPrint('[DeliveryWS] ORDER_CANCELLED parse error: $e');
        }
        break;

      case 'ERROR':
        debugPrint('[DeliveryWS] Server error: ${message['message']}');
        break;
    }
  }

  void _onError(Object error) {
    debugPrint('[DeliveryWS] Stream error: $error');
    _setStatus(WsConnectionStatus.disconnected);
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('[DeliveryWS] Connection closed');
    _setStatus(WsConnectionStatus.disconnected);
    _scheduleReconnect();
  }

  void _setStatus(WsConnectionStatus status) {
    _status = status;
    _statusController.add(status);
  }

  void _scheduleReconnect() {
    _cancelReconnect();
    _reconnectAttempt++;
    final delaySecs =
        (_reconnectAttempt * 2).clamp(1, _maxReconnectDelay);
    debugPrint(
        '[DeliveryWS] Reconnecting in ${delaySecs}s (attempt $_reconnectAttempt)...');
    _reconnectTimer = Timer(Duration(seconds: delaySecs), connect);
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }
}
