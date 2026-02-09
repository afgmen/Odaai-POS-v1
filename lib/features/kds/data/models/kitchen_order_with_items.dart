import '../../../../database/app_database.dart';

/// 주방 주문 + 판매 아이템 정보
class KitchenOrderWithItems {
  final KitchenOrder order;
  final List<SaleItem> items;

  const KitchenOrderWithItems({
    required this.order,
    required this.items,
  });

  /// 총 수량
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  /// 메뉴 요약 문자열 (예: "아메리카노 x2, 라떼 x1")
  String get menuSummary {
    if (items.isEmpty) return '';
    if (items.length == 1) {
      final item = items.first;
      return '${item.productName} x${item.quantity}';
    }
    // 2개 이상인 경우
    final first = items.first;
    final remaining = items.length - 1;
    return '${first.productName} x${first.quantity} 외 $remaining개';
  }

  /// 메뉴 전체 목록 문자열 (줄바꿈 구분)
  String get fullMenuList {
    return items
        .map((item) => '${item.productName} x${item.quantity}')
        .join('\n');
  }
}
