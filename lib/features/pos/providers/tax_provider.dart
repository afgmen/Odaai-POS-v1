import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/providers/store_settings_provider.dart';
import '../../../features/products/providers/category_provider.dart';
import 'cart_provider.dart';

/// Tax settings keys
class TaxSettingsKeys {
  static const taxEnabled = 'tax_enabled';
  static const taxRate = 'tax_rate';
  static const taxInclusive = 'tax_inclusive';
}

/// Tax enabled provider
final taxEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(storeSettingsProvider);
  return settings[TaxSettingsKeys.taxEnabled] as bool? ?? true; // Vietnam default: true
});

/// Tax rate provider (%)
final taxRateProvider = Provider<double>((ref) {
  final settings = ref.watch(storeSettingsProvider);
  return settings[TaxSettingsKeys.taxRate] as double? ?? 10.0; // Vietnam VAT: 10%
});

/// Tax inclusive provider (true = price includes tax, false = tax added separately)
final taxInclusiveProvider = Provider<bool>((ref) {
  final settings = ref.watch(storeSettingsProvider);
  return settings[TaxSettingsKeys.taxInclusive] as bool? ?? true; // Vietnam default: inclusive
});

/// Map of categoryId → vatRate (null entry means category has no override)
final _categoryVatMapProvider = Provider<Map<int, double?>>((ref) {
  final categoriesAsync = ref.watch(activeCategoriesListProvider);
  return categoriesAsync.whenOrNull(
    data: (categories) => {for (final c in categories) c.id: c.vatRate},
  ) ?? {};
});

/// Cart tax amount provider (per-product VAT, with per-category fallback)
/// B-118: 제품별 vatRate 우선 적용, 없으면 카테고리 vatRate, 없으면 전체 설정 세율 사용
final cartTaxAmountProvider = Provider<double>((ref) {
  final enabled = ref.watch(taxEnabledProvider);
  if (!enabled) return 0.0;

  final cart = ref.watch(cartProvider);
  if (cart.isEmpty) return 0.0;

  final discount = ref.watch(cartAllDiscountProvider);
  final defaultRate = ref.watch(taxRateProvider);
  final inclusive = ref.watch(taxInclusiveProvider);
  final categoryVatMap = ref.watch(_categoryVatMapProvider);

  // Distribute discount proportionally across items
  final subtotal = cart.fold(0.0, (sum, item) => sum + item.subtotal);
  final discountRatio = subtotal > 0 ? discount / subtotal : 0.0;

  double totalTax = 0.0;
  for (final item in cart) {
    // B-118: product.vatRate 우선, 카테고리 override, 마지막으로 global default
    final productVatRate = item.product.vatRate;
    final categoryVatRate = item.product.categoryId != null
        ? categoryVatMap[item.product.categoryId]
        : null;
    final rate = productVatRate != 10.0
        ? productVatRate
        : (categoryVatRate ?? defaultRate);

    final itemSubtotal = item.subtotal;
    final itemDiscount = itemSubtotal * discountRatio;
    final taxableAmount = itemSubtotal - itemDiscount;

    if (taxableAmount <= 0 || rate <= 0) continue;

    if (inclusive) {
      totalTax += taxableAmount - (taxableAmount / (1 + rate / 100));
    } else {
      totalTax += taxableAmount * (rate / 100);
    }
  }

  return totalTax;
});
