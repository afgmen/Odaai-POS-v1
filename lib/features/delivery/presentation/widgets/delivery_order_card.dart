import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/delivery_order.dart';
import '../../domain/enums/delivery_status.dart';
import '../../domain/services/delivery_service_provider.dart';
import 'platform_badge.dart';
import '../../../../l10n/app_localizations.dart';

/// Card showing platform badge, customer, items, status, timer, action buttons.
/// Flashes/highlights for NEW orders. Elapsed time color matches KDS pattern.
class DeliveryOrderCard extends ConsumerStatefulWidget {
  final DeliveryOrder order;
  final VoidCallback onTap;

  const DeliveryOrderCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  ConsumerState<DeliveryOrderCard> createState() => _DeliveryOrderCardState();
}

class _DeliveryOrderCardState extends ConsumerState<DeliveryOrderCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _flashController;
  Animation<double>? _flashAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.order.status == DeliveryStatus.newOrder) {
      _flashController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      )..repeat(reverse: true);
      _flashAnimation =
          Tween<double>(begin: 0.0, end: 0.12).animate(_flashController!);
    }
  }

  @override
  void dispose() {
    _flashController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final order = widget.order;
    final status = order.status;
    final statusColor = status.color;
    final elapsed = order.elapsedMinutes;

    Widget card = Card(
      elevation: status == DeliveryStatus.newOrder ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: status == DeliveryStatus.newOrder
            ? BorderSide(color: status.color, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: platform badge + order ID ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PlatformBadge(platform: order.platform, compact: true),
                  Text(
                    '#${order.platformOrderId.length > 8 ? order.platformOrderId.substring(order.platformOrderId.length - 8) : order.platformOrderId}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ── Customer name ──
              Text(
                order.customerName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // ── Items list ──
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ...order.items.take(3).map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'x${item.quantity}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (order.items.length > 3)
                      Text(
                        '+ ${order.items.length - 3} more',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Total + elapsed time ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatAmount(order.totalAmount),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _elapsedColor(elapsed),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '⏱ ${elapsed}m ago',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Status / action buttons ──
              _buildActionArea(context, ref, l10n, order, statusColor),
            ],
          ),
        ),
      ),
    );

    // Flash animation for NEW orders
    if (_flashAnimation != null) {
      return AnimatedBuilder(
        animation: _flashAnimation!,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: status.color.withValues(alpha: _flashAnimation!.value),
            ),
            child: child,
          );
        },
        child: card,
      );
    }

    return card;
  }

  Widget _buildActionArea(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    DeliveryOrder order,
    Color statusColor,
  ) {
    if (order.status == DeliveryStatus.newOrder) {
      // Accept + Reject buttons
      return Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _onAccept(context, ref, order),
              icon: const Icon(Icons.check, size: 16),
              label: Text(l10n.deliveryAccept),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 8),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _onReject(context, ref, l10n, order),
              icon: const Icon(Icons.close, size: 16),
              label: Text(l10n.deliveryReject),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 8),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      );
    }

    if (!order.status.isTerminal && order.status.nextStatus != null) {
      // Advance status button
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _onAdvance(context, ref, order),
          icon: Icon(order.status.nextStatus!.icon, size: 16),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _statusLabel(l10n, order.status),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward, size: 14),
            ],
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: statusColor,
            side: BorderSide(color: statusColor),
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      );
    }

    // Terminal status display only
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(order.status.icon, color: statusColor, size: 16),
          const SizedBox(width: 6),
          Text(
            _statusLabel(l10n, order.status),
            style: TextStyle(
                color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Actions
  // ──────────────────────────────────────────────

  Future<void> _onAccept(
      BuildContext context, WidgetRef ref, DeliveryOrder order) async {
    final service = ref.read(deliveryServiceProvider);
    final id = int.tryParse(order.id);
    if (id == null) return;
    await service.acceptOrder(id, order);
  }

  Future<void> _onReject(BuildContext context, WidgetRef ref,
      AppLocalizations l10n, DeliveryOrder order) async {
    final reason = await _showRejectDialog(context, l10n);
    if (reason == null || !context.mounted) return;

    final service = ref.read(deliveryServiceProvider);
    final id = int.tryParse(order.id);
    if (id == null) return;
    await service.rejectOrder(id, order, reason: reason);
  }

  Future<void> _onAdvance(
      BuildContext context, WidgetRef ref, DeliveryOrder order) async {
    final service = ref.read(deliveryServiceProvider);
    final id = int.tryParse(order.id);
    if (id == null) return;
    await service.advanceStatus(id, order);
  }

  Future<String?> _showRejectDialog(
      BuildContext context, AppLocalizations l10n) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deliveryReject),
        content: TextField(
          controller: controller,
          decoration:
              InputDecoration(labelText: l10n.deliveryRejectReason),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Helpers — same color logic as KDS OrderCard
  // ──────────────────────────────────────────────

  /// Simple amount formatter — shows thousands separator, no symbol.
  /// The currency symbol/conversion is handled at checkout; here we show
  /// the raw delivery platform amount for quick reference.
  String _formatAmount(double amount) {
    final intPart = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return intPart;
  }

  /// KDS-matching elapsed-time color coding.
  Color _elapsedColor(int minutes) {
    if (minutes >= 30) return Colors.red;
    if (minutes >= 20) return Colors.orange;
    if (minutes >= 10) return Colors.amber;
    return Colors.green;
  }

  String _statusLabel(AppLocalizations l10n, DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.newOrder:
        return l10n.deliveryStatusNew;
      case DeliveryStatus.accepted:
        return l10n.deliveryStatusAccepted;
      case DeliveryStatus.preparing:
        return l10n.deliveryStatusPreparing;
      case DeliveryStatus.readyForPickup:
        return l10n.deliveryStatusReadyForPickup;
      case DeliveryStatus.pickedUp:
        return l10n.deliveryStatusPickedUp;
      case DeliveryStatus.completed:
        return l10n.deliveryStatusCompleted;
      case DeliveryStatus.cancelled:
        return l10n.deliveryStatusCancelled;
    }
  }
}
