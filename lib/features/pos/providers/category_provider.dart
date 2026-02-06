import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/app_database.dart';
import '../../../providers/database_providers.dart';

/// 현재 선택된 카테고리 ("전체" = null)
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// 카테고리 목록 Provider (DB에서 고유 카테고리 조회)
final categoryListProvider = FutureProvider<List<String>>((ref) async {
  final dao = ref.watch(productsDaoProvider);
  final categories = await dao.getProductCountByCategory();
  return categories.keys.toList();
});

/// 필터링된 상품 목록 Provider
final filteredProductsProvider = FutureProvider<List<Product>>((ref) async {
  final dao = ref.watch(productsDaoProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);

  if (selectedCategory == null) {
    return await dao.getAllProducts();
  } else {
    return await dao.getProductsByCategory(selectedCategory);
  }
});

/// 검색 키워드 Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

/// 검색 결과 Provider (키워드 입력 시 검색, 빈 경우 필터 목록)
final searchResultsProvider = FutureProvider<List<Product>>((ref) async {
  final dao = ref.watch(productsDaoProvider);
  final query = ref.watch(searchQueryProvider);

  if (query.trim().isEmpty) {
    // 검색 키워드 없으면 카테고리 필터 적용
    return await ref.watch(filteredProductsProvider.future);
  }

  return await dao.searchProducts(query.trim());
});
