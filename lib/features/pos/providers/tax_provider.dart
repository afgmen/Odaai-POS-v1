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
final cartTaxAmountProvider = Provider<double>((ref) {
  final enabled = ref.watch(taxEnabledProvider);
  if (!enabled) return 0.0;

  final subtotal = ref.watch(cartSubtotalProvider);
  final discount = ref.watch(cartAllDiscountProvider);
  final rate = ref.watch(taxRateProvider);
  final inclusive = ref.watch(taxInclusiveProvider);

  final taxableAmount = subtotal - discount;
  if (taxableAmount <= 0) return 0.0;

  if (inclusive) {
    // Tax inclusive: tax = amount - (amount / (1 + rate/100))
    return taxableAmount - (taxableAmount / (1 + rate / 100));
  } else {
    // Tax exclusive: tax = amount * (rate/100)
    return taxableAmount * (rate / 100);
  }
});
