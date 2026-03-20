import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oda_pos/features/pos/providers/cart_provider.dart';
import 'package:oda_pos/database/app_database.dart';

// NOTE: cartTotalProvider depends on autoPromotionDiscountProvider which
// requires a database StreamProvider.  In unit tests we use cartSubtotalProvider
// and cartDiscountAmountProvider instead, and verify the formula manually.

// ---------------------------------------------------------------------------
// Helper: build a minimal Product for test purposes.
// ---------------------------------------------------------------------------
Product _product(int id, String name, double price, {String? category}) {
  final now = DateTime(2024);
  return Product(
    id: id,
    sku: 'SKU-$id',
    name: name,
    price: price,
    cost: price * 0.5,
    stock: 100,
    minStock: 5,
    isActive: true,
    needsSync: false,
    createdAt: now,
    updatedAt: now,
    category: category,
    vatRate: 10.0, // B-118: required field added
  );
}

/// Create a fresh ProviderContainer so each test starts with an empty cart.
ProviderContainer _makeContainer() => ProviderContainer();

void main() {
  group('CartState — adding items', () {
    test('adding one item puts it in cart', () {
      final c = _makeContainer();
      addTearDown(c.dispose);

      c.read(cartProvider.notifier).addItem(_product(1, 'Pho Bo', 15000));
      final cart = c.read(cartProvider);
      expect(cart.length, 1);
      expect(cart.first.product.name, 'Pho Bo');
      expect(cart.first.quantity, 1);
    });

    test('adding the same product increments quantity', () {
      final c = _makeContainer();
      addTearDown(c.dispose);

      final pho = _product(1, 'Pho Bo', 15000);
      c.read(cartProvider.notifier).addItem(pho);
      c.read(cartProvider.notifier).addItem(pho);
      final cart = c.read(cartProvider);
      expect(cart.length, 1);
      expect(cart.first.quantity, 2);
    });

    test('adding two different products gives two cart lines', () {
      final c = _makeContainer();
      addTearDown(c.dispose);

      c.read(cartProvider.notifier).addItem(_product(1, 'Pho Bo', 15000));
      c.read(cartProvider.notifier).addItem(_product(2, 'Bun Bo', 13000));
      expect(c.read(cartProvider).length, 2);
    });
  });

  // ── subtotal / totalAmount ────────────────────────────────────────────────
  group('CartState — totalAmount calculations', () {
    test('subtotal is sum of (price × quantity) for all items', () {
      final c = _makeContainer();
      addTearDown(c.dispose);

      c.read(cartProvider.notifier).addItem(_product(1, 'Pho Bo', 15000));
      c.read(cartProvider.notifier).addItem(_product(1, 'Pho Bo', 15000)); // qty 2
      c.read(cartProvider.notifier).addItem(_product(2, 'Bun Bo', 13000));

      // 15000*2 + 13000*1 = 43000
      final subtotal = c.read(cartSubtotalProvider);
      expect(subtotal, closeTo(43000, 0.01));
    });

    test('total equals subtotal when no discount applied', () {
      final c = _makeContainer();
      addTearDown(c.dispose);

      c.read(cartProvider.notifier).addItem(_product(1, 'Pho Bo', 10000));
      c.read(cartProvider.notifier).addItem(_product(2, 'Spring Roll', 5000));

      final subtotal = c.read(cartSubtotalProvider);
      final discount = c.read(cartDiscountAmountProvider);
      expect(subtotal - discount, closeTo(subtotal, 0.01));
    });

    test('adding 3 items of the same product calculates correct subtotal', () {
      final c = _makeContainer();
      addTearDown(c.dispose);

      final p = _product(1, 'Coffee', 5000);
      c.read(cartProvider.notifier).addItem(p);
      c.read(cartProvider.notifier).addItem(p);
      c.read(cartProvider.notifier).addItem(p);

      expect(c.read(cartSubtotalProvider), closeTo(15000, 0.01));
    });
  });

  // ── percentage discount ───────────────────────────────────────────────────
  group('CartState — percentage discount', () {
    test('10% discount on 20000 subtotal gives 2000 discount', () {
      final c = _makeContainer();
      addTearDown(c.dispose);

      c.read(cartProvider.notifier).addItem(_product(1, 'Pho Bo', 20000));
      c.read(discountTypeProvider.notifier).state = DiscountType.percent;
      c.read(discountValueProvider.notifier).state = 10;

      final discount = c.read(cartDiscountAmountProvider);
      expect(discount, closeTo(2000, 0.01));

      final subtotal = c.read(cartSubtotalProvider);
      expect(subtotal - discount, closeTo(18000, 0.01));
    });

    test('50% discount halves the subtotal', () {
      final c = _makeContainer();
      addTearDown(c.dispose);

      c.read(cartProvider.notifier).addItem(_product(1, 'Set Meal', 40000));
      c.read(discountTypeProvider.notifier).state = DiscountType.percent;
      c.read(discountValueProvider.notifier).state = 50;

      expect(c.read(cartDiscountAmountProvider), closeTo(20000, 0.01));
      final s50 = c.read(cartSubtotalProvider);
      final d50 = c.read(cartDiscountAmountProvider);
      expect(s50 - d50, closeTo(20000, 0.01));
    });

    test('100% discount results in 0 total', () {
      final c = _makeContainer();
      addTearDown(c.dispose);

      c.read(cartProvider.notifier).addItem(_product(1, 'Item', 10000));
      c.read(discountTypeProvider.notifier).state = DiscountType.percent;
      c.read(discountValueProvider.notifier).state = 100;

      final s100 = c.read(cartSubtotalProvider);
      final d100 = c.read(cartDiscountAmountProvider);
      expect(s100 - d100, closeTo(0, 0.01));
    });
  });

  // ── fixed discount ────────────────────────────────────────────────────────
  group('CartState — fixed amount discount', () {
    test('fixed discount of 3000 on 10000 subtotal gives 7000 total', () {
      final c = _makeContainer();
      addTearDown(c.dispose);

      c.read(cartProvider.notifier).addItem(_product(1, 'Pho Bo', 10000));
      c.read(discountTypeProvider.notifier).state = DiscountType.won;
      c.read(discountValueProvider.notifier).state = 3000;

      expect(c.read(cartDiscountAmountProvider), closeTo(3000, 0.01));
      final sFixed = c.read(cartSubtotalProvider);
      final dFixed = c.read(cartDiscountAmountProvider);
      expect(sFixed - dFixed, closeTo(7000, 0.01));
    });

    test('fixed discount cannot exceed subtotal (clamped to subtotal)', () {
      final c = _makeContainer();
      addTearDown(c.dispose);

      c.read(cartProvider.notifier).addItem(_product(1, 'Pho Bo', 5000));
      c.read(discountTypeProvider.notifier).state = DiscountType.won;
      c.read(discountValueProvider.notifier).state = 99999; // > subtotal

      // Discount is clamped to subtotal (5000); total should be 0
      expect(c.read(cartDiscountAmountProvider), closeTo(5000, 0.01));
      final sClamped = c.read(cartSubtotalProvider);
      final dClamped = c.read(cartDiscountAmountProvider);
      expect(sClamped - dClamped, closeTo(0, 0.01));
    });
  });

  // ── removing items ────────────────────────────────────────────────────────
  group('CartState — removing items', () {
    test('removing an item recalculates totalAmount', () {
      final c = _makeContainer();
      addTearDown(c.dispose);

      c.read(cartProvider.notifier).addItem(_product(1, 'Pho Bo', 15000));
      c.read(cartProvider.notifier).addItem(_product(2, 'Bun Bo', 13000));
      c.read(cartProvider.notifier).removeItem(1);

      expect(c.read(cartProvider).length, 1);
      expect(c.read(cartSubtotalProvider), closeTo(13000, 0.01));
    });

    test('removing non-existent product does not throw', () {
      final c = _makeContainer();
      addTearDown(c.dispose);

      c.read(cartProvider.notifier).addItem(_product(1, 'Pho Bo', 15000));
      c.read(cartProvider.notifier).removeItem(999); // does not exist

      expect(c.read(cartProvider).length, 1);
    });
  });

  // ── updateQuantity ────────────────────────────────────────────────────────
  group('CartState — updateQuantity', () {
    test('updating quantity recalculates subtotal', () {
      final c = _makeContainer();
      addTearDown(c.dispose);

      c.read(cartProvider.notifier).addItem(_product(1, 'Coffee', 5000));
      c.read(cartProvider.notifier).updateQuantity(1, 4);

      expect(c.read(cartProvider).first.quantity, 4);
      expect(c.read(cartSubtotalProvider), closeTo(20000, 0.01));
    });

    test('quantity = 0 removes item from cart (edge case)', () {
      final c = _makeContainer();
      addTearDown(c.dispose);

      c.read(cartProvider.notifier).addItem(_product(1, 'Coffee', 5000));
      c.read(cartProvider.notifier).updateQuantity(1, 0);

      // updateQuantity with 0 calls removeItem internally
      expect(c.read(cartProvider), isEmpty);
    });

    test('negative quantity removes item from cart', () {
      final c = _makeContainer();
      addTearDown(c.dispose);

      c.read(cartProvider.notifier).addItem(_product(1, 'Tea', 3000));
      c.read(cartProvider.notifier).updateQuantity(1, -1);

      expect(c.read(cartProvider), isEmpty);
    });
  });

  // ── itemCount ────────────────────────────────────────────────────────────
  group('CartState — itemCount', () {
    test('itemCount sums quantities across all lines', () {
      final c = _makeContainer();
      addTearDown(c.dispose);

      final pho = _product(1, 'Pho Bo', 15000);
      c.read(cartProvider.notifier).addItem(pho);
      c.read(cartProvider.notifier).addItem(pho); // qty 2
      c.read(cartProvider.notifier).addItem(_product(2, 'Bun Bo', 13000)); // qty 1

      expect(c.read(cartItemCountProvider), 3);
    });
  });

  // ── clear ────────────────────────────────────────────────────────────────
  group('CartState — clear', () {
    test('clear empties the cart', () {
      final c = _makeContainer();
      addTearDown(c.dispose);

      c.read(cartProvider.notifier).addItem(_product(1, 'Pho Bo', 15000));
      c.read(cartProvider.notifier).addItem(_product(2, 'Bun Bo', 13000));
      c.read(cartProvider.notifier).clear();

      expect(c.read(cartProvider), isEmpty);
      expect(c.read(cartSubtotalProvider), 0.0);
      expect(c.read(cartItemCountProvider), 0);
    });
  });

  // ── promotion discount (manual B1G1) ─────────────────────────────────────
  group('CartState — B1G1 promotion discount', () {
    test('B1G1: 2 items → 1 free (discount = 1 unit price)', () {
      final c = _makeContainer();
      addTearDown(c.dispose);

      final p = _product(1, 'Coffee', 5000);
      c.read(cartProvider.notifier).addItem(p);
      c.read(cartProvider.notifier).addItem(p); // qty 2

      c.read(promotionProductIdProvider.notifier).state = p.id;
      c.read(promotionTypeProvider.notifier).state = PromotionType.buy1get1;

      final promoDiscount = c.read(promotionDiscountProvider);
      expect(promoDiscount, closeTo(5000, 0.01)); // 1 free unit
    });

    test('B1G1: 1 item → no free unit (discount = 0)', () {
      final c = _makeContainer();
      addTearDown(c.dispose);

      final p = _product(1, 'Coffee', 5000);
      c.read(cartProvider.notifier).addItem(p); // qty 1

      c.read(promotionProductIdProvider.notifier).state = p.id;
      c.read(promotionTypeProvider.notifier).state = PromotionType.buy1get1;

      expect(c.read(promotionDiscountProvider), 0.0);
    });

    test('B2G1: 3 items → 1 free', () {
      final c = _makeContainer();
      addTearDown(c.dispose);

      final p = _product(1, 'Tea', 4000);
      c.read(cartProvider.notifier).addItem(p);
      c.read(cartProvider.notifier).addItem(p);
      c.read(cartProvider.notifier).addItem(p); // qty 3

      c.read(promotionProductIdProvider.notifier).state = p.id;
      c.read(promotionTypeProvider.notifier).state = PromotionType.buy2get1;

      expect(c.read(promotionDiscountProvider), closeTo(4000, 0.01));
    });
  });
}
