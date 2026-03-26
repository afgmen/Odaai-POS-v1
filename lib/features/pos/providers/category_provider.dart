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

/// 필터링된 상품 목록 Provider (StreamProvider — 재고/가격 변경 즉시 반영)
/// productChangeSignalProvider를 watch하여 Products Management CUD 시 강제 갱신됨
final filteredProductsProvider = StreamProvider<List<Product>>((ref) {
  final dao = ref.watch(productsDaoProvider);
  final selectedCategoryId = ref.watch(selectedCategoryProvider);
  ref.watch(productChangeSignalProvider); // 상품 변경 신호 구독 → 변경 시 스트림 재구독

  if (selectedCategoryId == null) {
    return dao.watchAllProducts();
  } else {
    return dao.watchProductsByCategoryId(selectedCategoryId);
  }
});

/// 검색 키워드 Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

/// 검색 결과 Provider (키워드 입력 시 검색, 빈 경우 필터 스트림)
final searchResultsProvider = StreamProvider<List<Product>>((ref) {
  final dao = ref.watch(productsDaoProvider);
  final query = ref.watch(searchQueryProvider);

  if (query.trim().isEmpty) {
    // 검색 키워드 없으면 카테고리 필터 스트림 직접 반환 (재고 변경 실시간 반영)
    return ref.watch(filteredProductsProvider.stream);
  }

  // 검색어 있으면 Future를 Stream으로 변환
  return Stream.fromFuture(dao.searchProducts(query.trim()));
});
