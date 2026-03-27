import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/app_database.dart';
import '../../../providers/database_providers.dart';

/// 현재 선택된 카테고리 ID ("전체" = null)
final selectedCategoryProvider = StateProvider<int?>((ref) => null);

/// 카테고리 목록 Provider (Categories 테이블에서 활성 카테고리 조회)
final categoryListProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.categoriesDao.getAllCategories().asStream();
});

/// 필터링된 상품 목록 Provider
/// productChangeSignalProvider를 watch → Products Management CUD 시 강제 갱신
final filteredProductsProvider = FutureProvider<List<Product>>((ref) async {
  final dao = ref.watch(productsDaoProvider);
  final selectedCategoryId = ref.watch(selectedCategoryProvider);
  ref.watch(productChangeSignalProvider); // 상품 변경 신호 → 리빌드 트리거

  if (selectedCategoryId == null) {
    return dao.getAllProducts();
  } else {
    return dao.getProductsByCategoryId(selectedCategoryId);
  }
});

/// 검색 키워드 Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

/// 검색 결과 Provider
/// productChangeSignal/searchQuery/selectedCategory 중 하나라도 바뀌면 즉시 갱신
final searchResultsProvider = FutureProvider<List<Product>>((ref) async {
  final dao = ref.watch(productsDaoProvider);
  final query = ref.watch(searchQueryProvider);
  ref.watch(productChangeSignalProvider); // 상품 변경 신호 → 리빌드 트리거

  if (query.trim().isNotEmpty) {
    return dao.searchProducts(query.trim());
  }

  return ref.watch(filteredProductsProvider.future);
});
