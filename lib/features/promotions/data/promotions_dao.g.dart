// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotions_dao.dart';

// ignore_for_file: type=lint
mixin _$PromotionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $ProductsTable get products => attachedDatabase.products;
  $PromotionsTable get promotions => attachedDatabase.promotions;
  $PromotionProductsTable get promotionProducts =>
      attachedDatabase.promotionProducts;
  PromotionsDaoManager get managers => PromotionsDaoManager(this);
}

class PromotionsDaoManager {
  final _$PromotionsDaoMixin _db;
  PromotionsDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$PromotionsTableTableManager get promotions =>
      $$PromotionsTableTableManager(_db.attachedDatabase, _db.promotions);
  $$PromotionProductsTableTableManager get promotionProducts =>
      $$PromotionProductsTableTableManager(
        _db.attachedDatabase,
        _db.promotionProducts,
      );
}
