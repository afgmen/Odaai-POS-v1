import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/app_database.dart';
import '../../../providers/database_providers.dart';

/// 상품관리 검색 키워드 (POS의 searchQueryProvider와 독립)
final mgmtSearchQueryProvider = StateProvider<String>((ref) => '');

/// 상품관리 카테고리 필터 (POS와 독립)
final mgmtSelectedCategoryProvider = StateProvider<String?>((ref) => null);

/// 카테고리 목록
final mgmtCategoryListProvider = FutureProvider<List<String>>((ref) async {
  final dao = ref.watch(productsDaoProvider);
  final categories = await dao.getProductCountByCategory();
  return categories.keys.toList();
});

/// 필터링된 상품 목록 (키워드 + 카테고리 조합)
final mgmtFilteredProductsProvider = FutureProvider<List<Product>>((ref) async {
  final dao = ref.watch(productsDaoProvider);
  final query = ref.watch(mgmtSearchQueryProvider);
  final category = ref.watch(mgmtSelectedCategoryProvider);

  if (query.trim().isNotEmpty) {
    return await dao.searchProducts(query.trim());
  }
  if (category != null) {
    return await dao.getProductsByCategory(category);
  }
  return await dao.getAllProducts();
});
