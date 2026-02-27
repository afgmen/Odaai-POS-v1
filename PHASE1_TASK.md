# Phase 1: 데이터 모델 개편 — 실행 태스크

## IMPORTANT: Read EVERY file you need to modify FIRST before writing anything!

## Task 1: CREATE `lib/features/pos/data/models/order_type.dart`
Create the directory path if needed, then create this file:

```dart
import 'package:flutter/material.dart';

enum OrderType {
  dineIn,
  takeaway,
  phoneDelivery,
  platformDelivery;

  String get displayNameEn {
    switch (this) {
      case OrderType.dineIn:
        return 'Dine In';
      case OrderType.takeaway:
        return 'Takeaway';
      case OrderType.phoneDelivery:
        return 'Phone Delivery';
      case OrderType.platformDelivery:
        return 'Platform Delivery';
    }
  }

  String get displayNameVi {
    switch (this) {
      case OrderType.dineIn:
        return 'Ăn tại chỗ';
      case OrderType.takeaway:
        return 'Mang đi';
      case OrderType.phoneDelivery:
        return 'Giao hàng qua điện thoại';
      case OrderType.platformDelivery:
        return 'Giao hàng qua nền tảng';
    }
  }

  IconData get icon {
    switch (this) {
      case OrderType.dineIn:
        return Icons.restaurant;
      case OrderType.takeaway:
        return Icons.shopping_bag_outlined;
      case OrderType.phoneDelivery:
        return Icons.phone_in_talk;
      case OrderType.platformDelivery:
        return Icons.delivery_dining;
    }
  }

  String get dbValue {
    switch (this) {
      case OrderType.dineIn:
        return 'dineIn';
      case OrderType.takeaway:
        return 'takeaway';
      case OrderType.phoneDelivery:
        return 'phoneDelivery';
      case OrderType.platformDelivery:
        return 'platformDelivery';
    }
  }

  static OrderType fromDb(String value) {
    switch (value) {
      case 'dineIn':
        return OrderType.dineIn;
      case 'takeaway':
        return OrderType.takeaway;
      case 'phoneDelivery':
        return OrderType.phoneDelivery;
      case 'platformDelivery':
        return OrderType.platformDelivery;
      default:
        return OrderType.dineIn;
    }
  }

  Color get color {
    switch (this) {
      case OrderType.dineIn:
        return const Color(0xFF4CAF50);
      case OrderType.takeaway:
        return const Color(0xFFFF9800);
      case OrderType.phoneDelivery:
        return const Color(0xFF2196F3);
      case OrderType.platformDelivery:
        return const Color(0xFF9C27B0);
    }
  }
}
```

## Task 2: MODIFY `lib/database/tables/sales.dart`
Add 6 columns to the Sales table (AFTER the existing `status` column and BEFORE `needsSync`):

```dart
// --- Phase 1: POS UX columns ---
TextColumn get orderType => text().withDefault(const Constant('dineIn'))();
IntColumn get tableId => integer().nullable()();
TextColumn get customerName => text().nullable()();
TextColumn get deliveryAddress => text().nullable()();
TextColumn get deliveryPhone => text().nullable()();
BoolColumn get isOpenTab => boolean().withDefault(const Constant(false))();
```

Do NOT add `.references(RestaurantTables, #id)` to tableId — the Sales table imports `products.dart` and adding a reference to store_tables_management.dart would create a circular import. Just use `integer().nullable()()`.

## Task 3: MODIFY `lib/database/tables/store_tables_management.dart`
In the `status` column comment, add 'ORDERING' and 'SERVED' to the list of valid statuses:
Change: `/// 테이블 상태 (AVAILABLE, RESERVED, OCCUPIED, CHECKOUT, CLEANING)`
To: `/// 테이블 상태 (AVAILABLE, RESERVED, OCCUPIED, ORDERING, SERVED, CHECKOUT, CLEANING)`

This is documentation only — the column is a TextColumn so any value works.

## Task 4: MODIFY `lib/database/app_database.dart`
1. Change `schemaVersion => 16` to `schemaVersion => 17`
2. Add migration block inside `onUpgrade`, after `if (from < 16)`:

```dart
if (from < 17) {
  // v16 → v17: POS UX Phase 1 — OrderType + Sales extension
  await _safeAddColumn('sales', 'order_type', "TEXT NOT NULL DEFAULT 'dineIn'");
  await _safeAddColumn('sales', 'table_id', 'INTEGER NULL');
  await _safeAddColumn('sales', 'customer_name', 'TEXT NULL');
  await _safeAddColumn('sales', 'delivery_address', 'TEXT NULL');
  await _safeAddColumn('sales', 'delivery_phone', 'TEXT NULL');
  await _safeAddColumn('sales', 'is_open_tab', 'INTEGER NOT NULL DEFAULT 0');
  // Index for open tab lookup by table
  await customStatement(
    'CREATE INDEX IF NOT EXISTS idx_sales_open_tab '
    'ON sales(table_id, is_open_tab) WHERE is_open_tab = 1'
  );
}
```

## Task 5: UPDATE `lib/database/daos/sales_dao.dart`
Add this method to the SalesDao class, at the end of the READ section:

```dart
/// Watch open tab for a specific table (Phase 1: Open Tab support)
Stream<Sale?> watchOpenTabByTableId(int tableId) {
  return (select(sales)
        ..where((s) =>
            s.tableId.equals(tableId) &
            s.isOpenTab.equals(true) &
            s.status.equals('open'))
        ..limit(1))
      .watchSingleOrNull();
}
```

## Task 6: Run build_runner and flutter analyze
```bash
cd /Users/macmini/.openclaw/workspace/Odaai-POS-v1
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
```

If flutter analyze shows errors, fix them. If it shows only info/warnings, that's acceptable.

## DO NOT:
- Change any file not listed above
- Add new dependencies to pubspec.yaml
- Run flutter test (tests may not be up to date)
- Modify generated .g.dart files manually (build_runner regenerates them)
