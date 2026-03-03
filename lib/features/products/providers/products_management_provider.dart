import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/app_database.dart';
import '../../../providers/database_providers.dart';

/// 상품관리 검색 키워드 (POS의 searchQueryProvider와 독립)
final mgmtSearchQueryProvider = StateProvider<String>((ref) => '');

/// 상품관리 카테고리 필터 — categoryId 기반 (null = 전체)
final mgmtSelectedCategoryProvider = StateProvider<int?>((ref) => null);

/// 카테고리 목록 — categories 테이블에서 가져옴
final mgmtCategoryListProvider = FutureProvider<List<Category>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.categoriesDao.getAllCategories();
});

/// categoryId → name 매핑 (테이블 표시용)
final categoryNameMapProvider = FutureProvider<Map<int, String>>((ref) async {
  final db = ref.watch(databaseProvider);
  final categories = await db.categoriesDao.getAllCategories();
  return {for (final c in categories) c.id: c.name};
});

/// 전체 상품 목록 스트림 (실시간 업데이트)
final allProductsStreamProvider = StreamProvider<List<Product>>((ref) {
  final dao = ref.watch(productsDaoProvider);
  return dao.watchAllProducts();
});

/// 필터링된 상품 목록 (키워드 + 카테고리 조합) - 실시간 업데이트
/// 전체 상품 Stream을 받아서 클라이언트 사이드에서 필터링
final mgmtFilteredProductsProvider = StreamProvider<List<Product>>((ref) {
  final allProductsAsync = ref.watch(allProductsStreamProvider);
  final query = ref.watch(mgmtSearchQueryProvider);
  final categoryId = ref.watch(mgmtSelectedCategoryProvider);

  return allProductsAsync.when(
    data: (allProducts) {
      var filtered = allProducts;

      // 카테고리 필터링 — categoryId 기반
      if (categoryId != null) {
        filtered = filtered.where((p) => p.categoryId == categoryId).toList();
      }

      // 검색어 필터링 (이름, SKU, 바코드)
      if (query.trim().isNotEmpty) {
        final searchLower = query.trim().toLowerCase();
        filtered = filtered.where((p) {
          return p.name.toLowerCase().contains(searchLower) ||
              p.sku.toLowerCase().contains(searchLower) ||
              (p.barcode?.toLowerCase().contains(searchLower) ?? false);
        }).toList();
      }

      return Stream.value(filtered);
    },
    loading: () => Stream.value(<Product>[]),
    error: (err, stack) => Stream.value(<Product>[]),
  ).asyncExpand((products) => Stream.value(products));
});
