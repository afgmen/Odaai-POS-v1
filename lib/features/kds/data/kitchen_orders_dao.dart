import 'package:drift/drift.dart';
import '../../../database/app_database.dart';
import '../../../database/tables/kitchen_orders.dart';
import '../../../database/tables/sales.dart';
import '../../../database/tables/store_tables_management.dart';
import 'models/kitchen_order_with_items.dart';

part 'kitchen_orders_dao.g.dart';

/// KDS (Kitchen Display System) DAO
/// 주방 주문 관리를 위한 데이터베이스 접근 계층
@DriftAccessor(tables: [KitchenOrders, Sales, SaleItems, RestaurantTables])
class KitchenOrdersDao extends DatabaseAccessor<AppDatabase>
    with _$KitchenOrdersDaoMixin {
  KitchenOrdersDao(super.db);

  // ============================================================
  // CREATE
  // ============================================================

  /// 새 주방 주문 생성 (POS에서 결제 완료 시 호출)
  Future<int> createOrder(KitchenOrdersCompanion order) {
    return into(kitchenOrders).insert(order);
  }

  /// 판매 ID로 주방 주문 자동 생성
  Future<int> createOrderFromSale({
    required int saleId,
    String? tableNumber,
    String? specialInstructions,
    String priority = 'NORMAL',
    String orderType = 'dineIn',
  }) async {
    return await into(kitchenOrders).insert(
      KitchenOrdersCompanion.insert(
        saleId: saleId,
        tableNumber: Value(tableNumber),
        specialInstructions: Value(specialInstructions),
        priority: Value(priority),
        orderType: Value(orderType),
      ),
    );
  }

  // ============================================================
  // READ - Single
  // ============================================================

  /// ID로 주문 조회
  Future<KitchenOrder?> getOrderById(int id) {
    return (select(kitchenOrders)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Sale ID로 주문 조회 (단건)
  Future<KitchenOrder?> getOrderBySaleId(int saleId) {
    return (select(kitchenOrders)..where((t) => t.saleId.equals(saleId)))
        .getSingleOrNull();
  }

  /// Sale ID로 모든 주문 조회 (B-121: 복수 조회용)
  Future<List<KitchenOrder>> getOrdersBySaleId(int saleId) {
    return (select(kitchenOrders)..where((t) => t.saleId.equals(saleId))).get();
  }

  // ============================================================
  // READ - List
  // ============================================================

  /// 모든 주문 목록 조회 (최신순)
  Future<List<KitchenOrder>> getAllOrders() {
    return (select(kitchenOrders)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// 상태별 주문 목록 조회
  Future<List<KitchenOrder>> getOrdersByStatus(String status) {
    return (select(kitchenOrders)
          ..where((t) => t.status.equals(status))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// 활성 주문 목록 (PENDING, PREPARING, READY)
  Future<List<KitchenOrder>> getActiveOrders() {
    return (select(kitchenOrders)
          ..where((t) => t.status.isIn(['PENDING', 'PREPARING', 'READY']))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  /// 긴급 주문만 조회
  Future<List<KitchenOrder>> getUrgentOrders() {
    return (select(kitchenOrders)
          ..where((t) => t.priority.equals('URGENT'))
          ..where((t) => t.status.isIn(['PENDING', 'PREPARING']))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  // ============================================================
  // READ - Stream (실시간 업데이트)
  // ============================================================

  /// 모든 주문 스트림 (KDS 화면용)
  Stream<List<KitchenOrder>> watchAllOrders() {
    return (select(kitchenOrders)
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  /// 상태별 주문 스트림
  Stream<List<KitchenOrder>> watchOrdersByStatus(String status) {
    return (select(kitchenOrders)
          ..where((t) => t.status.equals(status))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  /// 활성 주문 스트림 (KDS 메인 화면)
  Stream<List<KitchenOrder>> watchActiveOrders() {
    return (select(kitchenOrders)
          ..where((t) => t.status.isIn(['PENDING', 'PREPARING', 'READY']))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  // ============================================================
  // READ - With Items (JOIN)
  // ============================================================

  /// 주문 ID로 주문 + 메뉴 아이템 조회
  Future<KitchenOrderWithItems?> getOrderWithItems(int orderId) async {
    final order = await getOrderById(orderId);
    if (order == null) return null;

    final items = await (select(saleItems)
          ..where((t) => t.saleId.equals(order.saleId)))
        .get();

    return KitchenOrderWithItems(order: order, items: items);
  }

  /// 활성 주문 + 메뉴 아이템 목록 조회
  Future<List<KitchenOrderWithItems>> getActiveOrdersWithItems() async {
    final orders = await getActiveOrders();
    final result = <KitchenOrderWithItems>[];

    for (final order in orders) {
      final items = await (select(saleItems)
            ..where((t) => t.saleId.equals(order.saleId)))
          .get();
      result.add(KitchenOrderWithItems(order: order, items: items));
    }

    return result;
  }

  /// 활성 주문 + 메뉴 아이템 스트림 (KDS 메인 화면용)
  Stream<List<KitchenOrderWithItems>> watchActiveOrdersWithItems() {
    return watchActiveOrders().asyncMap((orders) async {
      final result = <KitchenOrderWithItems>[];

      for (final order in orders) {
        final items = await (select(saleItems)
              ..where((t) => t.saleId.equals(order.saleId)))
            .get();
        result.add(KitchenOrderWithItems(order: order, items: items));
      }

      return result;
    });
  }

  /// B-095: 전체 주문 + 메뉴 아이템 스트림 (SERVED/CANCELLED 포함)
  Stream<List<KitchenOrderWithItems>> watchAllOrdersWithItems() {
    return watchAllOrders().asyncMap((orders) async {
      final result = <KitchenOrderWithItems>[];

      for (final order in orders) {
        final items = await (select(saleItems)
              ..where((t) => t.saleId.equals(order.saleId)))
            .get();
        result.add(KitchenOrderWithItems(order: order, items: items));
      }

      return result;
    });
  }

  // ============================================================
  // UPDATE - 상태 변경
  // ============================================================

  /// 주문 상태 업데이트
  Future<bool> updateOrderStatus(int id, String newStatus) async {
    final now = DateTime.now();
    final updates = KitchenOrdersCompanion(
      status: Value(newStatus),
      updatedAt: Value(now),
    );

    // 상태별 타임스탬프 업데이트
    KitchenOrdersCompanion finalUpdates;
    switch (newStatus) {
      case 'PREPARING':
        finalUpdates = updates.copyWith(startedAt: Value(now));
        break;
      case 'READY':
        finalUpdates = updates.copyWith(readyAt: Value(now));
        break;
      case 'SERVED':
        finalUpdates = updates.copyWith(servedAt: Value(now));
        break;
      case 'CANCELLED':
        finalUpdates = updates.copyWith(cancelledAt: Value(now));
        break;
      default:
        finalUpdates = updates;
    }

    final result = await (update(kitchenOrders)..where((t) => t.id.equals(id)))
        .write(finalUpdates)
        .then((count) => count > 0);

    // Sync table status based on KDS state change
    await _syncTableStatus(id, newStatus);

    return result;
  }

  /// Sync RestaurantTable status when KDS order status changes
  Future<void> _syncTableStatus(int kitchenOrderId, String newKdsStatus) async {
    final order = await (select(kitchenOrders)..where((t) => t.id.equals(kitchenOrderId))).getSingleOrNull();
    if (order == null) return;

    final sale = await (select(sales)..where((s) => s.id.equals(order.saleId))).getSingleOrNull();
    if (sale == null || sale.tableId == null) return;

    final tableStatus = switch (newKdsStatus) {
      'PREPARING' => 'PREPARING',
      'READY' => 'SERVED',
      'SERVED' => 'CHECKOUT',
      _ => null,
    };
    if (tableStatus == null) return;

    await (update(restaurantTables)..where((t) => t.id.equals(sale.tableId!)))
        .write(RestaurantTablesCompanion(
      status: Value(tableStatus),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// PENDING → PREPARING
  Future<bool> startPreparing(int id) {
    return updateOrderStatus(id, 'PREPARING');
  }

  /// PREPARING → READY
  Future<bool> markAsReady(int id) {
    return updateOrderStatus(id, 'READY');
  }

  /// READY → SERVED
  Future<bool> markAsServed(int id) {
    return updateOrderStatus(id, 'SERVED');
  }

  /// U-23: saleId로 해당 sale의 모든 kitchen orders를 SERVED로 변경
  /// POS에서 결제 완료 시 주방에도 즉시 반영되도록
  Future<void> serveOrdersBySaleId(int saleId) async {
    final orders = await (select(kitchenOrders)
          ..where((t) => t.saleId.equals(saleId) & t.status.isNotIn(['CANCELLED', 'SERVED'])))
        .get();
    final now = DateTime.now();
    for (final order in orders) {
      await (update(kitchenOrders)..where((t) => t.id.equals(order.id))).write(
        KitchenOrdersCompanion(
          status: const Value('SERVED'),
          servedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    }
  }

  /// B-UAT: saleId로 해당 sale의 모든 kitchen orders를 CANCELLED로 변경
  /// POS에서 주문 취소 시 주방에도 즉시 반영되도록
  Future<void> cancelOrdersBySaleId(int saleId, {String? cancellationReason}) async {
    final orders = await (select(kitchenOrders)
          ..where((t) => t.saleId.equals(saleId) & t.status.isNotIn(['CANCELLED', 'SERVED'])))
        .get();
    final now = DateTime.now();
    for (final order in orders) {
      await (update(kitchenOrders)..where((t) => t.id.equals(order.id))).write(
        KitchenOrdersCompanion(
          status: const Value('CANCELLED'),
          cancelledAt: Value(now),
          updatedAt: Value(now),
          cancellationReason: Value(cancellationReason),
        ),
      );
    }
  }

  /// 주문 취소
  Future<bool> cancelOrder(int id, {String? cancellationReason}) async {
    final order = await getOrderById(id);
    if (order == null) return false;

    final now = DateTime.now();
    final result = await (update(kitchenOrders)..where((t) => t.id.equals(id))).write(
      KitchenOrdersCompanion(
        status: const Value('CANCELLED'),
        cancelledAt: Value(now),
        updatedAt: Value(now),
      ),
    ).then((count) => count > 0);

    if (result) {
      await _syncTableStatus(id, 'CANCELLED');
      await (update(sales)..where((s) => s.id.equals(order.saleId))).write(
        SalesCompanion(
          status: const Value('cancelled'),
          cancellationReason: Value(cancellationReason),
          cancelledAt: Value(now),
        ),
      );
    }

    return result;
  }

  // ============================================================
  // UPDATE - 기타
  // ============================================================

  /// 우선순위 변경
  Future<bool> updatePriority(int id, String priority) {
    return (update(kitchenOrders)..where((t) => t.id.equals(id)))
        .write(KitchenOrdersCompanion(
          priority: Value(priority),
          updatedAt: Value(DateTime.now()),
        ))
        .then((count) => count > 0);
  }

  /// 특별 지시사항 수정
  Future<bool> updateSpecialInstructions(int id, String? instructions) {
    return (update(kitchenOrders)..where((t) => t.id.equals(id)))
        .write(KitchenOrdersCompanion(
          specialInstructions: Value(instructions),
          updatedAt: Value(DateTime.now()),
        ))
        .then((count) => count > 0);
  }

  // ============================================================
  // DELETE
  // ============================================================

  /// 주문 삭제 (일반적으로 사용 안 함, 대신 CANCELLED 상태 사용)
  Future<int> deleteOrder(int id) {
    return (delete(kitchenOrders)..where((t) => t.id.equals(id))).go();
  }

  /// 완료된 주문 정리 (7일 이상 경과한 SERVED 주문)
  Future<int> cleanupOldServedOrders({int daysOld = 7}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    return (delete(kitchenOrders)
          ..where((t) => t.status.equals('SERVED'))
          ..where((t) => t.servedAt.isSmallerThanValue(cutoffDate)))
        .go();
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  /// 상태별 주문 개수 조회
  Future<int> countOrdersByStatus(String status) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = selectOnly(kitchenOrders)
      ..addColumns([kitchenOrders.id.count()])
      ..where(kitchenOrders.status.equals(status))
      ..where(kitchenOrders.createdAt.isBiggerOrEqualValue(startOfDay))
      ..where(kitchenOrders.createdAt.isSmallerThanValue(endOfDay));

    return query
        .map((row) => row.read(kitchenOrders.id.count()) ?? 0)
        .getSingle();
  }

  /// 오늘 처리된 주문 개수
  Future<int> countTodayServedOrders() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = selectOnly(kitchenOrders)
      ..addColumns([kitchenOrders.id.count()])
      ..where(kitchenOrders.status.equals('SERVED'))
      ..where(kitchenOrders.servedAt.isBiggerOrEqualValue(startOfDay))
      ..where(kitchenOrders.servedAt.isSmallerThanValue(endOfDay));

    return query
        .map((row) => row.read(kitchenOrders.id.count()) ?? 0)
        .getSingle();
  }

  /// 평균 조리 시간 계산 (초 단위) - 오늘 주문만
  /// T-9: startedAt/readyAt 없으면 createdAt→servedAt fallback 사용
  Future<double> calculateAveragePrepTime() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final orders = await (select(kitchenOrders)
          ..where((t) => t.status.equals('SERVED'))
          ..where((t) => t.createdAt.isBiggerOrEqualValue(startOfDay))
          ..where((t) => t.createdAt.isSmallerThanValue(endOfDay)))
        .get();

    if (orders.isEmpty) return 0.0;

    int totalSeconds = 0;
    int validCount = 0;

    for (final order in orders) {
      if (order.startedAt != null && order.readyAt != null) {
        // Preferred: startedAt → readyAt (KDS button flow)
        final duration = order.readyAt!.difference(order.startedAt!);
        totalSeconds += duration.inSeconds;
        validCount++;
      } else if (order.servedAt != null) {
        // Fallback: createdAt → servedAt (auto-serve flow)
        final duration = order.servedAt!.difference(order.createdAt);
        totalSeconds += duration.inSeconds;
        validCount++;
      }
    }

    if (validCount == 0) return 0.0;
    return totalSeconds / validCount;
  }
}
