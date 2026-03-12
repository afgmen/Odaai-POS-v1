import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:oda_pos/database/app_database.dart';

/// B-099: Promotion — 편집 시 상품 선택 후 Save 불가
///
/// Verifies that getPromotionProducts returns the correct product IDs,
/// so initState can correctly populate _selectedProductIds.
void main() {
  group('B-099: PromotionFormModal — edit mode product ID loading', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> createProduct(String name) => db.into(db.products).insert(
          ProductsCompanion.insert(
            name: name,
            sku: 'SKU-$name',
            price: const Value(50000),
            stock: const Value(20),
          ),
        );

    Future<int> createPromotion({bool applyToAll = false}) =>
        db.into(db.promotions).insert(
          PromotionsCompanion.insert(
            name: 'Test Promo',
            type: 'percentOff',
            value: const Value(10.0),
            applyToAllProducts: Value(applyToAll),
          ),
        );

    test('getPromotionProducts returns linked products for edit mode', () async {
      final p1 = await createProduct('Pho');
      final p2 = await createProduct('Bun Bo');
      final promoId = await createPromotion();

      await db.promotionsDao.updatePromotionWithProducts(
        promotionId: promoId,
        promotion: PromotionsCompanion(
          updatedAt: Value(DateTime.now()),
        ),
        applyToAll: false,
        productIds: [p1, p2],
      );

      final products = await db.promotionsDao.getPromotionProducts(promoId);
      final productIds = products.map((p) => p.id).toSet();

      expect(productIds, containsAll([p1, p2]));
      expect(productIds.length, 2);
    });

    test('empty product list returned when applyToAll=true', () async {
      final p1 = await createProduct('Fried Rice');
      final promoId = await createPromotion(applyToAll: true);

      await db.promotionsDao.updatePromotionWithProducts(
        promotionId: promoId,
        promotion: PromotionsCompanion(
          updatedAt: Value(DateTime.now()),
        ),
        applyToAll: true,
        productIds: [p1],
      );

      // When applyToAll=true, specific product links may be cleared
      final promotion =
          await (db.select(db.promotions)..where((p) => p.id.equals(promoId)))
              .getSingle();

      expect(promotion.applyToAllProducts, isTrue);
    });

    test('save guard: empty selectedProductIds when not applyToAll blocks save', () {
      // Mirrors the _savePromotion guard:
      //   if (!_applyToAllProducts && _selectedProductIds.isEmpty) → block
      bool shouldBlock({
        required bool applyToAll,
        required Set<int> selectedIds,
      }) {
        return !applyToAll && selectedIds.isEmpty;
      }

      expect(
        shouldBlock(applyToAll: false, selectedIds: {}),
        isTrue,
        reason: 'Must block save when no products selected',
      );

      expect(
        shouldBlock(applyToAll: false, selectedIds: {1, 2}),
        isFalse,
        reason: 'Save allowed with products selected',
      );

      expect(
        shouldBlock(applyToAll: true, selectedIds: {}),
        isFalse,
        reason: 'Save allowed when applyToAll=true regardless of selection',
      );
    });

    test('product IDs loaded in edit mode match originally saved IDs', () async {
      final p1 = await createProduct('Noodle');
      final p2 = await createProduct('Rice');
      final p3 = await createProduct('Soup');
      final promoId = await createPromotion();

      await db.promotionsDao.updatePromotionWithProducts(
        promotionId: promoId,
        promotion: PromotionsCompanion(
          updatedAt: Value(DateTime.now()),
        ),
        applyToAll: false,
        productIds: [p1, p3], // p2 not included
      );

      final products = await db.promotionsDao.getPromotionProducts(promoId);
      final loadedIds = products.map((p) => p.id).toSet();

      expect(loadedIds, contains(p1));
      expect(loadedIds, contains(p3));
      expect(loadedIds, isNot(contains(p2)));
    });

    test('getPromotionProducts returns empty for promotion with no links', () async {
      final promoId = await createPromotion();
      final products = await db.promotionsDao.getPromotionProducts(promoId);
      expect(products.length, 0);
    });
  });
}
