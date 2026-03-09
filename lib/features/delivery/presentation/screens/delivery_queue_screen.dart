import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/delivery_service_provider.dart';
import '../../domain/services/websocket_service.dart';
import '../providers/delivery_screen_provider.dart';
import '../widgets/delivery_filter_tabs.dart';
import '../widgets/delivery_order_card.dart';
import '../widgets/delivery_order_detail_modal.dart';
import '../widgets/delivery_stats_header.dart';
import '../../../../l10n/app_localizations.dart';
import 'manual_delivery_form_screen.dart';
import '../../../auth/providers/rbac_providers.dart';

/// Main delivery management screen.
///
/// Layout:
///   AppBar: "Delivery Orders" + New/Active badges + WS status dot
///   Stats header row
///   Platform filter tabs
///   Order grid (responsive: 1 col mobile, 2-3 col tablet)
class DeliveryQueueScreen extends ConsumerWidget {
  const DeliveryQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final newCount = ref.watch(newOrderCountProvider);
    final activeCount = ref.watch(activeOrderCountProvider);
    final wsStatus = ref.watch(wsConnectionStatusProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Row(
          children: [
            Text(l10n.deliveryTitle),
            const SizedBox(width: 8),
            if (newCount > 0)
              _CountBadge(
                label: l10n.deliveryNewOrders,
                count: newCount,
                color: const Color(0xFF2196F3),
              ),
            const SizedBox(width: 4),
            if (activeCount > 0)
              _CountBadge(
                label: l10n.deliveryActiveOrders,
                count: activeCount,
                color: const Color(0xFFFF9800),
              ),
          ],
        ),
        centerTitle: false,
        actions: [
          // WebSocket status indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _WsStatusDot(wsStatus: wsStatus),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.deliveryManualOrderCreate,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ManualDeliveryFormScreen(),
          ),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const DeliveryStatsHeader(),
          const DeliveryFilterTabs(),
          const Divider(height: 1),
          Expanded(child: _OrderGrid()),
        ],
      ),
    );
  }
}

class _OrderGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ordersAsync = ref.watch(filteredDeliveryOrdersProvider);

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (orders) {
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delivery_dining,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  l10n.deliveryNoOrders,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        final width = MediaQuery.of(context).size.width;
        final crossAxisCount = width >= 1024 ? 3 : (width >= 600 ? 2 : 1);

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: crossAxisCount == 1 ? 2.2 : 1.4,
          ),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return DeliveryOrderCard(
              key: ValueKey(order.id),
              order: order,
              onTap: () => DeliveryOrderDetailModal.show(context, order),
            );
          },
        );
      },
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _WsStatusDot extends StatelessWidget {
  final AsyncValue<WsConnectionStatus> wsStatus;

  const _WsStatusDot({required this.wsStatus});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final status =
        wsStatus.valueOrNull ?? WsConnectionStatus.disconnected;

    final (color, label) = switch (status) {
      WsConnectionStatus.connected => (
          Colors.green,
          l10n.deliveryConnected
        ),
      WsConnectionStatus.connecting => (Colors.orange, 'Connecting...'),
      WsConnectionStatus.disconnected => (
          Colors.red,
          l10n.deliveryDisconnected
        ),
    };

    return Tooltip(
      message:
          '${l10n.deliveryConnectionStatus}: $label',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}
