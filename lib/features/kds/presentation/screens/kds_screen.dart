import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/kds_screen_provider.dart';
import '../widgets/order_card.dart';
import '../widgets/filter_tabs.dart';
import '../widgets/order_detail_modal.dart';
import '../widgets/performance_header.dart';
import '../widgets/menu_item_summary_panel.dart';

/// KDS (Kitchen Display System) main screen.
///
/// Displays active kitchen orders in a grid layout with an optional
/// side panel that provides a menu-item-level summary view.
class KdsScreen extends ConsumerWidget {
  const KdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final filteredOrders = ref.watch(filteredOrdersProvider);
    final selectedOrderId = ref.watch(selectedOrderIdProvider);
    final showDetail = ref.watch(showOrderDetailProvider);
    final showMenuSummary = ref.watch(showMenuSummaryPanelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.kdsTitle),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Menu summary panel toggle button
          IconButton(
            onPressed: () {
              ref.read(showMenuSummaryPanelProvider.notifier).state =
                  !showMenuSummary;
            },
            icon: Icon(
              showMenuSummary ? Icons.list_alt : Icons.grid_view,
            ),
            tooltip: l10n.kdsMenuSummaryToggle,
          ),
          // Performance stats
          const PerformanceHeader(),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Main order grid area
          Expanded(
            child: showMenuSummary
                ? const MenuItemSummaryPanel()
                : Column(
                    children: [
                      // Status filter tabs
                      const FilterTabs(),

                      // Order grid
                      Expanded(
                        child: filteredOrders.when(
                          data: (orders) {
                            if (orders.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.restaurant_menu,
                                      size: 80,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      l10n.kdsNoOrders,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.2,
                              ),
                              itemCount: orders.length,
                              itemBuilder: (context, index) {
                                final orderWithItems = orders[index];
                                return OrderCard(
                                  orderWithItems: orderWithItems,
                                  onTap: () {
                                    ref
                                        .read(selectedOrderIdProvider.notifier)
                                        .state = orderWithItems.order.id;
                                    ref
                                        .read(showOrderDetailProvider.notifier)
                                        .state = true;
                                  },
                                );
                              },
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, stack) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error, color: Colors.red, size: 48),
                                const SizedBox(height: 16),
                                Text(l10n.kdsErrorOccurred(error)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          // Menu item summary side panel (conditionally shown)
        ],
      ),

      // Order detail modal
      bottomSheet: showDetail && selectedOrderId != null
          ? OrderDetailModal(orderId: selectedOrderId)
          : null,
    );
  }
}
