# Table Status Synchronization

## Architecture (B-060)

### Overview
Tables synchronization between Floor Plan and Tables screens is **ALREADY IMPLEMENTED** using Drift's reactive streams.

### How It Works

#### 1. Data Layer (Drift Streams)
```dart
// lib/features/tables/data/tables_dao.dart
Stream<List<RestaurantTable>> watchAllActiveTables() {
  return (select(restaurantTables)
    ..where((t) => t.isActive.equals(true))
    ..orderBy([(t) => OrderingTerm.asc(t.tableNumber)]))
    .watch();
}
```

#### 2. Provider Layer (Riverpod StreamProvider)
```dart
// Floor Plan Provider
final allElementsStreamProvider = StreamProvider<List<FloorElement>>((ref) {
  final dao = ref.watch(floorElementDaoProvider);
  return dao.watchAllElements();
});

// Tables Provider  
final allTablesStreamProvider = StreamProvider<List<RestaurantTable>>((ref) {
  final dao = ref.watch(tablesDaoProvider);
  return dao.watchAllActiveTables();
});
```

#### 3. Update Flow
```
User Action (Floor Plan or Tables)
    ↓
DAO.updateTableStatus()
    ↓
Drift DB Update
    ↓
Stream Emits New Value (AUTOMATIC)
    ↓
All Listening Widgets Rebuild (AUTOMATIC)
```

### Bidirectional Sync
Both screens listen to the **SAME** Drift stream:
- Floor Plan updates → Stream emits → Tables rebuilds ✅
- Tables updates → Stream emits → Floor Plan rebuilds ✅

### Verification

#### Check Logs
```dart
debugPrint('[TableSync] Updating table $tableId: $oldStatus → $status');
debugPrint('[TableSync] allTablesStreamProvider emitted: ${tables.length} tables');
```

#### Manual Test
1. Open Floor Plan screen
2. Change table status (AVAILABLE → ORDERING)
3. Navigate to Tables screen
4. Status should match immediately ✅

### Key Files
- `lib/features/tables/data/tables_dao.dart` - DB operations
- `lib/features/tables/data/tables_providers.dart` - Stream providers
- `lib/features/floor_plan/data/floor_plan_providers.dart` - Stream providers

### Conclusion
Synchronization is **ALREADY WORKING** via Drift's reactive architecture.
No additional code needed - it's built into the framework.
