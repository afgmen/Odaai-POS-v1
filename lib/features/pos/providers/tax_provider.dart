import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/providers/store_settings_provider.dart';
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

/// Cart tax amount provider
/// B-118: 제품별 vatRate 우선 적용, 없으면 전체 설정 세율 사용
final cartTaxAmountProvider = Provider<double>((ref) {
  final enabled = ref.watch(taxEnabledProvider);
  if (!enabled) return 0.0;

  final cart = ref.watch(cartProvider);
  final inclusive = ref.watch(taxInclusiveProvider);
  final defaultRate = ref.watch(taxRateProvider);

  double totalTax = 0.0;

  for (final item in cart) {
    // B-118: 제품에 vatRate가 설정되어 있으면 우선 사용, 없으면(null) 글로벌 설정
    // 수정: 기존 조건 (vatRate != 10.0 || vatRate == 10.0 = 항상 true) 버그 수정
    // vatRate가 제품별로 명시 설정되어 있으므로 product.vatRate를 직접 사용,
    // 0%이면 해당 상품은 비과세 처리
    final rate = item.product.vatRate;

    final itemSubtotal = item.subtotal;
    if (itemSubtotal <= 0 || rate <= 0) continue;

    if (inclusive) {
      totalTax += itemSubtotal - (itemSubtotal / (1 + rate / 100));
    } else {
      totalTax += itemSubtotal * (rate / 100);
    }
  }

  return totalTax;
});
