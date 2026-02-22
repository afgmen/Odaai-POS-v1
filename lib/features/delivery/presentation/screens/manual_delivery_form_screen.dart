import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart' hide DeliveryOrder;
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/database_providers.dart';
import '../../data/delivery_orders_providers.dart';
import '../../data/models/delivery_order.dart';
import '../../domain/enums/delivery_platform.dart';
import '../../domain/enums/delivery_status.dart';
import '../../domain/services/delivery_service_provider.dart';

/// Screen for manually creating a delivery order.
///
/// Staff use this for phone orders, walk-in delivery requests, or platforms
/// without a direct API integration. The created order appears in the delivery
/// queue alongside platform orders and follows the same status flow.
class ManualDeliveryFormScreen extends ConsumerStatefulWidget {
  const ManualDeliveryFormScreen({super.key});

  @override
  ConsumerState<ManualDeliveryFormScreen> createState() =>
      _ManualDeliveryFormScreenState();
}

class _ManualDeliveryFormScreenState
    extends ConsumerState<ManualDeliveryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();

  // State
  final List<_SelectedItem> _selectedItems = [];
  String _searchQuery = '';
  int? _estimatedMinutes; // null = no estimate
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  double get _total =>
      _selectedItems.fold(0, (sum, i) => sum + i.product.price * i.quantity);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        title: Text(
          l10n.deliveryManualOrderCreate,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.divider),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Customer info ──────────────────────────────
            _SectionHeader(
              title: l10n.deliveryCustomer,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 8),
            _card([
              _FormField(
                controller: _nameController,
                label: l10n.deliveryCustomerName,
                icon: Icons.person,
                keyboardType: TextInputType.name,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '${l10n.deliveryCustomerName} is required' : null,
              ),
              const Divider(height: 1),
              _FormField(
                controller: _phoneController,
                label: l10n.deliveryCustomerPhone,
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '${l10n.deliveryCustomerPhone} is required' : null,
              ),
              const Divider(height: 1),
              _FormField(
                controller: _addressController,
                label: l10n.deliveryAddressInput,
                icon: Icons.location_on_outlined,
                keyboardType: TextInputType.streetAddress,
                maxLines: 2,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '${l10n.deliveryAddressInput} is required' : null,
              ),
            ]),

            const SizedBox(height: 16),

            // ── Estimated pickup time ──────────────────────
            _SectionHeader(
              title: l10n.deliveryEstimatedPickup,
              icon: Icons.schedule,
            ),
            const SizedBox(height: 8),
            _card([
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  children: [null, 15, 30, 45, 60, 90].map((mins) {
                    final label = mins == null ? 'None' : '${mins}min';
                    final selected = _estimatedMinutes == mins;
                    return ChoiceChip(
                      label: Text(label),
                      selected: selected,
                      selectedColor: AppTheme.primary,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppTheme.textPrimary,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) =>
                          setState(() => _estimatedMinutes = mins),
                    );
                  }).toList(),
                ),
              ),
            ]),

            const SizedBox(height: 16),

            // ── Item selection ─────────────────────────────
            _SectionHeader(
              title: l10n.deliverySelectItems,
              icon: Icons.restaurant_menu,
            ),
            const SizedBox(height: 8),

            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.search,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppTheme.cardWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.divider),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),

            const SizedBox(height: 8),

            // Product list
            productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (products) {
                final filtered = products.where((p) {
                  if (_searchQuery.isEmpty) return true;
                  return p.name.toLowerCase().contains(_searchQuery) ||
                      (p.category?.toLowerCase().contains(_searchQuery) ?? false);
                }).toList();

                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        l10n.noProducts,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  );
                }

                return Container(
                  constraints: const BoxConstraints(maxHeight: 280),
                  decoration: BoxDecoration(
                    color: AppTheme.cardWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (context2, index2) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      final existing = _selectedItems
                          .where((i) => i.product.id == product.id)
                          .firstOrNull;
                      return _ProductPickerRow(
                        product: product,
                        quantity: existing?.quantity ?? 0,
                        onAdd: () => _addItem(product),
                        onRemove: () => _removeItem(product),
                      );
                    },
                  ),
                );
              },
            ),

            // Selected items summary
            if (_selectedItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedItems.fold(0, (sum, i) => sum + i.quantity)} item(s) selected',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ..._selectedItems.map(
                      (i) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${i.product.name} x${i.quantity}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              _formatPrice(i.product.price * i.quantity),
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                        Text(
                          _formatPrice(_total),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── Special instructions ───────────────────────
            _SectionHeader(
              title: l10n.kdsSpecialInstructions,
              icon: Icons.notes_outlined,
            ),
            const SizedBox(height: 8),
            _card([
              _FormField(
                controller: _notesController,
                label: l10n.kdsSpecialInstructions,
                icon: Icons.notes,
                maxLines: 3,
                required: false,
              ),
            ]),

            const SizedBox(height: 24),

            // ── Submit ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : () => _submit(context),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_box_outlined),
                label: Text(
                  _isSubmitting ? l10n.loading : l10n.deliveryManualOrderCreate,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Item management
  // ──────────────────────────────────────────────

  void _addItem(Product product) {
    setState(() {
      final existing =
          _selectedItems.where((i) => i.product.id == product.id).firstOrNull;
      if (existing != null) {
        existing.quantity++;
      } else {
        _selectedItems.add(_SelectedItem(product: product, quantity: 1));
      }
    });
  }

  void _removeItem(Product product) {
    setState(() {
      final existing =
          _selectedItems.where((i) => i.product.id == product.id).firstOrNull;
      if (existing != null) {
        if (existing.quantity > 1) {
          existing.quantity--;
        } else {
          _selectedItems.removeWhere((i) => i.product.id == product.id);
        }
      }
    });
  }

  // ──────────────────────────────────────────────
  // Submit
  // ──────────────────────────────────────────────

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one item'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final estimatedPickup = _estimatedMinutes != null
          ? now.add(Duration(minutes: _estimatedMinutes!))
          : null;

      // Build the DeliveryOrder items from selected products
      final orderItems = _selectedItems
          .map((i) => DeliveryOrderItem(
                name: i.product.name,
                quantity: i.quantity,
                price: i.product.price,
              ))
          .toList();

      final platformOrderId =
          'MANUAL-${now.millisecondsSinceEpoch.toString().substring(7)}';

      final order = DeliveryOrder(
        id: '',
        platformOrderId: platformOrderId,
        platform: DeliveryPlatform.manual,
        status: DeliveryStatus.newOrder,
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        deliveryAddress: _addressController.text.trim(),
        items: orderItems,
        totalAmount: _total,
        specialInstructions: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        estimatedPickupTime: estimatedPickup,
        createdAt: now,
        updatedAt: now,
      );

      // Save the delivery order, then auto-accept it to create a KDS ticket
      final localId = await ref.read(deliveryOrdersRepositoryProvider).saveOrder(order);
      await ref.read(deliveryServiceProvider).acceptOrder(localId, order.copyWith(id: localId.toString()));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #$platformOrderId created'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true = order was created
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ──────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(children: children),
    );
  }

  String _formatPrice(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

// ──────────────────────────────────────────────
// Supporting widgets
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

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int? maxLines;
  final bool required;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.required = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: AppTheme.textSecondary),
          border: InputBorder.none,
        ),
        validator: validator ??
            (required
                ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
                : null),
      ),
    );
  }
}

class _ProductPickerRow extends StatelessWidget {
  final Product product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _ProductPickerRow({
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final selected = quantity > 0;
    return ListTile(
      dense: true,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.restaurant,
          size: 18,
          color: selected ? AppTheme.primary : AppTheme.textSecondary,
        ),
      ),
      title: Text(
        product.name,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: AppTheme.textPrimary,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _formatPrice(product.price),
        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (quantity > 0) ...[
            _IconBtn(icon: Icons.remove_circle_outline, onTap: onRemove),
            Container(
              constraints: const BoxConstraints(minWidth: 28),
              alignment: Alignment.center,
              child: Text(
                '$quantity',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
          _IconBtn(icon: Icons.add_circle_outline, onTap: onAdd, color: AppTheme.primary),
        ],
      ),
    );
  }

  String _formatPrice(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _IconBtn({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 22, color: color ?? AppTheme.textSecondary),
      ),
    );
  }
}

/// A mutable item holder used during form editing.
class _SelectedItem {
  final Product product;
  int quantity;

  _SelectedItem({required this.product, required this.quantity});
}
