import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/services/delivery_service_provider.dart';
import '../providers/platform_status_provider.dart';

/// Delivery platform management settings screen.
///
/// Shows:
///   - List of registered delivery platform connectors
///   - Active / inactive status indicator
///   - Test connection button per platform
///   - Server URL configuration (reuses middlewareUrlProvider)
///   - Last known sync info
class DeliveryPlatformSettingsScreen extends ConsumerStatefulWidget {
  const DeliveryPlatformSettingsScreen({super.key});

  @override
  ConsumerState<DeliveryPlatformSettingsScreen> createState() =>
      _DeliveryPlatformSettingsScreenState();
}

class _DeliveryPlatformSettingsScreenState
    extends ConsumerState<DeliveryPlatformSettingsScreen> {
  /// Tracks pending test-connection results per platform name.
  final Map<String, AsyncValue<ConnectionTestResult>> _testResults = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final platformsAsync = ref.watch(platformStatusProvider);
    final wsUrl = ref.watch(middlewareUrlProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        title: Text(
          l10n.deliveryPlatformSettings,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.divider),
        ),
        actions: [
          // Refresh platforms list
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.retry,
            onPressed: () => ref.invalidate(platformStatusProvider),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Platform list ──────────────────────────────
          _SectionHeader(
            title: l10n.deliveryPlatformSettings,
            icon: Icons.storefront_outlined,
          ),
          const SizedBox(height: 8),

          platformsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => _ErrorCard(
              message: err.toString(),
              onRetry: () => ref.invalidate(platformStatusProvider),
            ),
            data: (platforms) {
              if (platforms.isEmpty) {
                return _SettingsCard(children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No platforms registered.\nCheck server connection.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                ]);
              }

              return _SettingsCard(
                children: [
                  for (int i = 0; i < platforms.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _PlatformTile(
                      platform: platforms[i],
                      testResult: _testResults[platforms[i].name],
                      onTest: () => _runTest(platforms[i].name, wsUrl),
                    ),
                  ],
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // ── Server URL ─────────────────────────────────
          const _SectionHeader(
            title: 'Server Configuration',
            icon: Icons.dns_outlined,
          ),
          const SizedBox(height: 8),
          const _SettingsCard(children: [
            _ServerUrlTile(),
          ]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _runTest(String platformName, String wsUrl) async {
    setState(() {
      _testResults[platformName] = const AsyncLoading();
    });
    final result = await testPlatformConnection(wsUrl, platformName);
    if (mounted) {
      setState(() {
        _testResults[platformName] = AsyncData(result);
      });
    }
  }
}

// ──────────────────────────────────────────────
// Platform tile
// ──────────────────────────────────────────────

class _PlatformTile extends ConsumerWidget {
  final PlatformStatus platform;
  final AsyncValue<ConnectionTestResult>? testResult;
  final VoidCallback onTest;

  const _PlatformTile({
    required this.platform,
    required this.testResult,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final (statusColor, statusLabel) = platform.active
        ? (Colors.green, l10n.deliveryPlatformActive)
        : (Colors.orange, l10n.deliveryPlatformNotConfigured);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.delivery_dining,
                color: statusColor,
                size: 22,
              ),
            ),
            title: Text(
              platform.displayName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: _TestButton(
              testResult: testResult,
              onTest: onTest,
              l10n: l10n,
            ),
          ),

          // Test result feedback
          if (testResult != null && testResult is AsyncData) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: _TestResultBanner(
                result: (testResult as AsyncData<ConnectionTestResult>).value,
                l10n: l10n,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TestButton extends StatelessWidget {
  final AsyncValue<ConnectionTestResult>? testResult;
  final VoidCallback onTest;
  final AppLocalizations l10n;

  const _TestButton({
    required this.testResult,
    required this.onTest,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    if (testResult is AsyncLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return TextButton.icon(
      onPressed: onTest,
      icon: const Icon(Icons.network_check, size: 16),
      label: Text(l10n.deliveryTestConnection, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _TestResultBanner extends StatelessWidget {
  final ConnectionTestResult result;
  final AppLocalizations l10n;

  const _TestResultBanner({required this.result, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: result.ok
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            result.ok ? Icons.check_circle_outline : Icons.error_outline,
            size: 16,
            color: result.ok ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              result.ok
                  ? '${result.message} (${result.latencyMs}ms)'
                  : result.message,
              style: TextStyle(
                fontSize: 12,
                color: result.ok ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Server URL tile (inline edit)
// ──────────────────────────────────────────────

class _ServerUrlTile extends ConsumerStatefulWidget {
  const _ServerUrlTile();

  @override
  ConsumerState<_ServerUrlTile> createState() => _ServerUrlTileState();
}

class _ServerUrlTileState extends ConsumerState<_ServerUrlTile> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(middlewareUrlProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Middleware Server URL',
                hintText: 'ws://localhost:3000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link, size: 20),
                helperText: 'WebSocket URL — ws:// or wss://',
                isDense: true,
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _apply(context),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => _apply(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _apply(BuildContext context) {
    final url = _controller.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('ws://') && !url.startsWith('wss://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL must start with ws:// or wss://')),
      );
      return;
    }
    ref.read(middlewareUrlProvider.notifier).setUrl(url);
    ref.read(deliveryWebSocketServiceProvider).updateServerUrl(url);
    ref.invalidate(platformStatusProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Server URL updated'),
          duration: Duration(seconds: 2)),
    );
  }
}

// ──────────────────────────────────────────────
// Shared widgets
// ──────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(children: children),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Failed to load platforms: $message',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
