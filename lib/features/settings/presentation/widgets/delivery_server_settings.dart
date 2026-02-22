import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../delivery/domain/services/delivery_service_provider.dart';
import '../../../delivery/domain/services/websocket_service.dart';
import '../../../../l10n/app_localizations.dart';

/// Settings section for the delivery middleware server WebSocket connection.
/// Allows setting the server URL and shows live connection status.
class DeliveryServerSettings extends ConsumerStatefulWidget {
  const DeliveryServerSettings({super.key});

  @override
  ConsumerState<DeliveryServerSettings> createState() =>
      _DeliveryServerSettingsState();
}

class _DeliveryServerSettingsState
    extends ConsumerState<DeliveryServerSettings> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    final currentUrl = ref.read(middlewareUrlProvider);
    _urlController = TextEditingController(text: currentUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wsStatus = ref.watch(wsConnectionStatusProvider);

    final (statusColor, statusLabel, statusIcon) = switch (
        wsStatus.valueOrNull ?? WsConnectionStatus.disconnected) {
      WsConnectionStatus.connected => (
          Colors.green,
          l10n.deliveryConnected,
          Icons.circle,
        ),
      WsConnectionStatus.connecting => (
          Colors.orange,
          'Connecting...',
          Icons.circle,
        ),
      WsConnectionStatus.disconnected => (
          Colors.red,
          l10n.deliveryDisconnected,
          Icons.circle,
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Connection status ──────────────────────────────────
        ListTile(
          leading: Icon(statusIcon, color: statusColor, size: 18),
          title: Text(l10n.deliveryConnectionStatus),
          subtitle: Text(
            statusLabel,
            style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
          ),
          trailing: TextButton.icon(
            onPressed: () {
              final ws = ref.read(deliveryWebSocketServiceProvider);
              ws.disconnect();
              ws.connect();
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reconnect'),
          ),
        ),

        // ── Server URL input ───────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Middleware Server URL',
                    hintText: 'ws://localhost:3000',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                    helperText:
                        'WebSocket URL of the Odaai delivery middleware server',
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _applyUrl(context),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _applyUrl(context),
                child: const Text('Apply'),
              ),
            ],
          ),
        ),

        // ── Reset to default ───────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextButton(
            onPressed: () {
              ref.read(middlewareUrlProvider.notifier).reset();
              _urlController.text = 'ws://localhost:3000';
              _showSnackBar(context, 'Reset to default URL');
            },
            child: const Text('Reset to default'),
          ),
        ),
      ],
    );
  }

  void _applyUrl(BuildContext context) {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    // Basic validation
    if (!url.startsWith('ws://') && !url.startsWith('wss://')) {
      _showSnackBar(context, 'URL must start with ws:// or wss://');
      return;
    }

    ref.read(middlewareUrlProvider.notifier).setUrl(url);
    _showSnackBar(context, 'Server URL updated');

    // Update the WS service
    ref.read(deliveryWebSocketServiceProvider).updateServerUrl(url);
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
