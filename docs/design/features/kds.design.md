# [Design] Kitchen Display System (KDS)

**Feature**: KDS (Kitchen Display System)
**Created**: 2024-02-08
**Status**: Design
**Plan Reference**: `docs/01-plan/features/kds.plan.md`

---

## 1. Architecture Design

### 1.1 System Architecture

```
┌────────────────────────────────────────────────────────────┐
│                      POS Module                             │
│  ┌─────────────────────┐                                   │
│  │  Payment Complete   │                                   │
│  │  Event Handler      │                                   │
│  └──────────┬──────────┘                                   │
└─────────────┼────────────────────────────────────────────┘
              │ triggers
              ▼
┌────────────────────────────────────────────────────────────┐
│                   Database Layer (Drift)                    │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────┐  │
│  │   Sales      │  │  SaleItems   │  │ KitchenOrders  │  │
│  │   (기존)      │  │   (기존)      │  │     (NEW)      │  │
│  └──────┬───────┘  └──────┬───────┘  └────────┬───────┘  │
│         │                  │                    │           │
│         └──────────────────┴────────────────────┘           │
│                            │                                 │
│                            │ watch/stream                    │
└────────────────────────────┼────────────────────────────────┘
                             │
              ┌──────────────┴──────────────┐
              ▼                             ▼
┌──────────────────────────┐  ┌──────────────────────────┐
│   KDS Provider Layer     │  │    Audio Service         │
│  (Riverpod)              │  │  (Notification Sounds)   │
│                          │  │                          │
│ - kitchenOrdersProvider  │  │ - newOrderSound()        │
│ - activeOrdersProvider   │  │ - urgentSound()          │
│ - orderStatusProvider    │  │ - warningSound()         │
│ - filterProvider         │  └──────────────────────────┘
└──────────┬───────────────┘
           │
           │ provides state
           ▼
┌────────────────────────────────────────────────────────────┐
│                   KDS Screen (UI)                           │
│  ┌──────────────────────────────────────────────────────┐ │
│  │                    App Bar                            │ │
│  │  [Kitchen Display] [Filter: All ▼] [Search 🔍]       │ │
│  └──────────────────────────────────────────────────────┘ │
│  ┌──────────────────────────────────────────────────────┐ │
│  │              Order Cards Grid                         │ │
│  │  ┌────────────┐ ┌────────────┐ ┌────────────┐       │ │
│  │  │ Order #001 │ │ Order #002 │ │ Order #003 │       │ │
│  │  │ PENDING    │ │ PREPARING  │ │ READY      │       │ │
│  │  │ 3 items    │ │ 2 items    │ │ 5 items    │       │ │
│  │  │ 5 min ago  │ │ 12 min ago │ │ 2 min ago  │       │ │
│  │  └────────────┘ └────────────┘ └────────────┘       │ │
│  └──────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────┘
```

### 1.2 Module Structure

```
lib/
├── features/
│   └── kds/                              # NEW - KDS Feature Module
│       ├── data/
│       │   ├── models/
│       │   │   └── kitchen_order.dart    # KitchenOrder model
│       │   ├── daos/
│       │   │   └── kitchen_orders_dao.dart
│       │   └── repositories/
│       │       └── kitchen_orders_repository.dart
│       ├── domain/
│       │   ├── enums/
│       │   │   ├── order_status.dart     # PENDING, PREPARING, READY, SERVED
│       │   │   └── order_priority.dart   # NORMAL, URGENT
│       │   └── services/
│       │       ├── audio_service.dart    # 알림음 재생
│       │       └── order_timer_service.dart # 대기 시간 계산
│       └── presentation/
│           ├── providers/
│           │   ├── kitchen_orders_provider.dart
│           │   ├── active_orders_provider.dart
│           │   ├── order_filter_provider.dart
│           │   └── audio_settings_provider.dart
│           ├── screens/
│           │   └── kds_screen.dart
│           └── widgets/
│               ├── order_card.dart
│               ├── order_detail_modal.dart
│               ├── filter_tabs.dart
│               └── empty_state.dart
│
├── database/
│   ├── tables/
│   │   ├── sales.dart                    # 기존
│   │   └── kitchen_orders.dart           # NEW
│   └── app_database.dart                 # KitchenOrders 테이블 추가
│
└── core/
    └── services/
        └── audio_player_service.dart     # audioplayers 래퍼
```

---

## 2. Database Design

### 2.1 New Table: KitchenOrders

**File**: `lib/database/tables/kitchen_orders.dart`

```dart
import 'package:drift/drift.dart';
import 'sales.dart';

class KitchenOrders extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Foreign Key
  IntColumn get saleId => integer().references(Sales, #id, onDelete: KeyAction.cascade)();

  // Status & Priority
  TextColumn get status => text().withDefault(const Constant('PENDING'))();
    // 'PENDING' | 'PREPARING' | 'READY' | 'SERVED' | 'CANCELLED'

  TextColumn get priority => text().withDefault(const Constant('NORMAL'))();
    // 'NORMAL' | 'URGENT'

  // Additional Info
  TextColumn get specialInstructions => text().nullable()();
  TextColumn get tableNumber => text().nullable()(); // 테이블 번호

  // Timestamps
  DateTimeColumn get startedAt => dateTime().nullable()(); // 조리 시작
  DateTimeColumn get readyAt => dateTime().nullable()();   // 완료
  DateTimeColumn get servedAt => dateTime().nullable()();  // 서빙
  DateTimeColumn get cancelledAt => dateTime().nullable()(); // 취소

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

**Indexes**:
```dart
// In app_database.dart
@override
List<TableInfo> get allTables => [
  // ... existing tables
  kitchenOrders,
];

// Add indexes for performance
CREATE INDEX idx_kitchen_orders_status ON kitchen_orders(status);
CREATE INDEX idx_kitchen_orders_created_at ON kitchen_orders(created_at DESC);
CREATE INDEX idx_kitchen_orders_sale_id ON kitchen_orders(sale_id);
```

### 2.2 Database Migration

**File**: `lib/database/migrations/migration_v4_add_kitchen_orders.dart`

```dart
// Migration from schema version 3 to 4
class MigrationV4 {
  static Future<void> migrate(Migrator m) async {
    // Create kitchen_orders table
    await m.create(KitchenOrders);

    // Create indexes
    await m.createIndex(Index(
      'idx_kitchen_orders_status',
      'CREATE INDEX idx_kitchen_orders_status ON kitchen_orders(status)',
    ));

    await m.createIndex(Index(
      'idx_kitchen_orders_created_at',
      'CREATE INDEX idx_kitchen_orders_created_at ON kitchen_orders(created_at DESC)',
    ));

    await m.createIndex(Index(
      'idx_kitchen_orders_sale_id',
      'CREATE INDEX idx_kitchen_orders_sale_id ON kitchen_orders(sale_id)',
    ));
  }
}
```

### 2.3 Data Flow Diagram

```
[POS Payment Complete]
        │
        ▼
[Create Sale Record]
        │
        ├──> Insert into Sales table
        ├──> Insert into SaleItems table
        └──> Insert into KitchenOrders table (status: PENDING)
                │
                ▼
        [Drift Stream Emit]
                │
                ▼
        [KDS Screen watches Stream]
                │
                ▼
        [UI Updates with new order]
                │
                ▼
        [Play notification sound]
```

---

## 3. Data Layer Design

### 3.1 KitchenOrder Model

**File**: `lib/features/kds/data/models/kitchen_order.dart`

```dart
import 'package:drift/drift.dart';
import '../../../../database/app_database.dart';

/// KitchenOrder with joined Sale and SaleItems
class KitchenOrderWithDetails {
  final KitchenOrder order;
  final Sale sale;
  final List<SaleItem> items;

  KitchenOrderWithDetails({
    required this.order,
    required this.sale,
    required this.items,
  });

  // Computed properties
  String get orderNumber => sale.saleNumber;
  DateTime get orderTime => order.createdAt;
  int get itemCount => items.length;

  Duration get waitingTime => DateTime.now().difference(orderTime);
  bool get isOverdue => waitingTime.inMinutes > 15;

  String get displayStatus {
    switch (order.status) {
      case 'PENDING': return 'Pending';
      case 'PREPARING': return 'Preparing';
      case 'READY': return 'Ready';
      case 'SERVED': return 'Served';
      case 'CANCELLED': return 'Cancelled';
      default: return order.status;
    }
  }
}
```

### 3.2 KitchenOrdersDao

**File**: `lib/features/kds/data/daos/kitchen_orders_dao.dart`

```dart
import 'package:drift/drift.dart';
import '../../../../database/app_database.dart';
import '../models/kitchen_order.dart';

part 'kitchen_orders_dao.g.dart';

@DriftAccessor(tables: [KitchenOrders, Sales, SaleItems])
class KitchenOrdersDao extends DatabaseAccessor<AppDatabase> with _$KitchenOrdersDaoMixin {
  KitchenOrdersDao(AppDatabase db) : super(db);

  // ══════════════════════════════════════════════════════════════
  // CREATE
  // ══════════════════════════════════════════════════════════════

  /// Create kitchen order from sale
  Future<int> createFromSale(int saleId, {String? tableNumber}) async {
    return into(kitchenOrders).insert(KitchenOrdersCompanion.insert(
      saleId: saleId,
      tableNumber: Value(tableNumber),
      status: const Value('PENDING'),
      priority: const Value('NORMAL'),
    ));
  }

  // ══════════════════════════════════════════════════════════════
  // READ
  // ══════════════════════════════════════════════════════════════

  /// Watch all active orders (not SERVED or CANCELLED)
  Stream<List<KitchenOrderWithDetails>> watchActiveOrders() {
    final query = select(kitchenOrders).join([
      leftOuterJoin(sales, sales.id.equalsExp(kitchenOrders.saleId)),
    ])..where(
      kitchenOrders.status.isNotIn(['SERVED', 'CANCELLED'])
    )..orderBy([
      OrderingTerm.desc(kitchenOrders.createdAt),
    ]);

    return query.watch().asyncMap((rows) async {
      final results = <KitchenOrderWithDetails>[];

      for (final row in rows) {
        final order = row.readTable(kitchenOrders);
        final sale = row.readTable(sales);

        // Get sale items
        final items = await (select(saleItems)
          ..where((t) => t.saleId.equals(sale.id)))
          .get();

        results.add(KitchenOrderWithDetails(
          order: order,
          sale: sale,
          items: items,
        ));
      }

      return results;
    });
  }

  /// Watch orders by status
  Stream<List<KitchenOrderWithDetails>> watchOrdersByStatus(String status) {
    final query = select(kitchenOrders).join([
      leftOuterJoin(sales, sales.id.equalsExp(kitchenOrders.saleId)),
    ])..where(kitchenOrders.status.equals(status))
     ..orderBy([OrderingTerm.desc(kitchenOrders.createdAt)]);

    return query.watch().asyncMap((rows) async {
      final results = <KitchenOrderWithDetails>[];

      for (final row in rows) {
        final order = row.readTable(kitchenOrders);
        final sale = row.readTable(sales);
        final items = await (select(saleItems)
          ..where((t) => t.saleId.equals(sale.id)))
          .get();

        results.add(KitchenOrderWithDetails(
          order: order,
          sale: sale,
          items: items,
        ));
      }

      return results;
    });
  }

  /// Get single order by ID
  Future<KitchenOrderWithDetails?> getOrderById(int orderId) async {
    final order = await (select(kitchenOrders)
      ..where((t) => t.id.equals(orderId)))
      .getSingleOrNull();

    if (order == null) return null;

    final sale = await (select(sales)
      ..where((t) => t.id.equals(order.saleId)))
      .getSingle();

    final items = await (select(saleItems)
      ..where((t) => t.saleId.equals(sale.id)))
      .get();

    return KitchenOrderWithDetails(
      order: order,
      sale: sale,
      items: items,
    );
  }

  // ══════════════════════════════════════════════════════════════
  // UPDATE
  // ══════════════════════════════════════════════════════════════

  /// Update order status
  Future<void> updateStatus(int orderId, String newStatus) async {
    final now = DateTime.now();

    await (update(kitchenOrders)..where((t) => t.id.equals(orderId))).write(
      KitchenOrdersCompanion(
        status: Value(newStatus),
        startedAt: newStatus == 'PREPARING' ? Value(now) : const Value.absent(),
        readyAt: newStatus == 'READY' ? Value(now) : const Value.absent(),
        servedAt: newStatus == 'SERVED' ? Value(now) : const Value.absent(),
        cancelledAt: newStatus == 'CANCELLED' ? Value(now) : const Value.absent(),
        updatedAt: Value(now),
      ),
    );
  }

  /// Set priority to URGENT
  Future<void> markAsUrgent(int orderId) async {
    await (update(kitchenOrders)..where((t) => t.id.equals(orderId))).write(
      const KitchenOrdersCompanion(
        priority: Value('URGENT'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // DELETE
  // ══════════════════════════════════════════════════════════════

  /// Delete old served/cancelled orders (cleanup)
  Future<int> deleteOldOrders({int daysToKeep = 7}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    return (delete(kitchenOrders)
      ..where((t) =>
        t.status.isIn(['SERVED', 'CANCELLED']) &
        t.updatedAt.isSmallerThanValue(cutoffDate)
      )
    ).go();
  }
}
```

### 3.3 Repository

**File**: `lib/features/kds/data/repositories/kitchen_orders_repository.dart`

```dart
import '../../../../database/app_database.dart';
import '../daos/kitchen_orders_dao.dart';
import '../models/kitchen_order.dart';

class KitchenOrdersRepository {
  final KitchenOrdersDao _dao;

  KitchenOrdersRepository(this._dao);

  // Stream APIs
  Stream<List<KitchenOrderWithDetails>> watchActiveOrders() =>
    _dao.watchActiveOrders();

  Stream<List<KitchenOrderWithDetails>> watchOrdersByStatus(String status) =>
    _dao.watchOrdersByStatus(status);

  // Query APIs
  Future<KitchenOrderWithDetails?> getOrderById(int orderId) =>
    _dao.getOrderById(orderId);

  // Command APIs
  Future<int> createFromSale(int saleId, {String? tableNumber}) =>
    _dao.createFromSale(saleId, tableNumber: tableNumber);

  Future<void> startPreparing(int orderId) =>
    _dao.updateStatus(orderId, 'PREPARING');

  Future<void> markReady(int orderId) =>
    _dao.updateStatus(orderId, 'READY');

  Future<void> markServed(int orderId) =>
    _dao.updateStatus(orderId, 'SERVED');

  Future<void> cancel(int orderId) =>
    _dao.updateStatus(orderId, 'CANCELLED');

  Future<void> markAsUrgent(int orderId) =>
    _dao.markAsUrgent(orderId);

  // Maintenance
  Future<int> cleanupOldOrders({int daysToKeep = 7}) =>
    _dao.deleteOldOrders(daysToKeep: daysToKeep);
}
```

---

## 4. Domain Layer Design

### 4.1 Enums

**File**: `lib/features/kds/domain/enums/order_status.dart`

```dart
enum OrderStatus {
  pending('PENDING', 'Pending'),
  preparing('PREPARING', 'Preparing'),
  ready('READY', 'Ready'),
  served('SERVED', 'Served'),
  cancelled('CANCELLED', 'Cancelled');

  final String code;
  final String label;

  const OrderStatus(this.code, this.label);

  static OrderStatus fromCode(String code) {
    return OrderStatus.values.firstWhere(
      (s) => s.code == code,
      orElse: () => OrderStatus.pending,
    );
  }
}
```

**File**: `lib/features/kds/domain/enums/order_priority.dart`

```dart
enum OrderPriority {
  normal('NORMAL'),
  urgent('URGENT');

  final String code;
  const OrderPriority(this.code);

  static OrderPriority fromCode(String code) {
    return OrderPriority.values.firstWhere(
      (p) => p.code == code,
      orElse: () => OrderPriority.normal,
    );
  }
}
```

### 4.2 Audio Service

**File**: `lib/features/kds/domain/services/audio_service.dart`

```dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  bool _isEnabled = true;

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  Future<void> playNewOrderSound() async {
    if (!_isEnabled) return;
    await _player.play(AssetSource('sounds/new_order.mp3'));
  }

  Future<void> playUrgentSound() async {
    if (!_isEnabled) return;
    await _player.play(AssetSource('sounds/urgent_order.mp3'));
  }

  Future<void> playWarningSound() async {
    if (!_isEnabled) return;
    await _player.play(AssetSource('sounds/warning.mp3'));
  }

  void dispose() {
    _player.dispose();
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});
```

### 4.3 Order Timer Service

**File**: `lib/features/kds/domain/services/order_timer_service.dart`

```dart
class OrderTimerService {
  static const int warningThresholdMinutes = 15;
  static const int criticalThresholdMinutes = 30;

  /// Calculate waiting time from order creation
  static Duration calculateWaitingTime(DateTime orderTime) {
    return DateTime.now().difference(orderTime);
  }

  /// Check if order is overdue (> 15 min)
  static bool isOverdue(DateTime orderTime) {
    return calculateWaitingTime(orderTime).inMinutes > warningThresholdMinutes;
  }

  /// Check if order is critical (> 30 min)
  static bool isCritical(DateTime orderTime) {
    return calculateWaitingTime(orderTime).inMinutes > criticalThresholdMinutes;
  }

  /// Format waiting time as string (e.g., "5m", "1h 20m")
  static String formatWaitingTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
```

---

## 5. Presentation Layer Design

### 5.1 Providers

**File**: `lib/features/kds/presentation/providers/kitchen_orders_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/database_providers.dart';
import '../../data/daos/kitchen_orders_dao.dart';
import '../../data/models/kitchen_order.dart';
import '../../data/repositories/kitchen_orders_repository.dart';

// DAO Provider
final kitchenOrdersDaoProvider = Provider<KitchenOrdersDao>((ref) {
  final db = ref.watch(databaseProvider);
  return KitchenOrdersDao(db);
});

// Repository Provider
final kitchenOrdersRepositoryProvider = Provider<KitchenOrdersRepository>((ref) {
  final dao = ref.watch(kitchenOrdersDaoProvider);
  return KitchenOrdersRepository(dao);
});

// Stream Provider: Active Orders
final activeOrdersProvider = StreamProvider<List<KitchenOrderWithDetails>>((ref) {
  final repo = ref.watch(kitchenOrdersRepositoryProvider);
  return repo.watchActiveOrders();
});

// Stream Provider: Orders by Status
final ordersByStatusProvider = StreamProvider.family<List<KitchenOrderWithDetails>, String>(
  (ref, status) {
    final repo = ref.watch(kitchenOrdersRepositoryProvider);
    return repo.watchOrdersByStatus(status);
  },
);
```

**File**: `lib/features/kds/presentation/providers/order_filter_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum OrderFilter {
  all,
  pending,
  preparing,
  ready;

  String get statusCode {
    switch (this) {
      case OrderFilter.pending: return 'PENDING';
      case OrderFilter.preparing: return 'PREPARING';
      case OrderFilter.ready: return 'READY';
      case OrderFilter.all: return 'ALL';
    }
  }

  String get label {
    switch (this) {
      case OrderFilter.all: return 'All';
      case OrderFilter.pending: return 'Pending';
      case OrderFilter.preparing: return 'Preparing';
      case OrderFilter.ready: return 'Ready';
    }
  }
}

final orderFilterProvider = StateProvider<OrderFilter>((ref) => OrderFilter.all);

final searchQueryProvider = StateProvider<String>((ref) => '');
```

**File**: `lib/features/kds/presentation/providers/audio_settings_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioSettingsNotifier extends StateNotifier<bool> {
  AudioSettingsNotifier() : super(true) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('kds_audio_enabled') ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('kds_audio_enabled', state);
  }
}

final audioEnabledProvider = StateNotifierProvider<AudioSettingsNotifier, bool>(
  (ref) => AudioSettingsNotifier(),
);
```

### 5.2 Screen Structure

**File**: `lib/features/kds/presentation/screens/kds_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/kitchen_orders_provider.dart';
import '../providers/order_filter_provider.dart';
import '../widgets/filter_tabs.dart';
import '../widgets/order_card.dart';
import '../widgets/empty_state.dart';

class KdsScreen extends ConsumerWidget {
  const KdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final filter = ref.watch(orderFilterProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    // Watch orders based on filter
    final ordersAsync = filter == OrderFilter.all
        ? ref.watch(activeOrdersProvider)
        : ref.watch(ordersByStatusProvider(filter.statusCode));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(context, ref, l10n),
      body: Column(
        children: [
          // Filter Tabs
          const FilterTabs(),

          // Search Bar (if needed)
          if (searchQuery.isNotEmpty) _buildSearchBar(ref, l10n),

          // Orders Grid
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                // Apply search filter
                final filteredOrders = searchQuery.isEmpty
                    ? orders
                    : orders.where((o) =>
                        o.orderNumber.toLowerCase().contains(searchQuery.toLowerCase()) ||
                        (o.order.tableNumber?.contains(searchQuery) ?? false)
                      ).toList();

                if (filteredOrders.isEmpty) {
                  return const EmptyState();
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisExtent: 280,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    return OrderCard(order: filteredOrders[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return AppBar(
      title: Text(l10n.kitchenDisplay),
      centerTitle: false,
      actions: [
        // Search button
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => _showSearchDialog(context, ref, l10n),
        ),

        // Audio toggle
        Consumer(
          builder: (context, ref, child) {
            final audioEnabled = ref.watch(audioEnabledProvider);
            return IconButton(
              icon: Icon(audioEnabled ? Icons.volume_up : Icons.volume_off),
              onPressed: () => ref.read(audioEnabledProvider.notifier).toggle(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar(WidgetRef ref, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.cardWhite,
      child: TextField(
        decoration: InputDecoration(
          hintText: l10n.searchByOrderOrTable,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => ref.read(searchQueryProvider.notifier).state = '',
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
      ),
    );
  }

  void _showSearchDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    // Show search dialog implementation
  }
}
```

### 5.3 Widget: Order Card

**File**: `lib/features/kds/presentation/widgets/order_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/kitchen_order.dart';
import '../../domain/enums/order_status.dart';
import '../../domain/services/order_timer_service.dart';
import '../providers/kitchen_orders_provider.dart';
import 'order_detail_modal.dart';

class OrderCard extends ConsumerWidget {
  final KitchenOrderWithDetails order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = OrderStatus.fromCode(order.order.status);
    final isOverdue = order.isOverdue;
    final waitingTime = OrderTimerService.formatWaitingTime(order.waitingTime);

    return Card(
      elevation: 4,
      color: _getBackgroundColor(status, isOverdue),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showDetailModal(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Order Number + Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.orderNumber,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOverdue ? Colors.red : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      waitingTime,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isOverdue ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Table Number (if available)
              if (order.order.tableNumber != null)
                Text(
                  'Table ${order.order.tableNumber}',
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),

              const SizedBox(height: 12),

              // Items List (first 3)
              ...order.items.take(3).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      '${item.quantity}x',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.productName,
                        style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),

              if (order.items.length > 3)
                Text(
                  '+ ${order.items.length - 3} more items',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textDisabled),
                ),

              const Spacer(),

              // Action Buttons
              Row(
                children: _buildActionButtons(context, ref, status),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(OrderStatus status, bool isOverdue) {
    if (isOverdue) return Colors.red.shade50;

    switch (status) {
      case OrderStatus.pending:
        return Colors.orange.shade50;
      case OrderStatus.preparing:
        return Colors.blue.shade50;
      case OrderStatus.ready:
        return Colors.green.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  List<Widget> _buildActionButtons(BuildContext context, WidgetRef ref, OrderStatus status) {
    final repo = ref.read(kitchenOrdersRepositoryProvider);

    switch (status) {
      case OrderStatus.pending:
        return [
          Expanded(
            child: ElevatedButton(
              onPressed: () => repo.startPreparing(order.order.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Start'),
            ),
          ),
        ];

      case OrderStatus.preparing:
        return [
          Expanded(
            child: ElevatedButton(
              onPressed: () => repo.markReady(order.order.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ready'),
            ),
          ),
        ];

      case OrderStatus.ready:
        return [
          Expanded(
            child: ElevatedButton(
              onPressed: () => repo.markServed(order.order.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: const Text('Served'),
            ),
          ),
        ];

      default:
        return [];
    }
  }

  void _showDetailModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => OrderDetailModal(order: order),
    );
  }
}
```

---

## 6. Integration Points

### 6.1 POS Payment Integration

**File**: `lib/features/pos/presentation/widgets/payment_modal.dart`

Add after successful payment:

```dart
// After creating sale record
final saleId = await salesDao.createSale(...);

// Create kitchen order
final kitchenOrdersDao = ref.read(kitchenOrdersDaoProvider);
await kitchenOrdersDao.createFromSale(
  saleId,
  tableNumber: tableNumber, // Get from table selection if available
);
```

### 6.2 Navigation

**File**: `lib/main.dart`

Add KDS route:

```dart
// In main navigation
DrawerListTile(
  icon: Icons.restaurant_menu,
  title: l10n.kitchenDisplay,
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const KdsScreen()),
  ),
),
```

---

## 7. Localization

**File**: `lib/l10n/app_en.arb`

```json
{
  "kitchenDisplay": "Kitchen Display",
  "orderNumber": "Order #",
  "tableNumber": "Table",
  "pending": "Pending",
  "preparing": "Preparing",
  "ready": "Ready",
  "served": "Served",
  "startPreparing": "Start",
  "markReady": "Ready",
  "markServed": "Served",
  "searchByOrderOrTable": "Search by order or table number",
  "noActiveOrders": "No active orders",
  "orderDetails": "Order Details",
  "specialInstructions": "Special Instructions",
  "urgentOrder": "Urgent Order",
  "overdueOrder": "Overdue Order"
}
```

---

## 8. Testing Strategy

### 8.1 Unit Tests

```dart
// test/features/kds/data/daos/kitchen_orders_dao_test.dart
void main() {
  test('createFromSale creates PENDING order', () async {
    // ...
  });

  test('updateStatus to PREPARING sets startedAt', () async {
    // ...
  });
}
```

### 8.2 Widget Tests

```dart
// test/features/kds/presentation/widgets/order_card_test.dart
void main() {
  testWidgets('OrderCard displays order number', (tester) async {
    // ...
  });
}
```

### 8.3 Integration Tests

```dart
// integration_test/kds_flow_test.dart
void main() {
  testWidgets('Complete order flow from POS to KDS', (tester) async {
    // 1. Create sale in POS
    // 2. Verify order appears in KDS
    // 3. Update status to PREPARING
    // 4. Update status to READY
    // 5. Update status to SERVED
  });
}
```

---

## 9. Performance Considerations

### 9.1 Database Optimization

- Index on `status` column for fast filtering
- Index on `created_at` for sorting
- Cascade delete on foreign key to prevent orphaned records

### 9.2 Stream Optimization

- Use `asyncMap` for efficient joins
- Debounce rapid status changes
- Limit active orders query to last 24 hours

### 9.3 UI Optimization

- Use `GridView.builder` for lazy loading
- Implement pagination for large order lists
- Cache order detail modals

---

## 10. Dependencies

### 10.1 New Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  # Existing...
  audioplayers: ^6.0.0  # Audio notifications

assets:
  - assets/sounds/new_order.mp3
  - assets/sounds/urgent_order.mp3
  - assets/sounds/warning.mp3
```

---

## 11. File Checklist

### Database
- [x] `lib/database/tables/kitchen_orders.dart`
- [x] Migration script in `app_database.dart`

### Data Layer
- [x] `lib/features/kds/data/models/kitchen_order.dart`
- [x] `lib/features/kds/data/daos/kitchen_orders_dao.dart`
- [x] `lib/features/kds/data/repositories/kitchen_orders_repository.dart`

### Domain Layer
- [x] `lib/features/kds/domain/enums/order_status.dart`
- [x] `lib/features/kds/domain/enums/order_priority.dart`
- [x] `lib/features/kds/domain/services/audio_service.dart`
- [x] `lib/features/kds/domain/services/order_timer_service.dart`

### Presentation Layer
- [x] `lib/features/kds/presentation/providers/kitchen_orders_provider.dart`
- [x] `lib/features/kds/presentation/providers/order_filter_provider.dart`
- [x] `lib/features/kds/presentation/providers/audio_settings_provider.dart`
- [x] `lib/features/kds/presentation/screens/kds_screen.dart`
- [x] `lib/features/kds/presentation/widgets/order_card.dart`
- [x] `lib/features/kds/presentation/widgets/order_detail_modal.dart`
- [x] `lib/features/kds/presentation/widgets/filter_tabs.dart`
- [x] `lib/features/kds/presentation/widgets/empty_state.dart`

### Assets
- [ ] `assets/sounds/new_order.mp3`
- [ ] `assets/sounds/urgent_order.mp3`
- [ ] `assets/sounds/warning.mp3`

---

## 12. Implementation Order

1. **Phase 1: Database** (Day 1 Morning)
   - Create `kitchen_orders.dart` table
   - Write migration script
   - Test migration

2. **Phase 2: Data Layer** (Day 1 Afternoon)
   - Create DAO
   - Create Repository
   - Create Providers
   - Unit tests

3. **Phase 3: Domain Layer** (Day 2 Morning)
   - Create enums
   - Create services
   - Test audio service

4. **Phase 4: UI Components** (Day 2 Afternoon - Day 3)
   - Create OrderCard widget
   - Create KDS screen
   - Create filter tabs
   - Create detail modal

5. **Phase 5: Integration** (Day 3 Afternoon)
   - Integrate with POS payment flow
   - Add navigation
   - Add localization

6. **Phase 6: Testing & Polish** (Day 4)
   - Integration tests
   - UI polish
   - Performance optimization

---

**Next Step**: `/pdca do kds` - Start implementation

**Design Approval**: Awaiting review before implementation
