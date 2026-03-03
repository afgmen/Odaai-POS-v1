# 테이블 관리 (Table Management) - Design Document

**Feature**: Table Management
**Version**: 1.0.0
**Created**: 2026-02-08
**Author**: AI Development Team
**Status**: Design Phase
**Plan Reference**: `docs/01-plan/features/table-management.plan.md`

---

## 1. Architecture Overview

### 1.1 Layer Structure (Clean Architecture)

```
┌───────────────────────────────────────────────────────────────────┐
│                     Presentation Layer                            │
│  ┌──────────────────────┐  ┌──────────────────────────────────┐  │
│  │ TableLayoutScreen    │  │ ReservationScreen                │  │
│  │ - Drag & Drop Canvas │  │ - Reservation Form               │  │
│  │ - Table Widgets      │  │ - Calendar View                  │  │
│  │ - Status Filter      │  │ - Reservation List               │  │
│  └──────────────────────┘  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │              Providers (Riverpod)                            │ │
│  │  - tableLayoutProvider                                       │ │
│  │  - tablesStreamProvider                                      │ │
│  │  - reservationsStreamProvider                                │ │
│  │  - filteredTablesProvider                                    │ │
│  └──────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────────────┐
│                       Domain Layer                                │
│  ┌──────────────────────┐  ┌──────────────────────────────────┐  │
│  │ TableStatus Enum     │  │ ReservationStatus Enum           │  │
│  │ - AVAILABLE          │  │ - PENDING                        │  │
│  │ - RESERVED           │  │ - CONFIRMED                      │  │
│  │ - OCCUPIED           │  │ - SEATED                         │  │
│  │ - CHECKOUT           │  │ - CANCELLED                      │  │
│  │ - CLEANING           │  │ - NO_SHOW                        │  │
│  └──────────────────────┘  └──────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────────────┐
│                        Data Layer                                 │
│  ┌──────────────────────┐  ┌──────────────────────────────────┐  │
│  │ TablesDao            │  │ ReservationsDao                  │  │
│  │ - CRUD operations    │  │ - CRUD operations                │  │
│  │ - Stream watchers    │  │ - Stream watchers                │  │
│  │ - Status updates     │  │ - Date range queries             │  │
│  └──────────────────────┘  └──────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────────────┐
│                    Database (Drift SQLite)                        │
│  ┌──────────────────────┐  ┌──────────────────────────────────┐  │
│  │ tables               │  │ reservations                     │  │
│  │ - id (PK)            │  │ - id (PK)                        │  │
│  │ - table_number       │  │ - table_id (FK)                  │  │
│  │ - seats              │  │ - customer_name                  │  │
│  │ - position_x/y       │  │ - customer_phone                 │  │
│  │ - status             │  │ - party_size                     │  │
│  │ - current_sale_id    │  │ - reservation_date               │  │
│  │ - occupied_at        │  │ - reservation_time               │  │
│  │ - reservation_id     │  │ - status                         │  │
│  └──────────────────────┘  └──────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────┘
```

### 1.2 Integration Points

```
┌──────────────┐
│   POS        │ Payment Complete Event
│   System     │─────────────┐
└──────────────┘             │
                             ▼
                    ┌─────────────────┐
                    │ Table Management│
                    │   - Update      │────► KDS Display
                    │     Status      │      (show table info)
                    │   - Link Sale   │
                    └─────────────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  Sales Table    │
                    │  (table_number) │
                    └─────────────────┘
```

---

## 2. Database Design

### 2.1 Schema Version Upgrade (v8 → v9)

#### 2.1.1 New Tables

**tables 테이블**
```dart
class Tables extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tableNumber => text().withLength(min: 1, max: 10).unique()();
  IntColumn get seats => integer().withDefault(const Constant(4))();
  RealColumn get positionX => real().withDefault(const Constant(0))();
  RealColumn get positionY => real().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('AVAILABLE'))();
  IntColumn get currentSaleId => integer().nullable().references(Sales, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get occupiedAt => dateTime().nullable()();
  IntColumn get reservationId => integer().nullable().references(Reservations, #id, onDelete: KeyAction.setNull)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

**reservations 테이블**
```dart
class Reservations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tableId => integer().nullable().references(Tables, #id, onDelete: KeyAction.setNull)();
  TextColumn get customerName => text().withLength(min: 1, max: 100)();
  TextColumn get customerPhone => text().withLength(min: 10, max: 20)();
  IntColumn get partySize => integer()();
  DateTimeColumn get reservationDate => dateTime()();
  TextColumn get reservationTime => text()(); // HH:mm format
  TextColumn get status => text().withDefault(const Constant('PENDING'))();
  TextColumn get specialRequests => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

#### 2.1.2 Indexes

```dart
// In migration onCreate:
await customStatement(
  'CREATE INDEX idx_tables_status ON tables(status)'
);
await customStatement(
  'CREATE INDEX idx_tables_table_number ON tables(table_number)'
);
await customStatement(
  'CREATE INDEX idx_reservations_date ON reservations(reservation_date, reservation_time)'
);
await customStatement(
  'CREATE INDEX idx_reservations_status ON reservations(status)'
);
await customStatement(
  'CREATE INDEX idx_reservations_customer_phone ON reservations(customer_phone)'
);
```

#### 2.1.3 Migration Script (v8 → v9)

```dart
// In app_database.dart - onUpgrade method
if (from < 9) {
  // Create tables table
  await m.createTable(tables);

  // Create reservations table
  await m.createTable(reservations);

  // Create indexes
  await customStatement(
    'CREATE INDEX idx_tables_status ON tables(status)'
  );
  await customStatement(
    'CREATE INDEX idx_tables_table_number ON tables(table_number)'
  );
  await customStatement(
    'CREATE INDEX idx_reservations_date ON reservations(reservation_date, reservation_time)'
  );
  await customStatement(
    'CREATE INDEX idx_reservations_status ON reservations(status)'
  );
  await customStatement(
    'CREATE INDEX idx_reservations_customer_phone ON reservations(customer_phone)'
  );

  // Seed default tables (optional)
  await _seedDefaultTables();
}
```

#### 2.1.4 Default Seed Data

```dart
Future<void> _seedDefaultTables() async {
  // Create 10 default tables in 2 rows
  final defaultTables = [
    // Row 1
    TablesCompanion.insert(
      tableNumber: '1',
      seats: const Value(4),
      positionX: const Value(50.0),
      positionY: const Value(50.0),
    ),
    TablesCompanion.insert(
      tableNumber: '2',
      seats: const Value(4),
      positionX: const Value(200.0),
      positionY: const Value(50.0),
    ),
    // ... (total 10 tables)
  ];

  for (final table in defaultTables) {
    await into(tables).insert(table);
  }
}
```

### 2.2 State Transitions

#### 2.2.1 TableStatus State Machine

```
┌──────────────┐
│  AVAILABLE   │ (빈 테이블)
└──────┬───────┘
       │
       ├─(예약 등록)──────► RESERVED (예약됨)
       │                         │
       │                         │(예약 고객 착석)
       │                         ▼
       └─(워크인 고객 착석)──► OCCUPIED (착석 중)
                                 │
                                 │(결제 완료)
                                 ▼
                              CHECKOUT (계산 완료)
                                 │
                                 │(테이블 정리 시작)
                                 ▼
                              CLEANING (정리 중)
                                 │
                                 │(정리 완료)
                                 ▼
                              AVAILABLE
```

#### 2.2.2 ReservationStatus State Machine

```
┌──────────────┐
│   PENDING    │ (예약 대기)
└──────┬───────┘
       │
       ├─(매니저 확인)──────► CONFIRMED (예약 확정)
       │                           │
       │                           ├─(고객 착석)──► SEATED (착석 완료)
       │                           │
       │                           └─(노쇼)──────► NO_SHOW
       │
       └─(취소 요청)──────► CANCELLED (예약 취소)
```

---

## 3. Data Layer Implementation

### 3.1 File Structure

```
lib/features/tables/
├── data/
│   ├── tables_dao.dart                 # Tables DAO
│   ├── reservations_dao.dart           # Reservations DAO
│   ├── tables_providers.dart           # Riverpod providers
│   └── models/
│       ├── table_with_reservation.dart # Composite model
│       └── reservation_summary.dart    # Summary model
├── domain/
│   └── enums/
│       ├── table_status.dart           # TableStatus enum
│       └── reservation_status.dart     # ReservationStatus enum
└── presentation/
    ├── screens/
    │   ├── table_layout_screen.dart    # Main layout screen
    │   └── reservations_screen.dart    # Reservations screen
    ├── widgets/
    │   ├── table_widget.dart           # Draggable table widget
    │   ├── table_detail_modal.dart     # Table detail modal
    │   ├── reservation_form.dart       # Reservation form
    │   └── status_filter_tabs.dart     # Status filter tabs
    └── providers/
        ├── table_layout_provider.dart  # Layout state
        └── reservation_provider.dart   # Reservation state
```

### 3.2 TablesDao Design

```dart
@DriftAccessor(tables: [Tables, Sales, Reservations])
class TablesDao extends DatabaseAccessor<AppDatabase> with _$TablesDaoMixin {
  TablesDao(AppDatabase db) : super(db);

  // ============================================================
  // CREATE
  // ============================================================

  /// 새 테이블 생성
  Future<int> createTable(TablesCompanion table) {
    return into(tables).insert(table);
  }

  // ============================================================
  // READ - Single
  // ============================================================

  /// ID로 테이블 조회
  Future<Table?> getTableById(int id) {
    return (select(tables)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 테이블 번호로 조회
  Future<Table?> getTableByNumber(String tableNumber) {
    return (select(tables)..where((t) => t.tableNumber.equals(tableNumber)))
        .getSingleOrNull();
  }

  // ============================================================
  // READ - List
  // ============================================================

  /// 모든 활성 테이블 조회
  Future<List<Table>> getAllActiveTables() {
    return (select(tables)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.tableNumber)]))
        .get();
  }

  /// 상태별 테이블 조회
  Future<List<Table>> getTablesByStatus(String status) {
    return (select(tables)
          ..where((t) => t.status.equals(status) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.tableNumber)]))
        .get();
  }

  // ============================================================
  // STREAM - Real-time Updates
  // ============================================================

  /// 모든 활성 테이블 실시간 스트림
  Stream<List<Table>> watchAllActiveTables() {
    return (select(tables)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.tableNumber)]))
        .watch();
  }

  /// 상태별 테이블 실시간 스트림
  Stream<List<Table>> watchTablesByStatus(String status) {
    return (select(tables)
          ..where((t) => t.status.equals(status) & t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.tableNumber)]))
        .watch();
  }

  /// 테이블 상세 정보 스트림 (예약 정보 포함)
  Stream<TableWithReservation?> watchTableWithReservation(int tableId) {
    final query = select(tables).join([
      leftOuterJoin(
        reservations,
        reservations.id.equalsExp(tables.reservationId),
      ),
    ])..where(tables.id.equals(tableId));

    return query.watch().map((rows) {
      if (rows.isEmpty) return null;
      final row = rows.first;
      return TableWithReservation(
        table: row.readTable(tables),
        reservation: row.readTableOrNull(reservations),
      );
    });
  }

  // ============================================================
  // UPDATE
  // ============================================================

  /// 테이블 상태 업데이트
  Future<bool> updateTableStatus({
    required int tableId,
    required String status,
    int? currentSaleId,
    DateTime? occupiedAt,
    int? reservationId,
  }) {
    return (update(tables)..where((t) => t.id.equals(tableId))).write(
      TablesCompanion(
        status: Value(status),
        currentSaleId: Value(currentSaleId),
        occupiedAt: Value(occupiedAt),
        reservationId: Value(reservationId),
        updatedAt: Value(DateTime.now()),
      ),
    ).then((count) => count > 0);
  }

  /// 테이블 위치 업데이트 (드래그앤드롭)
  Future<bool> updateTablePosition({
    required int tableId,
    required double x,
    required double y,
  }) {
    return (update(tables)..where((t) => t.id.equals(tableId))).write(
      TablesCompanion(
        positionX: Value(x),
        positionY: Value(y),
        updatedAt: Value(DateTime.now()),
      ),
    ).then((count) => count > 0);
  }

  /// 테이블 정보 수정 (번호, 좌석 수)
  Future<bool> updateTableInfo({
    required int tableId,
    String? tableNumber,
    int? seats,
  }) {
    return (update(tables)..where((t) => t.id.equals(tableId))).write(
      TablesCompanion(
        tableNumber: tableNumber != null ? Value(tableNumber) : const Value.absent(),
        seats: seats != null ? Value(seats) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    ).then((count) => count > 0);
  }

  // ============================================================
  // DELETE
  // ============================================================

  /// 테이블 소프트 삭제 (isActive = false)
  Future<bool> softDeleteTable(int tableId) {
    return (update(tables)..where((t) => t.id.equals(tableId))).write(
      TablesCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    ).then((count) => count > 0);
  }

  /// 테이블 영구 삭제 (테스트용)
  Future<int> hardDeleteTable(int tableId) {
    return (delete(tables)..where((t) => t.id.equals(tableId))).go();
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  /// 상태별 테이블 개수
  Future<Map<String, int>> getTableCountByStatus() async {
    final allTables = await getAllActiveTables();
    final counts = <String, int>{};
    for (final table in allTables) {
      counts[table.status] = (counts[table.status] ?? 0) + 1;
    }
    return counts;
  }

  /// 평균 테이블 회전율 (오늘)
  Future<double> getAverageTableTurnoverToday() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = selectOnly(sales)
      ..addColumns([sales.id.count()])
      ..where(
        sales.saleDate.isBetweenValues(startOfDay, endOfDay) &
        sales.tableNumber.isNotNull(),
      );

    final result = await query.getSingle();
    final totalSales = result.read(sales.id.count()) ?? 0;

    final activeTables = await getAllActiveTables();
    if (activeTables.isEmpty) return 0;

    return totalSales / activeTables.length;
  }
}
```

### 3.3 ReservationsDao Design

```dart
@DriftAccessor(tables: [Reservations, Tables])
class ReservationsDao extends DatabaseAccessor<AppDatabase>
    with _$ReservationsDaoMixin {
  ReservationsDao(AppDatabase db) : super(db);

  // ============================================================
  // CREATE
  // ============================================================

  /// 새 예약 생성
  Future<int> createReservation(ReservationsCompanion reservation) {
    return into(reservations).insert(reservation);
  }

  // ============================================================
  // READ - Single
  // ============================================================

  /// ID로 예약 조회
  Future<Reservation?> getReservationById(int id) {
    return (select(reservations)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
  }

  // ============================================================
  // READ - List
  // ============================================================

  /// 날짜별 예약 목록 조회
  Future<List<Reservation>> getReservationsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(reservations)
          ..where((r) => r.reservationDate.isBetweenValues(startOfDay, endOfDay))
          ..orderBy([(r) => OrderingTerm.asc(r.reservationTime)]))
        .get();
  }

  /// 상태별 예약 목록 조회
  Future<List<Reservation>> getReservationsByStatus(String status) {
    return (select(reservations)
          ..where((r) => r.status.equals(status))
          ..orderBy([
            (r) => OrderingTerm.asc(r.reservationDate),
            (r) => OrderingTerm.asc(r.reservationTime),
          ]))
        .get();
  }

  /// 오늘 예약 목록 조회
  Future<List<Reservation>> getTodayReservations() {
    return getReservationsByDate(DateTime.now());
  }

  /// 이번 주 예약 목록 조회
  Future<List<Reservation>> getWeekReservations() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return (select(reservations)
          ..where((r) => r.reservationDate.isBetweenValues(startOfWeek, endOfWeek))
          ..orderBy([
            (r) => OrderingTerm.asc(r.reservationDate),
            (r) => OrderingTerm.asc(r.reservationTime),
          ]))
        .get();
  }

  // ============================================================
  // STREAM - Real-time Updates
  // ============================================================

  /// 날짜별 예약 실시간 스트림
  Stream<List<Reservation>> watchReservationsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(reservations)
          ..where((r) => r.reservationDate.isBetweenValues(startOfDay, endOfDay))
          ..orderBy([(r) => OrderingTerm.asc(r.reservationTime)]))
        .watch();
  }

  /// 오늘 예약 실시간 스트림
  Stream<List<Reservation>> watchTodayReservations() {
    return watchReservationsByDate(DateTime.now());
  }

  // ============================================================
  // UPDATE
  // ============================================================

  /// 예약 상태 업데이트
  Future<bool> updateReservationStatus({
    required int reservationId,
    required String status,
  }) {
    return (update(reservations)..where((r) => r.id.equals(reservationId)))
        .write(
      ReservationsCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    ).then((count) => count > 0);
  }

  /// 예약 테이블 배정
  Future<bool> assignTableToReservation({
    required int reservationId,
    required int tableId,
  }) {
    return (update(reservations)..where((r) => r.id.equals(reservationId)))
        .write(
      ReservationsCompanion(
        tableId: Value(tableId),
        updatedAt: Value(DateTime.now()),
      ),
    ).then((count) => count > 0);
  }

  /// 예약 수정
  Future<bool> updateReservation({
    required int reservationId,
    String? customerName,
    String? customerPhone,
    int? partySize,
    DateTime? reservationDate,
    String? reservationTime,
    String? specialRequests,
  }) {
    return (update(reservations)..where((r) => r.id.equals(reservationId)))
        .write(
      ReservationsCompanion(
        customerName: customerName != null ? Value(customerName) : const Value.absent(),
        customerPhone: customerPhone != null ? Value(customerPhone) : const Value.absent(),
        partySize: partySize != null ? Value(partySize) : const Value.absent(),
        reservationDate: reservationDate != null ? Value(reservationDate) : const Value.absent(),
        reservationTime: reservationTime != null ? Value(reservationTime) : const Value.absent(),
        specialRequests: Value(specialRequests),
        updatedAt: Value(DateTime.now()),
      ),
    ).then((count) => count > 0);
  }

  // ============================================================
  // DELETE
  // ============================================================

  /// 예약 삭제
  Future<int> deleteReservation(int reservationId) {
    return (delete(reservations)..where((r) => r.id.equals(reservationId))).go();
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  /// 상태별 예약 개수
  Future<Map<String, int>> getReservationCountByStatus() async {
    final allReservations = await (select(reservations).get());
    final counts = <String, int>{};
    for (final reservation in allReservations) {
      counts[reservation.status] = (counts[reservation.status] ?? 0) + 1;
    }
    return counts;
  }

  /// 오늘 노쇼 개수
  Future<int> getTodayNoShowCount() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = selectOnly(reservations)
      ..addColumns([reservations.id.count()])
      ..where(
        reservations.reservationDate.isBetweenValues(startOfDay, endOfDay) &
        reservations.status.equals('NO_SHOW'),
      );

    final result = await query.getSingle();
    return result.read(reservations.id.count()) ?? 0;
  }
}
```

### 3.4 Composite Models

**TableWithReservation**
```dart
class TableWithReservation {
  final Table table;
  final Reservation? reservation;

  const TableWithReservation({
    required this.table,
    this.reservation,
  });

  bool get hasReservation => reservation != null;
  bool get isReserved => table.status == 'RESERVED' && hasReservation;

  String get displayInfo {
    if (hasReservation) {
      return '${reservation!.customerName} (${reservation!.partySize}명)';
    }
    return '빈 테이블';
  }
}
```

---

## 4. Domain Layer Implementation

### 4.1 TableStatus Enum

```dart
/// 테이블 상태
enum TableStatus {
  available('AVAILABLE', '빈 테이블', Color(0xFF4CAF50)),
  reserved('RESERVED', '예약됨', Color(0xFFFF9800)),
  occupied('OCCUPIED', '착석 중', Color(0xFFF44336)),
  checkout('CHECKOUT', '계산 완료', Color(0xFF9C27B0)),
  cleaning('CLEANING', '정리 중', Color(0xFF2196F3));

  final String value;
  final String label;
  final Color color;

  const TableStatus(this.value, this.label, this.color);

  /// String → Enum 변환
  static TableStatus fromString(String value) {
    return TableStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TableStatus.available,
    );
  }

  /// 다음 상태로 전환 가능 여부
  bool canTransitionTo(TableStatus next) {
    switch (this) {
      case TableStatus.available:
        return next == TableStatus.reserved || next == TableStatus.occupied;
      case TableStatus.reserved:
        return next == TableStatus.occupied || next == TableStatus.available;
      case TableStatus.occupied:
        return next == TableStatus.checkout;
      case TableStatus.checkout:
        return next == TableStatus.cleaning;
      case TableStatus.cleaning:
        return next == TableStatus.available;
    }
  }

  /// 자동 전환 (시간 기반)
  TableStatus? getAutoTransition() {
    switch (this) {
      case TableStatus.checkout:
        return TableStatus.cleaning; // 결제 완료 후 5분 → 정리 중
      case TableStatus.cleaning:
        return TableStatus.available; // 정리 중 10분 후 → 빈 테이블
      default:
        return null;
    }
  }
}
```

### 4.2 ReservationStatus Enum

```dart
/// 예약 상태
enum ReservationStatus {
  pending('PENDING', '예약 대기', Color(0xFF9E9E9E)),
  confirmed('CONFIRMED', '예약 확정', Color(0xFF4CAF50)),
  seated('SEATED', '착석 완료', Color(0xFF2196F3)),
  cancelled('CANCELLED', '예약 취소', Color(0xFFE0E0E0)),
  noShow('NO_SHOW', '노쇼', Color(0xFFF44336));

  final String value;
  final String label;
  final Color color;

  const ReservationStatus(this.value, this.label, this.color);

  /// String → Enum 변환
  static ReservationStatus fromString(String value) {
    return ReservationStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReservationStatus.pending,
    );
  }

  /// 다음 상태로 전환 가능 여부
  bool canTransitionTo(ReservationStatus next) {
    switch (this) {
      case ReservationStatus.pending:
        return next == ReservationStatus.confirmed || next == ReservationStatus.cancelled;
      case ReservationStatus.confirmed:
        return next == ReservationStatus.seated ||
            next == ReservationStatus.noShow ||
            next == ReservationStatus.cancelled;
      case ReservationStatus.seated:
      case ReservationStatus.cancelled:
      case ReservationStatus.noShow:
        return false; // 종료 상태
    }
  }
}
```

---

## 5. Presentation Layer Implementation

### 5.1 Riverpod Providers

**tables_providers.dart**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import '../../../providers/database_providers.dart';
import '../data/tables_dao.dart';
import '../data/models/table_with_reservation.dart';

// ============================================================
// DAO Provider
// ============================================================

final tablesDaoProvider = Provider<TablesDao>((ref) {
  final database = ref.watch(databaseProvider);
  return database.tablesDao;
});

// ============================================================
// Stream Providers (실시간 데이터)
// ============================================================

/// 모든 활성 테이블 스트림
final allTablesStreamProvider = StreamProvider<List<Table>>((ref) {
  final dao = ref.watch(tablesDaoProvider);
  return dao.watchAllActiveTables();
});

/// 상태별 테이블 스트림
final tablesByStatusStreamProvider = StreamProvider.family<List<Table>, String>(
  (ref, status) {
    final dao = ref.watch(tablesDaoProvider);
    return dao.watchTablesByStatus(status);
  },
);

// ============================================================
// State Providers
// ============================================================

/// 선택된 테이블 필터 (null = 전체)
final selectedTableStatusProvider = StateProvider<String?>((ref) => null);

/// 필터링된 테이블 목록
final filteredTablesProvider = StreamProvider<List<Table>>((ref) {
  final allTablesAsync = ref.watch(allTablesStreamProvider);
  final selectedStatus = ref.watch(selectedTableStatusProvider);

  return allTablesAsync.when(
    data: (allTables) {
      if (selectedStatus == null) {
        return Stream.value(allTables);
      }
      final filtered = allTables.where((t) => t.status == selectedStatus).toList();
      return Stream.value(filtered);
    },
    loading: () => Stream.value([]),
    error: (err, stack) => Stream.value([]),
  ).asyncExpand((tables) => tables);
});

/// 선택된 테이블 ID
final selectedTableIdProvider = StateProvider<int?>((ref) => null);

/// 테이블 상세 모달 표시 상태
final showTableDetailProvider = StateProvider<bool>((ref) => false);

// ============================================================
// Statistics Providers
// ============================================================

/// 상태별 테이블 개수
final tableCountByStatusProvider = FutureProvider<Map<String, int>>((ref) {
  final dao = ref.watch(tablesDaoProvider);
  return dao.getTableCountByStatus();
});

/// 평균 테이블 회전율
final avgTableTurnoverProvider = FutureProvider<double>((ref) {
  final dao = ref.watch(tablesDaoProvider);
  return dao.getAverageTableTurnoverToday();
});
```

**reservations_providers.dart**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import '../../../providers/database_providers.dart';
import '../data/reservations_dao.dart';

// ============================================================
// DAO Provider
// ============================================================

final reservationsDaoProvider = Provider<ReservationsDao>((ref) {
  final database = ref.watch(databaseProvider);
  return database.reservationsDao;
});

// ============================================================
// Stream Providers
// ============================================================

/// 오늘 예약 스트림
final todayReservationsStreamProvider = StreamProvider<List<Reservation>>((ref) {
  final dao = ref.watch(reservationsDaoProvider);
  return dao.watchTodayReservations();
});

/// 날짜별 예약 스트림
final reservationsByDateStreamProvider = StreamProvider.family<List<Reservation>, DateTime>(
  (ref, date) {
    final dao = ref.watch(reservationsDaoProvider);
    return dao.watchReservationsByDate(date);
  },
);

// ============================================================
// State Providers
// ============================================================

/// 선택된 날짜 (예약 캘린더)
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// 예약 폼 표시 상태
final showReservationFormProvider = StateProvider<bool>((ref) => false);

/// 선택된 예약 ID
final selectedReservationIdProvider = StateProvider<int?>((ref) => null);

// ============================================================
// Statistics Providers
// ============================================================

/// 상태별 예약 개수
final reservationCountByStatusProvider = FutureProvider<Map<String, int>>((ref) {
  final dao = ref.watch(reservationsDaoProvider);
  return dao.getReservationCountByStatus();
});

/// 오늘 노쇼 개수
final todayNoShowCountProvider = FutureProvider<int>((ref) {
  final dao = ref.watch(reservationsDaoProvider);
  return dao.getTodayNoShowCount();
});
```

### 5.2 UI Screens

#### 5.2.1 TableLayoutScreen (Main)

**File**: `lib/features/tables/presentation/screens/table_layout_screen.dart`

**Features**:
- 드래그앤드롭 테이블 배치
- 테이블 상태 시각화 (색상 코딩)
- 상태 필터 탭
- 테이블 추가/삭제 버튼
- 실시간 상태 업데이트

**Layout**:
```
┌──────────────────────────────────────────────────┐
│ Table Management                         [+ Add] │
├──────────────────────────────────────────────────┤
│ [All] [Available] [Reserved] [Occupied] [...]    │ ← Status Filter Tabs
├──────────────────────────────────────────────────┤
│                                                  │
│   ┌─────┐          ┌─────┐          ┌─────┐    │
│   │ T1  │          │ T2  │          │ T3  │    │ ← Draggable Table Widgets
│   │ 🟢  │          │ 🟠  │          │ 🔴  │    │   (Color = Status)
│   └─────┘          └─────┘          └─────┘    │
│                                                  │
│   ┌─────┐          ┌─────┐                      │
│   │ T4  │          │ T5  │                      │
│   │ 🟢  │          │ 🔵  │                      │
│   └─────┘          └─────┘                      │
│                                                  │
└──────────────────────────────────────────────────┘
```

**Key Components**:
- `StatusFilterTabs`: 상태별 필터 탭
- `TableWidget`: 개별 테이블 위젯 (드래그 가능)
- `AddTableButton`: 테이블 추가 버튼
- `TableDetailModal`: 테이블 상세 정보 모달

#### 5.2.2 ReservationsScreen

**File**: `lib/features/tables/presentation/screens/reservations_screen.dart`

**Features**:
- 날짜별 예약 목록
- 캘린더 뷰
- 예약 등록/수정/취소
- 테이블 배정

**Layout**:
```
┌──────────────────────────────────────────────────┐
│ Reservations                       [+ New]       │
├──────────────────────────────────────────────────┤
│ ┌──────────────────────────────────────────────┐ │
│ │     📅 2026-02-08 (Today)                    │ │ ← Calendar
│ └──────────────────────────────────────────────┘ │
├──────────────────────────────────────────────────┤
│ 🕐 10:00 - Kim Minho (4명) - Table 5  [✓]      │ ← Reservation List
│ 🕐 12:30 - Lee Sujin (2명) - Table 3  [✓]      │
│ 🕐 18:00 - Park Jieun (6명) - Not assigned [?]  │
├──────────────────────────────────────────────────┤
│ Stats: 3 confirmed | 1 pending | 0 no-show      │
└──────────────────────────────────────────────────┘
```

**Key Components**:
- `ReservationCalendar`: 캘린더 위젯
- `ReservationList`: 예약 목록
- `ReservationForm`: 예약 등록/수정 폼
- `TableAssignmentButton`: 테이블 배정 버튼

### 5.3 Key Widgets

#### 5.3.1 TableWidget (Draggable)

```dart
class TableWidget extends StatelessWidget {
  final Table table;
  final VoidCallback onTap;
  final Function(Offset)? onDragEnd;

  const TableWidget({
    Key? key,
    required this.table,
    required this.onTap,
    this.onDragEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = TableStatus.fromString(table.status);

    return Positioned(
      left: table.positionX,
      top: table.positionY,
      child: Draggable<Table>(
        data: table,
        feedback: _buildTableCard(status, isDragging: true),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildTableCard(status),
        ),
        onDragEnd: (details) {
          if (onDragEnd != null) {
            onDragEnd!(details.offset);
          }
        },
        child: GestureDetector(
          onTap: onTap,
          child: _buildTableCard(status),
        ),
      ),
    );
  }

  Widget _buildTableCard(TableStatus status, {bool isDragging = false}) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.2),
        border: Border.all(color: status.color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            table.tableNumber,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: status.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              color: status.color,
            ),
          ),
          if (table.seats > 0)
            Text(
              '${table.seats}인석',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}
```

#### 5.3.2 TableDetailModal

```dart
class TableDetailModal extends ConsumerWidget {
  final int tableId;

  const TableDetailModal({Key? key, required this.tableId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(tablesDaoProvider);

    return StreamBuilder<TableWithReservation?>(
      stream: dao.watchTableWithReservation(tableId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final table = data.table;
        final reservation = data.reservation;
        final status = TableStatus.fromString(table.status);

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Table ${table.tableNumber}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: status.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(color: status.color, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),

              // Table Info
              _buildInfoRow('좌석 수', '${table.seats}명'),
              if (table.occupiedAt != null)
                _buildInfoRow('착석 시간', _formatTime(table.occupiedAt!)),

              // Reservation Info
              if (reservation != null) ...[
                const Divider(height: 32),
                const Text('예약 정보', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildInfoRow('고객명', reservation.customerName),
                _buildInfoRow('전화번호', reservation.customerPhone),
                _buildInfoRow('인원', '${reservation.partySize}명'),
                _buildInfoRow('예약 시간', reservation.reservationTime),
              ],

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _changeStatus(context, ref, table),
                      child: const Text('상태 변경'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _editTable(context, ref, table),
                      child: const Text('정보 수정'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _changeStatus(BuildContext context, WidgetRef ref, Table table) async {
    // Show status change dialog
    // Update table status using TablesDao
  }

  Future<void> _editTable(BuildContext context, WidgetRef ref, Table table) async {
    // Show table edit dialog
    // Update table info using TablesDao
  }
}
```

---

## 6. POS/KDS Integration

### 6.1 POS Integration

**위치**: `lib/features/pos/presentation/screens/pos_screen.dart`

**변경 사항**:
1. 결제 플로우에 테이블 선택 단계 추가
2. Sale 생성 시 `table_number` 필드 채우기
3. 결제 완료 시 테이블 상태 업데이트

```dart
// In POS Screen - Payment flow
Future<void> _completeSale(BuildContext context, WidgetRef ref) async {
  // 1. Show table selection dialog
  final selectedTable = await showDialog<Table>(
    context: context,
    builder: (context) => const TableSelectionDialog(),
  );

  if (selectedTable == null) return; // User cancelled

  // 2. Create sale with table info
  final saleId = await salesDao.createSale(
    SalesCompanion.insert(
      // ... other fields
      tableNumber: Value(selectedTable.tableNumber),
    ),
  );

  // 3. Update table status to OCCUPIED
  await tablesDao.updateTableStatus(
    tableId: selectedTable.id,
    status: 'OCCUPIED',
    currentSaleId: saleId,
    occupiedAt: DateTime.now(),
  );

  // 4. Create KDS order
  await kitchenOrdersDao.createOrderFromSale(
    saleId: saleId,
    tableNumber: selectedTable.tableNumber,
  );

  // Success!
}
```

### 6.2 KDS Integration

**위치**: `lib/features/kds/presentation/widgets/order_card.dart`

**변경 사항**:
1. OrderCard에 테이블 번호 표시
2. 서빙 완료 시 테이블 상태 업데이트

```dart
// In KDS OrderCard Widget
Widget build(BuildContext context) {
  final order = orderWithItems.order;

  return Card(
    child: Column(
      children: [
        // Table Number Badge (큰 표시)
        if (order.tableNumber != null)
          Container(
            padding: const EdgeInsets.all(8),
            color: AppTheme.primary,
            child: Text(
              'Table ${order.tableNumber}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

        // ... menu items, status, etc.

        // Complete Button
        ElevatedButton(
          onPressed: () => _completeOrder(context, ref),
          child: const Text('서빙 완료'),
        ),
      ],
    ),
  );
}

Future<void> _completeOrder(BuildContext context, WidgetRef ref) async {
  final order = orderWithItems.order;

  // 1. Update KDS order status to SERVED
  await kitchenOrdersDao.updateOrderStatus(
    orderId: order.id,
    status: 'SERVED',
  );

  // 2. Update table status to CHECKOUT
  if (order.tableNumber != null) {
    final table = await tablesDao.getTableByNumber(order.tableNumber!);
    if (table != null) {
      await tablesDao.updateTableStatus(
        tableId: table.id,
        status: 'CHECKOUT',
      );
    }
  }
}
```

---

## 7. Implementation Order

### 7.1 Phase 1: Database & Models (Days 1-2)

**Day 1: Database Migration**
1. ✅ Create `Tables` table definition
2. ✅ Create `Reservations` table definition
3. ✅ Add tables to `@DriftDatabase` annotation
4. ✅ Update `schemaVersion` to 9
5. ✅ Write migration script (v8 → v9)
6. ✅ Add indexes
7. ✅ Seed default tables (optional)
8. ✅ Test migration

**Day 2: DAO Layer**
1. ✅ Create `TablesDao` with all CRUD methods
2. ✅ Create `ReservationsDao` with all CRUD methods
3. ✅ Create composite models (`TableWithReservation`)
4. ✅ Add to database DAOs list
5. ✅ Test DAO methods

### 7.2 Phase 2: Domain Layer (Days 3-4)

**Day 3: Enums**
1. ✅ Create `TableStatus` enum with state machine
2. ✅ Create `ReservationStatus` enum with state machine
3. ✅ Add color coding
4. ✅ Add transition validation

**Day 4: Providers**
1. ✅ Create `tables_providers.dart`
2. ✅ Create `reservations_providers.dart`
3. ✅ Add DAO providers
4. ✅ Add Stream providers
5. ✅ Add state providers
6. ✅ Add statistics providers

### 7.3 Phase 3: UI - Layout Editor (Days 5-6)

**Day 5: Basic Layout Screen**
1. ✅ Create `TableLayoutScreen` scaffold
2. ✅ Create `TableWidget` (draggable)
3. ✅ Implement drag & drop functionality
4. ✅ Add table add/delete buttons
5. ✅ Connect to providers

**Day 6: Advanced Features**
1. ✅ Implement status filter tabs
2. ✅ Add grid snapping (optional)
3. ✅ Implement layout save/load
4. ✅ Add table edit functionality
5. ✅ Polish UI/UX

### 7.4 Phase 4: UI - Status & Reservation (Days 7-8)

**Day 7: Status Management**
1. ✅ Create `TableDetailModal`
2. ✅ Implement status change dialog
3. ✅ Add real-time status updates
4. ✅ Add table info editing

**Day 8: Reservation UI**
1. ✅ Create `ReservationsScreen`
2. ✅ Create `ReservationForm`
3. ✅ Implement calendar view (using `table_calendar`)
4. ✅ Add reservation list
5. ✅ Implement reservation CRUD

### 7.5 Phase 5: Integration & Testing (Days 9-10)

**Day 9: POS/KDS Integration**
1. ✅ Add table selection to POS payment flow
2. ✅ Update Sale schema to include `table_number`
3. ✅ Connect KDS to display table info
4. ✅ Implement auto status sync

**Day 10: Testing & Polish**
1. ✅ End-to-end testing
2. ✅ Fix bugs
3. ✅ Performance optimization
4. ✅ UI/UX polish
5. ✅ Gap analysis (Match Rate ≥ 90%)

---

## 8. Critical Files List

### 8.1 Database Layer
- `lib/database/tables/tables.dart` (NEW)
- `lib/database/tables/reservations.dart` (NEW)
- `lib/database/app_database.dart` (MODIFY - add tables, update schema)

### 8.2 Data Layer
- `lib/features/tables/data/tables_dao.dart` (NEW)
- `lib/features/tables/data/reservations_dao.dart` (NEW)
- `lib/features/tables/data/tables_providers.dart` (NEW)
- `lib/features/tables/data/reservations_providers.dart` (NEW)
- `lib/features/tables/data/models/table_with_reservation.dart` (NEW)

### 8.3 Domain Layer
- `lib/features/tables/domain/enums/table_status.dart` (NEW)
- `lib/features/tables/domain/enums/reservation_status.dart` (NEW)

### 8.4 Presentation Layer
- `lib/features/tables/presentation/screens/table_layout_screen.dart` (NEW)
- `lib/features/tables/presentation/screens/reservations_screen.dart` (NEW)
- `lib/features/tables/presentation/widgets/table_widget.dart` (NEW)
- `lib/features/tables/presentation/widgets/table_detail_modal.dart` (NEW)
- `lib/features/tables/presentation/widgets/reservation_form.dart` (NEW)
- `lib/features/tables/presentation/widgets/status_filter_tabs.dart` (NEW)

### 8.5 Integration Points
- `lib/features/pos/presentation/screens/pos_screen.dart` (MODIFY)
- `lib/features/kds/presentation/widgets/order_card.dart` (MODIFY)
- `lib/database/tables/sales.dart` (MODIFY - add table_number if not exists)

---

## 9. Dependencies

### 9.1 New Dependencies

**pubspec.yaml**
```yaml
dependencies:
  # Existing
  flutter:
    sdk: flutter
  drift: ^2.16.0
  flutter_riverpod: ^2.5.1

  # NEW
  table_calendar: ^3.1.0  # For reservation calendar
```

**Installation**:
```bash
flutter pub add table_calendar
flutter pub get
```

### 9.2 Feature Dependencies

- ✅ **POS System** (existing)
- ✅ **KDS** (existing)
- ✅ **Sales Management** (existing)
- ⚠️ **Customer Management** (optional - for linking customer to reservation)

---

## 10. Testing Strategy

### 10.1 Unit Tests

**TablesDao Tests**
- ✅ Create table
- ✅ Get table by ID
- ✅ Get table by number
- ✅ Update table status
- ✅ Update table position
- ✅ Soft delete table
- ✅ Get table count by status

**ReservationsDao Tests**
- ✅ Create reservation
- ✅ Get reservation by ID
- ✅ Get reservations by date
- ✅ Update reservation status
- ✅ Assign table to reservation
- ✅ Delete reservation

### 10.2 Integration Tests

**POS Integration**
- ✅ Complete sale with table selection
- ✅ Table status updates to OCCUPIED
- ✅ KDS order created with table info

**KDS Integration**
- ✅ Order displays table number
- ✅ Complete order updates table to CHECKOUT

### 10.3 Manual Testing Scenarios

1. **Table Lifecycle**
   - ✅ Add new table
   - ✅ Drag table to new position
   - ✅ Edit table info (number, seats)
   - ✅ Change table status
   - ✅ Delete table

2. **Reservation Lifecycle**
   - ✅ Create reservation
   - ✅ Confirm reservation
   - ✅ Assign table
   - ✅ Seat customer (reservation → table occupied)
   - ✅ Cancel reservation
   - ✅ Mark as no-show

3. **POS → Table → KDS Flow**
   - ✅ Select table in POS
   - ✅ Complete payment
   - ✅ Verify KDS shows table info
   - ✅ Complete order in KDS
   - ✅ Verify table status = CHECKOUT

---

## 11. Performance Considerations

### 11.1 Optimizations

1. **Drag & Drop Performance**
   - Use `RepaintBoundary` for table widgets
   - Debounce position updates (500ms)
   - Only save final position to DB

2. **Real-time Updates**
   - Use Drift Stream watchers (efficient)
   - Client-side filtering for status
   - Limit to 100 tables (performance threshold)

3. **Database Queries**
   - Indexes on `status`, `table_number`, `reservation_date`
   - Avoid N+1 queries with JOIN
   - Use `selectOnly` for counts

### 11.2 Memory Management

- Dispose StreamProviders when not needed
- Limit reservation history to 30 days
- Auto-delete old reservations (> 90 days)

---

## 12. Security & Validation

### 12.1 Input Validation

**Table Creation**
- ✅ Table number: 1-10 characters, alphanumeric
- ✅ Seats: 1-20
- ✅ Position: 0-1000 (canvas bounds)

**Reservation Creation**
- ✅ Customer name: 1-100 characters
- ✅ Phone: 10-20 digits
- ✅ Party size: 1-20
- ✅ Reservation date: Today or future
- ✅ Reservation time: HH:mm format

### 12.2 State Transition Validation

- ✅ Use `canTransitionTo()` method in enums
- ✅ Prevent invalid status changes
- ✅ Log state transition errors

---

## 13. Future Enhancements (v1.1+)

### 13.1 v1.1.0 Features
- 테이블 합치기/나누기
- 자동 테이블 배정 알고리즘
- 테이블 서비스 시간 목표 설정
- 웨이팅 리스트 (대기 고객 관리)

### 13.2 v2.0.0 Features
- QR 코드 메뉴판 연동
- 고객용 예약 앱
- 포인트 적립 시스템 연동
- 고급 통계 및 리포트

---

## 14. Acceptance Criteria Checklist

### 14.1 Functional Requirements

**테이블 관리**
- [ ] 테이블 추가/삭제/이동 가능
- [ ] 드래그앤드롭으로 위치 변경
- [ ] 테이블 번호, 좌석 수 설정 가능
- [ ] 5가지 상태 시각화 (색상 코딩)
- [ ] 실시간 상태 업데이트

**예약 관리**
- [ ] 예약 등록 (이름, 전화번호, 날짜, 시간, 인원)
- [ ] 예약 목록 조회 (오늘, 이번 주)
- [ ] 예약 확정/취소 가능
- [ ] 노쇼 처리 가능
- [ ] 테이블 배정 가능

**POS 연동**
- [ ] 결제 시 테이블 선택 가능
- [ ] Sale에 table_number 저장
- [ ] 결제 완료 시 테이블 상태 OCCUPIED로 변경

**KDS 연동**
- [ ] KDS 화면에 테이블 정보 표시
- [ ] 서빙 완료 시 테이블 상태 CHECKOUT로 변경

### 14.2 Non-Functional Requirements

**Performance**
- [ ] 테이블 상태 업데이트 < 500ms
- [ ] 레이아웃 로딩 < 1s
- [ ] 50개 테이블 렌더링 < 2s

**Usability**
- [ ] 직관적인 드래그앤드롭 UI
- [ ] 명확한 상태 색상 구분
- [ ] 간단한 예약 등록 플로우

**Reliability**
- [ ] 데이터 손실 0%
- [ ] Migration 성공률 100%
- [ ] Stream 동기화 안정성

---

## 15. Sign-off

### 15.1 Design Review

- [ ] **Architecture Approved**: Clean Architecture 준수
- [ ] **Database Schema Approved**: Migration script 검증 완료
- [ ] **UI/UX Approved**: Wireframe 및 flow 확인
- [ ] **Integration Points Approved**: POS/KDS 연동 설계 확인

### 15.2 Ready for Implementation

- [ ] **Plan Document Reviewed**: `table-management.plan.md` 기반
- [ ] **Design Document Complete**: 모든 섹션 작성 완료
- [ ] **Dependencies Identified**: `table_calendar` 추가 필요
- [ ] **Timeline Confirmed**: 10일 일정 확인

**Next Step**: `/pdca do table-management` (Implementation Phase)

---

**Document Version**: 1.0.0
**Last Updated**: 2026-02-08
**Next Phase**: Implementation (Do Phase)
