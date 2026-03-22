import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/delivery_orders_providers.dart';
import '../../data/models/delivery_order.dart';
import '../../domain/enums/delivery_status.dart';
import 'platform_badge.dart';
import '../../../../l10n/app_localizations.dart';

/// Full-detail modal for a delivery order.
/// Shows: platform badge, customer info, address, driver info, item list,
/// status timeline, special instructions, totals.
class DeliveryOrderDetailModal extends ConsumerWidget {
  final DeliveryOrder order;

  const DeliveryOrderDetailModal({super.key, required this.order});

  static Future<void> show(BuildContext context, DeliveryOrder order) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DeliveryOrderDetailModal(order: order),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  PlatformBadge(platform: order.platform),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '#${order.platformOrderId}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: order.status.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: order.status.color),
                    ),
                    child: Text(
                      _statusLabel(l10n, order.status),
                      style: TextStyle(
                        color: order.status.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 20),

            // Scrollable body
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // ── Customer info ──
                  _SectionTitle(title: l10n.deliveryCustomer),
                  _InfoRow(
                    icon: Icons.person,
                    label: order.customerName,
                  ),
                  if (order.customerPhone != null)
                    _InfoRow(
                      icon: Icons.phone,
                      label: order.customerPhone!,
                    ),

                  // ── Delivery address ──
                  if (order.deliveryAddress != null) ...[
                    const SizedBox(height: 12),
                    _SectionTitle(title: l10n.deliveryAddress),
                    _InfoRow(
                      icon: Icons.location_on,
                      label: order.deliveryAddress!,
                    ),
                  ],

                  // ── Driver info ──
                  if (order.driverInfo != null) ...[
                    const SizedBox(height: 12),
                    _SectionTitle(title: l10n.deliveryDriver),
                    _InfoRow(
                      icon: Icons.delivery_dining,
                      label: order.driverInfo!.name,
                    ),
                    _InfoRow(
                      icon: Icons.phone,
                      label: order.driverInfo!.phone,
                    ),
                    _InfoRow(
                      icon: Icons.directions_car,
                      label: order.driverInfo!.licensePlate,
                    ),
                  ],

                  // ── Estimated pickup ──
                  if (order.estimatedPickupTime != null) ...[
                    const SizedBox(height: 12),
                    _SectionTitle(title: l10n.deliveryEstimatedPickup),
                    _InfoRow(
                      icon: Icons.access_time,
                      label: DateFormat('HH:mm')
                          .format(order.estimatedPickupTime!),
                    ),
                  ],

                  // ── Items ──
                  const SizedBox(height: 12),
                  _SectionTitle(
                    title: 'Items (${order.totalQuantity})',
                  ),
                  ...order.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(item.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                                if (item.notes != null &&
                                    item.notes!.isNotEmpty)
                                  Text(
                                    item.notes!,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            _formatAmount(item.price * item.quantity),
                            style: const TextStyle(
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 20),

                  // ── Total ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.deliveryTotalAmount,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        _formatAmount(order.totalAmount),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black),
                      ),
                    ],
                  ),

                  // ── Special instructions ──
                  if (order.specialInstructions != null &&
                      order.specialInstructions!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.sticky_note_2,
                              color: Colors.amber, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              order.specialInstructions!,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // ── Timeline ──
                  _SectionTitle(title: 'Timeline'),
                  _TimelineRow(
                    label: l10n.deliveryStatusNew,
                    time: order.createdAt,
                    isDone: true,
                    color: DeliveryStatus.newOrder.color,
                  ),
                  _TimelineRow(
                    label: l10n.deliveryStatusAccepted,
                    time: order.status.index >=
                            DeliveryStatus.accepted.index
                        ? order.updatedAt
                        : null,
                    isDone: order.status.index >=
                        DeliveryStatus.accepted.index,
                    color: DeliveryStatus.accepted.color,
                  ),
                  _TimelineRow(
                    label: l10n.deliveryStatusPreparing,
                    time: order.status.index >=
                            DeliveryStatus.preparing.index
                        ? order.updatedAt
                        : null,
                    isDone: order.status.index >=
                        DeliveryStatus.preparing.index,
                    color: DeliveryStatus.preparing.color,
                  ),
                  _TimelineRow(
                    label: l10n.deliveryStatusReadyForPickup,
                    time: order.status.index >=
                            DeliveryStatus.readyForPickup.index
                        ? order.updatedAt
                        : null,
                    isDone: order.status.index >=
                        DeliveryStatus.readyForPickup.index,
                    color: DeliveryStatus.readyForPickup.color,
                  ),

                  // ── DEL-007: Cancel Order button ──
                  if (!order.status.isTerminal) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.cancel_outlined,
                          color: Colors.red),
                      label: Text(
                        l10n.cancelOrder,
                        style: const TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        minimumSize: const Size.fromHeight(44),
                      ),
                      onPressed: () => _confirmCancel(context, ref, l10n),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmCancel(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelOrder),
        content: Text(l10n.kdsCancelOrderConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.yes,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref
        .read(deliveryOrdersDaoProvider)
        .updateStatus(order.id, DeliveryStatus.cancelled.value);

    if (context.mounted) Navigator.pop(context);
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

  static String _formatAmount(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final DateTime? time;
  final bool isDone;
  final Color color;

  const _TimelineRow({
    required this.label,
    required this.time,
    required this.isDone,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isDone ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: isDone ? color : Colors.grey.shade300,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDone ? Colors.black87 : Colors.grey,
          ),
        ),
        if (time != null) ...[
          const Spacer(),
          Text(
            DateFormat('HH:mm').format(time!),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ],
    );
  }
}
