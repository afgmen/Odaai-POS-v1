import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/enums/delivery_platform.dart';
import '../providers/delivery_screen_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// Horizontal filter tabs: All | Grab (n) | ShopeeFood (n) | Manual (n)
class DeliveryFilterTabs extends ConsumerWidget {
  const DeliveryFilterTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selected = ref.watch(selectedPlatformFilterProvider);
    final grabCount = ref.watch(grabOrderCountProvider);
    final shopeeCount = ref.watch(shopeefoodOrderCountProvider);
    final manualCount = ref.watch(manualOrderCountProvider);

    final tabs = <_FilterTab>[
      _FilterTab(label: l10n.deliveryFilterAll, platform: null, count: null),
      _FilterTab(
        label: 'Grab',
        platform: DeliveryPlatform.grab,
        count: grabCount,
        color: DeliveryPlatform.grab.brandColor,
      ),
      _FilterTab(
        label: 'ShopeeFood',
        platform: DeliveryPlatform.shopeefood,
        count: shopeeCount,
        color: DeliveryPlatform.shopeefood.brandColor,
      ),
      _FilterTab(
        label: l10n.deliveryFilterManual,
        platform: DeliveryPlatform.manual,
        count: manualCount,
        color: DeliveryPlatform.manual.brandColor,
      ),
    ];

    return Container(
      height: 48,
      color: Colors.grey.shade100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isSelected = selected == tab.platform;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tab.color != null) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: tab.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(tab.label),
                  if (tab.count != null && tab.count! > 0) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : (tab.color ?? Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${tab.count}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? (tab.color ?? Colors.grey)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              onSelected: (_) {
                ref
                    .read(selectedPlatformFilterProvider.notifier)
                    .state = tab.platform;
              },
              selectedColor:
                  (tab.color ?? Theme.of(context).primaryColor)
                      .withValues(alpha: 0.15),
              checkmarkColor: tab.color ?? Theme.of(context).primaryColor,
            ),
          );
        },
      ),
    );
  }
}

class _FilterTab {
  final String label;
  final DeliveryPlatform? platform;
  final int? count;
  final Color? color;

  const _FilterTab({
    required this.label,
    required this.platform,
    required this.count,
    this.color,
  });
}
