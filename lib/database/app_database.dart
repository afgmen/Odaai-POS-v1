import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

// 조건부 import: 플랫폼에 따라 적절한 DB 연결 사용
import 'connection/unsupported.dart'
    if (dart.library.ffi) 'connection/native.dart'
    if (dart.library.html) 'connection/web.dart' as connection;

import 'daos/customers_dao.dart';
import 'daos/employees_dao.dart';
import 'daos/categories_dao.dart';
import 'daos/modifier_dao.dart';
import 'daos/products_dao.dart';
import 'daos/sales_dao.dart';
import 'daos/sync_dao.dart';
import 'daos/permissions_dao.dart';
import 'daos/role_permissions_dao.dart';
import 'daos/user_roles_dao.dart';
import 'daos/store_assignments_dao.dart';
import '../features/loyalty/data/loyalty_dao.dart';
import '../features/backup/data/backup_dao.dart';
import '../features/attendance/data/attendance_dao.dart';
import '../features/kds/data/kitchen_orders_dao.dart';
import '../features/tables/data/tables_dao.dart';
import '../features/tables/data/reservations_dao.dart';
import '../features/auth/data/permission_logs_dao.dart';
import '../features/daily_closing/data/daily_closing_dao.dart';
import '../features/delivery/data/delivery_orders_dao.dart';
import '../features/promotions/data/promotions_dao.dart';
import '../features/floor_plan/data/floor_zone_dao.dart';
import '../features/floor_plan/data/floor_element_dao.dart';
import 'tables/delivery_orders.dart';
import 'tables/floor_zones.dart';
import 'tables/floor_elements.dart';
import 'tables/floor_plan_config.dart';
import 'tables/employees.dart';
import 'tables/products.dart';
import 'tables/promotions.dart';
import 'tables/promotion_products.dart';
import 'tables/sales.dart';
import 'tables/sync_queue.dart';
import 'tables/point_transactions.dart';
import 'tables/membership_tiers.dart';
import 'tables/loyalty_settings.dart';
import 'tables/backup_logs.dart';
import 'tables/backup_settings.dart';
import 'tables/attendance_logs.dart';
import 'tables/leave_requests.dart';
import 'tables/work_schedules.dart';
import 'tables/leave_balances.dart';
import 'tables/kitchen_orders.dart';
import 'tables/store_tables_management.dart';
import 'tables/reservations.dart';
import 'tables/permission_logs.dart';
import 'tables/daily_closings.dart';
import 'tables/permissions.dart';
import 'tables/categories.dart';
import 'tables/product_modifiers.dart';
import 'tables/role_permissions.dart';
import 'tables/user_roles.dart';
import 'tables/store_assignments.dart';
import 'tables/system_settings.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Products,
    StockMovements,
    Sales,
    SaleItems,
    Employees,
    Customers,
    SyncQueue,
    Promotions,
    PromotionProducts, // B-082: 프로모션-제품 연결
    CashDrawerLogs,
    Refunds,
    RefundItems,
    PointTransactions,
    MembershipTiers,
    LoyaltySettings,
    BackupLogs,
    BackupSettings,
    AttendanceLogs,
    LeaveRequests,
    WorkSchedules,
    LeaveBalances,
    KitchenOrders,
    RestaurantTables,
    Reservations,
    PermissionLogs,
    DailyClosings,
    Permissions,
    RolePermissions,
    UserRoles,
    StoreAssignments,
    SystemSettings,
    DeliveryOrders,
    FloorZones,
    FloorElements,
    FloorPlanConfig,
    Categories,
    ModifierGroups,
    ModifierOptions,
    ProductModifierLinks,
    SaleItemModifiers,
  ],
  daos: [
    ProductsDao,
    SalesDao,
    SyncDao,
    CustomersDao,
    EmployeesDao,
    LoyaltyDao,
    BackupDao,
    AttendanceDao,
    KitchenOrdersDao,
    TablesDao,
    ReservationsDao,
    PermissionLogsDao,
    DailyClosingDao,
    PermissionsDao,
    RolePermissionsDao,
    UserRolesDao,
    StoreAssignmentsDao,
    DeliveryOrdersDao,
    FloorZoneDao,
    FloorElementDao,
    CategoriesDao,
    ModifierDao,
    PromotionsDao, // B-082
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(connection.openConnection());

  AppDatabase.forTesting(super.executor);

  // DAO getters
  late final salesDao = SalesDao(this);
  late final customersDao = CustomersDao(this);
  late final employeesDao = EmployeesDao(this);
  late final kitchenOrdersDao = KitchenOrdersDao(this);
  late final modifierDao = ModifierDao(this);
  late final categoriesDao = CategoriesDao(this);
  late final deliveryOrdersDao = DeliveryOrdersDao(this);
  late final permissionsDao = PermissionsDao(this);
  late final permissionLogsDao = PermissionLogsDao(this);
  late final rolePermissionsDao = RolePermissionsDao(this);
  late final userRolesDao = UserRolesDao(this);
  late final storeAssignmentsDao = StoreAssignmentsDao(this);
  late final promotionsDao = PromotionsDao(this);
  late final dailyClosingDao = DailyClosingDao(this);

  @override
  int get schemaVersion => 28;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedInitialData();
        await _seedMembershipTiers();
        await _seedLoyaltySettings();
        await _seedRBACPermissions();
        await _seedDefaultRolePermissions();
        await _ensureAdminOwnerRole();

        // ── 핵심 테이블 인덱스 생성 ──
        // Sales 테이블: 날짜 범위 조회, 상태 필터, 고객/직원 조회 최적화
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_sales_date_status '
          'ON sales(sale_date DESC, status)'
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_sales_customer '
          'ON sales(customer_id) WHERE customer_id IS NOT NULL'
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_sales_employee '
          'ON sales(employee_id) WHERE employee_id IS NOT NULL'
        );

        // Products 테이블: 카테고리 필터, 바코드/SKU 조회 최적화
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_products_category '
          'ON products(category)'
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_products_barcode '
          'ON products(barcode) WHERE barcode IS NOT NULL'
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_products_sku '
          'ON products(sku)'
        );

        // 포인트 트랜잭션 인덱스 생성
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_point_transactions_customer_created '
          'ON point_transactions(customer_id, created_at DESC)'
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_point_transactions_sale '
          'ON point_transactions(sale_id) WHERE sale_id IS NOT NULL'
        );
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(promotions);
        }
        if (from < 3) {
          await _safeAddColumn('sales', 'payment_reference', 'TEXT NULL');
        }
        if (from < 4) {
          // v3 → v4: 고객 포인트/메모, 테이블, 시재, 환불 테이블 추가
          await _safeAddColumn('customers', 'points', 'INTEGER NOT NULL DEFAULT 0');
          await _safeAddColumn('customers', 'note', 'TEXT NULL');
          await _safeCreateTable(m, restaurantTables, 'restaurant_tables');
          await _safeCreateTable(m, cashDrawerLogs, 'cash_drawer_logs');
          await _safeCreateTable(m, refunds, 'refunds');
          await _safeCreateTable(m, refundItems, 'refund_items');
        }
        if (from < 5) {
          // v4 → v5: 로열티 프로그램 추가
          await _migrateLoyaltyProgram(m);
        }
        if (from < 6) {
          // v5 → v6: 백업 & 복구 시스템 추가
          await _migrateBackupSystem(m);
        }
        if (from < 7) {
          // v6 → v7: 직원 근태 관리 시스템 추가
          await _migrateAttendanceSystem(m);
        }
        if (from < 8) {
          // v7 → v8: 주방 디스플레이 시스템 (KDS) 추가
          await _migrateKitchenOrdersSystem(m);
        }
        if (from < 9) {
          // v8 → v9: 테이블 관리 시스템 (Table Management) 추가
          await _migrateTableManagementSystem(m);
        }
        if (from < 10) {
          // v9 → v10: 직원 권한 관리 시스템 (Staff Permission System) 추가
          await _migratePermissionSystem(m);
        }
        if (from < 11) {
          // v10 → v11: 일일 마감 리포트 시스템 (Daily Closing Report) 추가
          await _migrateDailyClosingSystem(m);
        }
        if (from < 12) {
          // v11 → v12: RBAC 시스템 (Role-Based Access Control) 추가
          await _migrateRBACSystem(m);
        }
        if (from < 13) {
          // v12 → v13: system_settings 테이블 추가 (RBAC 토글 등)
          await _migrateSystemSettings(m);
        }
        if (from < 14) {
          // v13 → v14: Employees 테이블 RBAC 컬럼 추가 (camelCase 컬럼명)
          await _migrateEmployeesRbacColumns();
        }
        if (from < 15) {
          // v14 → v15: Fix CURRENT_TIMESTAMP text values in permissions and system_settings
          // Drift stores DateTimeColumn as integer epoch seconds, but CURRENT_TIMESTAMP
          // inserted text like "2026-02-15 00:02:41" causing FormatException on read.
          await _migrateFixTimestampColumns();
        }
        if (from < 16) {
          // v15 → v16: Delivery orders table for GrabFood / ShopeeFood / manual orders
          await _safeCreateTable(m, deliveryOrders, 'delivery_orders');
        }
        if (from < 17) {
          // v16 → v17: POS UX Phase 1 — OrderType + Sales extension + Table status
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
        if (from < 18) {
          // v17 → v18: Phase 0 — Floor Plan Designer
          await _safeCreateTable(m, floorZones, 'floor_zones');
          await _safeCreateTable(m, floorElements, 'floor_elements');
          await _safeCreateTable(m, floorPlanConfig, 'floor_plan_config');
          await _safeAddColumn('restaurant_tables', 'shape', "TEXT NOT NULL DEFAULT 'square'");
          await _safeAddColumn('restaurant_tables', 'zone_id', 'INTEGER NULL');
        }
        if (from < 19) {
          // v18 → v19: Round number for SaleItems
          await _safeAddColumn('sale_items', 'round_number', 'INTEGER NOT NULL DEFAULT 1');
        }
        if (from < 20) {
          // v19 → v20: KDS orderType normalization
          await _safeAddColumn('kitchen_orders', 'order_type', "TEXT NOT NULL DEFAULT 'dineIn'");
        }
        if (from < 21) {
          // v20 → v21: Categories table and Products.categoryId
          await _migrateCategorySystem(m);
        }
        if (from < 22) {
          // v21 → v22: Product Modifiers (Groups, Options, Links, SaleItemModifiers)
          await _migrateProductModifiers(m);
        }
        if (from < 24) {
          // v23 → v24: 직원별 PIN salt 추가 (보안 강화)
          // 기존 직원은 pinSalt=NULL → 레거시 전역 salt로 계속 로그인 가능
          // 다음 PIN 변경 시 자동으로 per-user salt 적용됨
          await _safeAddColumn('employees', 'pin_salt', 'TEXT NULL');
          // v23 → v24: B-118 — 제품별 VAT 세율 (0/5/8/10%)
          await _safeAddColumn('products', 'vat_rate', 'REAL NOT NULL DEFAULT 10.0');
        }
        if (from < 25) {
          // v24 → v25: Per-category VAT rate
          // null = use store-wide default tax rate
          await _safeAddColumn('categories', 'vat_rate', 'REAL NULL');
          // v24 → v25: B-120 — KitchenOrders cancellationReason 컬럼 추가
          await _safeAddColumn('kitchen_orders', 'cancellation_reason', 'TEXT NULL');
        }
        if (from < 26) {
          // v25 → v26: B-124 — DeliveryOrders.saleId 컬럼 추가 (POS 결제 연결)
          await _safeAddColumn('delivery_orders', 'sale_id', 'INTEGER NULL REFERENCES sales(id) ON DELETE SET NULL');
        }
        if (from < 27) {
          // v26 → v27: B-115 — StockMovements 공급업체 정보 컬럼 추가 (Oda 연동 대비)
          await _safeAddColumn('stock_movements', 'supplier_name', 'TEXT NULL');
          await _safeAddColumn('stock_movements', 'supplier_id', 'INTEGER NULL');
        }
        if (from < 28) {
          // v27 → v28: Fix TEXT timestamps in kitchen_orders
          // createOrderFromSale omits createdAt/updatedAt → SQLite DEFAULT CURRENT_TIMESTAMP
          // stores TEXT "YYYY-MM-DD HH:MM:SS" → FormatException when Drift reads as integer.
          // Same issue as v14→v15 fix for permissions/system_settings.
          await _migrateFixKitchenOrdersTimestamps();
        }
      },
      beforeOpen: (details) async {
        if (!kIsWeb) {
          await customStatement('PRAGMA journal_mode = WAL');
          await customStatement('PRAGMA synchronous = NORMAL');
        }
        await customStatement('PRAGMA foreign_keys = ON');

        // Fix #3 v5: kitchen_orders TEXT 타임스탬프 수정 — 매 앱 시작 시 실행
        // v28 마이그레이션이 실패하거나 WasmDatabase에서 DB가 재생성되는 경우 대비
        await _migrateFixKitchenOrdersTimestamps();

        // permissions / role_permissions / user_roles 시드 데이터는
        // INSERT OR IGNORE를 사용하므로 항상 안전하게 실행 가능
        // (이미 존재하는 행은 건너뜀, 빠진 행만 추가)
        await _seedRBACPermissions();
        await _seedDefaultRolePermissions();
        await _ensureAdminOwnerRole();
      },
    );
  }

  /// 컬럼이 이미 존재하면 무시하는 안전한 ALTER TABLE
  Future<void> _safeAddColumn(String table, String column, String type) async {
    // 컬럼 존재 여부를 먼저 확인하여 불필요한 예외를 방지
    final result = await customSelect(
      "SELECT COUNT(*) as cnt FROM pragma_table_info('$table') WHERE name = ?",
      variables: [Variable.withString(column)],
    ).getSingle();
    final exists = (result.data['cnt'] as int) > 0;
    if (exists) return;

    try {
      await customStatement('ALTER TABLE $table ADD COLUMN $column $type');
    } catch (e) {
      // 컬럼 존재 외의 진짜 오류는 로깅
      debugPrint('[Migration] Failed to add column $column to $table: $e');
    }
  }

  /// 테이블이 이미 존재하면 무시하는 안전한 CREATE TABLE
  Future<void> _safeCreateTable(Migrator m, TableInfo table, String tableName) async {
    final result = await customSelect(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      variables: [Variable.withString(tableName)],
    ).get();
    if (result.isEmpty) {
      try {
        await m.createTable(table);
      } catch (e) {
        debugPrint('[Migration] Failed to create table $tableName: $e');
      }
    }
  }

  /// v4 → v5 마이그레이션: 로열티 프로그램
  Future<void> _migrateLoyaltyProgram(Migrator m) async {
    // 1. Customers 테이블 확장
    await _safeAddColumn('customers', 'membership_tier', "TEXT NOT NULL DEFAULT 'bronze'");
    await _safeAddColumn('customers', 'total_spent', 'INTEGER NOT NULL DEFAULT 0');
    await _safeAddColumn('customers', 'birth_date', 'INTEGER NULL');
    await _safeAddColumn('customers', 'last_purchase_at', 'INTEGER NULL');
    await _safeAddColumn('customers', 'purchase_count', 'INTEGER NOT NULL DEFAULT 0');
    await _safeAddColumn('customers', 'updated_at', 'INTEGER NOT NULL DEFAULT 0');

    // 2. 신규 테이블 생성
    await _safeCreateTable(m, pointTransactions, 'point_transactions');
    await _safeCreateTable(m, membershipTiers, 'membership_tiers');
    await _safeCreateTable(m, loyaltySettings, 'loyalty_settings');

    // 3. 인덱스 생성 (IF NOT EXISTS로 중복 방지)
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_point_transactions_customer_created '
      'ON point_transactions(customer_id, created_at DESC)'
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_point_transactions_sale '
      'ON point_transactions(sale_id) WHERE sale_id IS NOT NULL'
    );

    // 4. 기존 고객 데이터 마이그레이션: 누적 구매액 계산
    try {
      await customStatement('''
        UPDATE customers
        SET total_spent = (
          SELECT COALESCE(SUM(total), 0)
          FROM sales
          WHERE sales.customer_id = customers.id
        ),
        purchase_count = (
          SELECT COUNT(*)
          FROM sales
          WHERE sales.customer_id = customers.id
        ),
        last_purchase_at = (
          SELECT MAX(created_at)
          FROM sales
          WHERE sales.customer_id = customers.id
        )
        WHERE EXISTS (
          SELECT 1 FROM sales WHERE sales.customer_id = customers.id
        )
      ''');

      // 5. 누적 구매액 기반 초기 등급 부여
      await customStatement("UPDATE customers SET membership_tier = 'platinum' WHERE total_spent >= 1000000");
      await customStatement("UPDATE customers SET membership_tier = 'gold' WHERE total_spent >= 500000 AND total_spent < 1000000");
      await customStatement("UPDATE customers SET membership_tier = 'silver' WHERE total_spent >= 100000 AND total_spent < 500000");
    } catch (e) {
      // 새 데이터베이스이거나 테이블이 아직 없는 경우
      debugPrint('[Migration v5] Loyalty data migration skipped: $e');
    }

    // 6. 멤버십 등급 시드 데이터
    await _seedMembershipTiers();

    // 7. 로열티 설정 시드 데이터
    await _seedLoyaltySettings();
  }

  /// 멤버십 등급 초기 데이터
  Future<void> _seedMembershipTiers() async {
    try {
      await batch((b) {
        b.insertAll(membershipTiers, [
          MembershipTiersCompanion.insert(
            tierCode: 'bronze',
            tierNameKey: 'tier_bronze',
            minSpent: 0,
            pointRate: 0.01,
            birthdayDiscountPercent: const Value(0),
            displayOrder: 1,
            colorHex: '#CD7F32',
            iconName: 'bronze_medal',
          ),
          MembershipTiersCompanion.insert(
            tierCode: 'silver',
            tierNameKey: 'tier_silver',
            minSpent: 100000,
            pointRate: 0.015,
            birthdayDiscountPercent: const Value(5),
            displayOrder: 2,
            colorHex: '#C0C0C0',
            iconName: 'silver_medal',
          ),
          MembershipTiersCompanion.insert(
            tierCode: 'gold',
            tierNameKey: 'tier_gold',
            minSpent: 500000,
            pointRate: 0.02,
            birthdayDiscountPercent: const Value(10),
            displayOrder: 3,
            colorHex: '#FFD700',
            iconName: 'gold_medal',
          ),
          MembershipTiersCompanion.insert(
            tierCode: 'platinum',
            tierNameKey: 'tier_platinum',
            minSpent: 1000000,
            pointRate: 0.03,
            birthdayDiscountPercent: const Value(15),
            displayOrder: 4,
            colorHex: '#E5E4E2',
            iconName: 'platinum_medal',
          ),
        ], mode: InsertMode.insertOrIgnore);
      });
    } catch (e) {
      debugPrint('[Seed] Membership tiers seed skipped: $e');
    }
  }

  /// 로열티 설정 초기 데이터
  Future<void> _seedLoyaltySettings() async {
    try {
      await batch((b) {
        b.insertAll(loyaltySettings, [
          LoyaltySettingsCompanion.insert(
            settingKey: 'base_point_rate',
            settingValue: '0.01',
            settingType: 'double',
            description: const Value('Base point earn rate (1%)'),
            category: 'points',
          ),
          LoyaltySettingsCompanion.insert(
            settingKey: 'min_redeem_points',
            settingValue: '1000',
            settingType: 'int',
            description: const Value('Minimum redeemable points'),
            category: 'points',
          ),
          LoyaltySettingsCompanion.insert(
            settingKey: 'max_redeem_percent',
            settingValue: '50',
            settingType: 'int',
            description: const Value('Max redemption ratio (%)'),
            category: 'points',
          ),
          LoyaltySettingsCompanion.insert(
            settingKey: 'point_unit',
            settingValue: '100',
            settingType: 'int',
            description: const Value('Point unit size'),
            category: 'points',
          ),
          LoyaltySettingsCompanion.insert(
            settingKey: 'point_expiry_months',
            settingValue: '0',
            settingType: 'int',
            description: const Value('Point expiry (months, 0=unlimited)'),
            category: 'points',
          ),
          LoyaltySettingsCompanion.insert(
            settingKey: 'auto_upgrade_enabled',
            settingValue: 'true',
            settingType: 'bool',
            description: const Value('Enable auto tier upgrade'),
            category: 'membership',
          ),
          LoyaltySettingsCompanion.insert(
            settingKey: 'birthday_bonus_points',
            settingValue: '1000',
            settingType: 'int',
            description: const Value('Birthday bonus points'),
            category: 'membership',
          ),
        ], mode: InsertMode.insertOrIgnore);
      });
    } catch (e) {
      debugPrint('[Seed] Loyalty settings seed skipped: $e');
    }
  }


  Future<void> _migrateCategorySystem(Migrator m) async {
    // 1. Categories 테이블 생성
    await _safeCreateTable(m, categories, 'categories');

    // 2. Products 테이블에 categoryId 컬럼 추가
    await _safeAddColumn('products', 'category_id', 'INTEGER NULL');

    // 3. 기존 category (text) 데이터를 Categories 테이블로 마이그레이션
    try {
      // 3-1. 기존 category 값들을 중복 제거하여 수집
      final existingCategories = await customSelect(
        'SELECT DISTINCT category FROM products WHERE category IS NOT NULL AND category != ""',
      ).get();

      // 3-2. Categories 테이블에 삽입
      int sortOrder = 0;
      for (final row in existingCategories) {
        final categoryName = row.data['category'] as String;
        await customStatement(
          'INSERT OR IGNORE INTO categories (name, sort_order, is_active, created_at) '
          'VALUES (?, ?, 1, ?)',
          [categoryName, sortOrder++, DateTime.now().millisecondsSinceEpoch ~/ 1000],
        );
      }

      // 3-3. Products.categoryId를 매핑 (category text → categoryId FK)
      await customStatement('''
        UPDATE products
        SET category_id = (
          SELECT id FROM categories WHERE categories.name = products.category
        )
        WHERE category IS NOT NULL AND category != ""
      ''');

      debugPrint('[Migration v21] Migrated ${existingCategories.length} categories');
    } catch (e) {
      debugPrint('[Migration v21] Error migrating categories: $e');
    }

    // 4. 인덱스 생성
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_products_category_id '
      'ON products(category_id) WHERE category_id IS NOT NULL'
    );
  }

  Future<void> _migrateProductModifiers(Migrator m) async {
    // 1. Create modifier tables
    await _safeCreateTable(m, modifierGroups, 'modifier_groups');
    await _safeCreateTable(m, modifierOptions, 'modifier_options');
    await _safeCreateTable(m, productModifierLinks, 'product_modifier_links');
    await _safeCreateTable(m, saleItemModifiers, 'sale_item_modifiers');

    // 2. Create indexes
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_modifier_options_group '
      'ON modifier_options(group_id) WHERE is_active = 1'
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_product_modifier_links_product '
      'ON product_modifier_links(product_id)'
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sale_item_modifiers_sale_item '
      'ON sale_item_modifiers(sale_item_id)'
    );

    debugPrint('[Migration v22] Product Modifiers tables created');
  }
  Future<void> _seedInitialData() async {
    await into(employees).insert(
      EmployeesCompanion.insert(
        username: 'admin',
        name: 'Administrator',
        passwordHash: '', // 레거시 필드 (미사용) — 평문 저장 금지
        role: const Value('OWNER'),
        pinHash: const Value('e1c30c7b89e49eb8db1d46b4f3e5a73a909036bb4e607f344e4d5e680f085a4d'),
      ),
    );

    // 시드 카테고리 생성
    final foodId = await into(categories).insert(
      CategoriesCompanion.insert(name: 'Food', sortOrder: const Value(0)),
    );
    final snacksId = await into(categories).insert(
      CategoriesCompanion.insert(name: 'Snacks', sortOrder: const Value(1)),
    );
    final beveragesId = await into(categories).insert(
      CategoriesCompanion.insert(name: 'Beverages', sortOrder: const Value(2)),
    );

    await batch((batch) {
      batch.insertAll(products, [
        ProductsCompanion.insert(
          sku: 'DEMO001',
          name: 'Potato Chips',
          barcode: const Value('4000386123457'),
          price: const Value(10000),
          cost: const Value(7000),
          stock: const Value(100),
          minStock: const Value(10),
          category: const Value('Snacks'),
          categoryId: Value(snacksId),
        ),
        ProductsCompanion.insert(
          sku: 'DEMO002',
          name: 'Instant Noodles',
          barcode: const Value('8800001234568'),
          price: const Value(5000),
          cost: const Value(3000),
          stock: const Value(50),
          minStock: const Value(5),
          category: const Value('Food'),
          categoryId: Value(foodId),
        ),
        ProductsCompanion.insert(
          sku: 'DEMO003',
          name: 'Soft Drink',
          barcode: const Value('6901234567890'),
          price: const Value(25000),
          cost: const Value(18000),
          stock: const Value(30),
          minStock: const Value(10),
          category: const Value('Beverages'),
          categoryId: Value(beveragesId),
        ),
      ]);
    });

    // Seed system settings for new databases
    try {
      await customStatement(
        "INSERT OR IGNORE INTO system_settings (key, value, updated_at) VALUES ('require_kitchen_approval', 'true', CAST(strftime('%s', 'now') AS INTEGER))"
      );
      await customStatement(
        "INSERT OR IGNORE INTO system_settings (key, value, updated_at) VALUES ('rbac_enabled', 'false', CAST(strftime('%s', 'now') AS INTEGER))"
      );
    } catch (e) {
      debugPrint('[Seed] system_settings seed skipped: $e');
    }
  }

  /// v5 → v6 마이그레이션: 백업 & 복구 시스템
  Future<void> _migrateBackupSystem(Migrator m) async {
    // 1. 신규 테이블 생성
    await _safeCreateTable(m, backupLogs, 'backup_logs');
    await _safeCreateTable(m, backupSettings, 'backup_settings');

    // 2. 인덱스 생성
    try {
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_backup_logs_created '
        'ON backup_logs(created_at DESC)'
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_backup_logs_status '
        'ON backup_logs(status, created_at DESC)'
      );
    } catch (e) {
      debugPrint('[Migration] Index creation skipped: $e');
    }

    // 3. 백업 설정 시드 데이터
    await _seedBackupSettings();
  }

  /// 백업 설정 초기 데이터
  Future<void> _seedBackupSettings() async {
    try {
      await batch((b) {
        b.insertAll(backupSettings, [
          // 스케줄 설정
          BackupSettingsCompanion.insert(
            settingKey: 'auto_backup_enabled',
            settingValue: 'true',
            settingType: 'bool',
            description: const Value('Enable automatic backup'),
            category: 'schedule',
          ),
          BackupSettingsCompanion.insert(
            settingKey: 'backup_frequency',
            settingValue: 'daily',
            settingType: 'string',
            description: const Value('Backup frequency (daily/weekly/monthly)'),
            category: 'schedule',
          ),
          BackupSettingsCompanion.insert(
            settingKey: 'backup_time',
            settingValue: '02:00',
            settingType: 'time',
            description: const Value('Backup time (HH:mm)'),
            category: 'schedule',
          ),
          BackupSettingsCompanion.insert(
            settingKey: 'backup_on_close',
            settingValue: 'false',
            settingType: 'bool',
            description: const Value('Backup on app close'),
            category: 'schedule',
          ),

          // 저장소 설정
          BackupSettingsCompanion.insert(
            settingKey: 'max_backups_to_keep',
            settingValue: '30',
            settingType: 'int',
            description: const Value('Max backups to retain'),
            category: 'storage',
          ),
          BackupSettingsCompanion.insert(
            settingKey: 'local_backup_enabled',
            settingValue: 'true',
            settingType: 'bool',
            description: const Value('Enable local backup'),
            category: 'storage',
          ),

          // 클라우드 설정
          BackupSettingsCompanion.insert(
            settingKey: 'cloud_backup_enabled',
            settingValue: 'false',
            settingType: 'bool',
            description: const Value('Enable cloud backup'),
            category: 'cloud',
          ),
          BackupSettingsCompanion.insert(
            settingKey: 'cloud_auto_upload',
            settingValue: 'true',
            settingType: 'bool',
            description: const Value('Auto upload after backup'),
            category: 'cloud',
          ),

          // 보안 설정
          BackupSettingsCompanion.insert(
            settingKey: 'encryption_enabled',
            settingValue: 'false',
            settingType: 'bool',
            description: const Value('Enable backup encryption'),
            category: 'security',
          ),
          BackupSettingsCompanion.insert(
            settingKey: 'compression_enabled',
            settingValue: 'true',
            settingType: 'bool',
            description: const Value('Enable backup compression'),
            category: 'security',
          ),
        ], mode: InsertMode.insertOrIgnore);
      });
    } catch (e) {
      debugPrint('[Migration] Seed data skipped: $e');
    }
  }

  /// v6 → v7 마이그레이션: 직원 근태 관리 시스템
  Future<void> _migrateAttendanceSystem(Migrator m) async {
    // 1. 신규 테이블 생성
    await _safeCreateTable(m, attendanceLogs, 'attendance_logs');
    await _safeCreateTable(m, leaveRequests, 'leave_requests');
    await _safeCreateTable(m, workSchedules, 'work_schedules');
    await _safeCreateTable(m, leaveBalances, 'leave_balances');

    // 2. 인덱스 생성
    try {
      // attendance_logs 인덱스
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_attendance_logs_employee_date '
        'ON attendance_logs(employee_id, work_date DESC)'
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_attendance_logs_status '
        'ON attendance_logs(status, work_date)'
      );

      // leave_requests 인덱스
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_leave_requests_employee '
        'ON leave_requests(employee_id, created_at DESC)'
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_leave_requests_status '
        'ON leave_requests(status, start_date)'
      );

      // work_schedules 인덱스
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_work_schedules_employee '
        'ON work_schedules(employee_id, day_of_week)'
      );
    } catch (e) {
      debugPrint('[Migration] Index creation skipped: $e');
    }

    // 3. 초기 데이터 시딩
    await _seedAttendanceInitialData();
  }

  /// 근태 시스템 초기 데이터
  Future<void> _seedAttendanceInitialData() async {
    try {
      // 모든 직원에게 기본 휴가 잔여일 부여 (2024년 기준)
      final employees = await select(this.employees).get();
      final currentYear = DateTime.now().year;

      await batch((b) {
        for (final employee in employees) {
          b.insert(
            leaveBalances,
            LeaveBalancesCompanion.insert(
              employeeId: employee.id,
              year: currentYear,
              annualTotal: 15.0, // 연차 15일
              annualUsed: 0.0,
              annualRemaining: 15.0,
              sickTotal: 5.0, // 병가 5일
              sickUsed: 0.0,
              sickRemaining: 5.0,
              personalTotal: 3.0, // 개인 사유 3일
              personalUsed: 0.0,
              personalRemaining: 3.0,
            ),
            mode: InsertMode.insertOrIgnore,
          );

          // 기본 근무 스케줄 생성 (월~금 09:00~18:00)
          for (int dayOfWeek = 1; dayOfWeek <= 5; dayOfWeek++) {
            b.insert(
              workSchedules,
              WorkSchedulesCompanion.insert(
                employeeId: employee.id,
                dayOfWeek: dayOfWeek,
                shiftType: 'day',
                startTime: '09:00',
                endTime: '18:00',
                plannedMinutes: 480, // 8시간 = 480분
                effectiveFrom: DateTime(currentYear, 1, 1),
              ),
              mode: InsertMode.insertOrIgnore,
            );
          }

          // 주말은 휴무
          for (int dayOfWeek = 0; dayOfWeek <= 0; dayOfWeek++) {
            // 일요일
            b.insert(
              workSchedules,
              WorkSchedulesCompanion.insert(
                employeeId: employee.id,
                dayOfWeek: dayOfWeek,
                shiftType: 'off',
                startTime: '00:00',
                endTime: '00:00',
                plannedMinutes: 0,
                effectiveFrom: DateTime(currentYear, 1, 1),
              ),
              mode: InsertMode.insertOrIgnore,
            );
          }
          for (int dayOfWeek = 6; dayOfWeek <= 6; dayOfWeek++) {
            // 토요일
            b.insert(
              workSchedules,
              WorkSchedulesCompanion.insert(
                employeeId: employee.id,
                dayOfWeek: dayOfWeek,
                shiftType: 'off',
                startTime: '00:00',
                endTime: '00:00',
                plannedMinutes: 0,
                effectiveFrom: DateTime(currentYear, 1, 1),
              ),
              mode: InsertMode.insertOrIgnore,
            );
          }
        }
      });
    } catch (e) {
      debugPrint('[Migration] Leave balance seed skipped: $e');
    }
  }

  /// v7 → v8 마이그레이션: 주방 디스플레이 시스템 (KDS)
  Future<void> _migrateKitchenOrdersSystem(Migrator m) async {
    // 1. kitchen_orders 테이블 생성
    await _safeCreateTable(m, kitchenOrders, 'kitchen_orders');

    // 2. 성능 최적화 인덱스 생성
    try {
      // 상태별 조회 인덱스 (KDS 화면의 핵심 쿼리)
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_kitchen_orders_status_created '
        'ON kitchen_orders(status, created_at DESC)'
      );

      // 판매 ID로 주문 조회 (POS 통합용)
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_kitchen_orders_sale '
        'ON kitchen_orders(sale_id)'
      );

      // 생성일자 역순 정렬 (최신 주문 우선)
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_kitchen_orders_created '
        'ON kitchen_orders(created_at DESC)'
      );
    } catch (e) {
      debugPrint('[Migration] Index creation skipped: $e');
    }
  }

  /// v8 → v9 마이그레이션: 테이블 관리 시스템 (Table Management)
  Future<void> _migrateTableManagementSystem(Migrator m) async {
    // 1. tables 테이블 생성
    await _safeCreateTable(m, restaurantTables, 'restaurant_tables');

    // 2. reservations 테이블 생성
    await _safeCreateTable(m, reservations, 'reservations');

    // 3. 성능 최적화 인덱스 생성
    try {
      // tables 인덱스
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_restaurant_tables_status '
        'ON restaurant_tables(status)'
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_restaurant_tables_table_number '
        'ON restaurant_tables(table_number)'
      );

      // reservations 인덱스
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_reservations_date '
        'ON reservations(reservation_date, reservation_time)'
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_reservations_status '
        'ON reservations(status)'
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_reservations_customer_phone '
        'ON reservations(customer_phone)'
      );
    } catch (e) {
      debugPrint('[Migration] Index creation skipped: $e');
    }

    // 4. 기본 테이블 시드 데이터 (선택 사항)
    await _seedDefaultTables();
  }

  /// 기본 테이블 시드 데이터 (10개 테이블)
  Future<void> _seedDefaultTables() async {
    try {
      await batch((b) {
        // Row 1: 5개 테이블 (좌측 → 우측)
        for (int i = 1; i <= 5; i++) {
          b.insert(
            restaurantTables,
            RestaurantTablesCompanion.insert(
              tableNumber: '$i',
              seats: const Value(4),
              positionX: Value(50.0 + (i - 1) * 150.0), // 50, 200, 350, 500, 650
              positionY: const Value(50.0),
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }

        // Row 2: 5개 테이블 (좌측 → 우측)
        for (int i = 6; i <= 10; i++) {
          b.insert(
            restaurantTables,
            RestaurantTablesCompanion.insert(
              tableNumber: '$i',
              seats: const Value(4),
              positionX: Value(50.0 + (i - 6) * 150.0), // 50, 200, 350, 500, 650
              positionY: const Value(200.0),
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
      });
    } catch (e) {
      debugPrint('[Migration] Seed data skipped: $e');
    }
  }

  /// v9 → v10 마이그레이션: 직원 권한 관리 시스템
  Future<void> _migratePermissionSystem(Migrator m) async {
    // 1. Employees 테이블 확장 - 권한 시스템 필드 추가
    // 기존 'role' 컬럼의 기본값을 'CASHIER'로 변경 (기존은 'cashier')
    await _safeAddColumn('employees', 'pin_hash', 'TEXT NULL');
    await _safeAddColumn('employees', 'pin_changed_at', 'INTEGER NULL');
    await _safeAddColumn('employees', 'last_login_at', 'INTEGER NULL');
    await _safeAddColumn('employees', 'session_token', 'TEXT NULL');
    await _safeAddColumn('employees', 'session_expires_at', 'INTEGER NULL');

    // 2. 기존 직원의 role 값을 대문자로 변환 (cashier → CASHIER, admin → MANAGER)
    try {
      await customStatement('''
        UPDATE employees
        SET role = CASE
          WHEN UPPER(role) = 'ADMIN' THEN 'MANAGER'
          WHEN UPPER(role) = 'MANAGER' THEN 'MANAGER'
          WHEN UPPER(role) = 'CASHIER' THEN 'CASHIER'
          WHEN UPPER(role) = 'KITCHEN' THEN 'KITCHEN'
          ELSE 'CASHIER'
        END
      ''');
    } catch (e) {
      debugPrint('[Migration] Data update skipped: $e');
    }

    // 3. 권한 로그 테이블 생성
    await _safeCreateTable(m, permissionLogs, 'permission_logs');

    // 4. 인덱스 생성
    try {
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_permission_logs_employee '
        'ON permission_logs(employee_id)'
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_permission_logs_created '
        'ON permission_logs(created_at DESC)'
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_permission_logs_action '
        'ON permission_logs(action_type)'
      );
    } catch (e) {
      debugPrint('[Migration] Index creation skipped: $e');
    }

    // 5. 첫 번째 직원을 관리자로 설정 (기본 관리자 계정 생성)
    try {
      final firstEmployee = await customSelect(
        'SELECT id FROM employees ORDER BY id LIMIT 1'
      ).getSingleOrNull();

      if (firstEmployee != null) {
        await customStatement('''
          UPDATE employees
          SET role = 'MANAGER'
          WHERE id = ?
        ''', [firstEmployee.data['id']]);
      }
    } catch (e) {
      debugPrint('[Migration] Employee update skipped: $e');
    }
  }

  /// v10 → v11 마이그레이션: 일일 마감 리포트 시스템
  Future<void> _migrateDailyClosingSystem(Migrator m) async {
    // 1. daily_closings 테이블 생성
    await _safeCreateTable(m, dailyClosings, 'daily_closings');

    // 2. 성능 최적화 및 중복 방지 인덱스 생성
    try {
      // UNIQUE INDEX: 날짜별 중복 마감 방지
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_daily_closings_date '
        'ON daily_closings(closing_date)'
      );

      // 직원별 마감 이력 조회용 인덱스
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_daily_closings_employee '
        'ON daily_closings(closed_by_employee_id)'
      );

      // 마감 시각 역순 정렬 인덱스
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_daily_closings_closed_at '
        'ON daily_closings(closed_at DESC)'
      );
    } catch (e) {
      debugPrint('[Migration] Index creation skipped: $e');
    }
  }

  /// v11 → v12 마이그레이션: RBAC 시스템 (Role-Based Access Control)
  Future<void> _migrateRBACSystem(Migrator m) async {
    // 1. RBAC 테이블 생성
    await _safeCreateTable(m, permissions, 'permissions');
    await _safeCreateTable(m, rolePermissions, 'role_permissions');
    await _safeCreateTable(m, userRoles, 'user_roles');
    await _safeCreateTable(m, storeAssignments, 'store_assignments');

    // 2. Employees 테이블에 RBAC 필드 추가
    await _safeAddColumn('employees', 'defaultRole', "TEXT NOT NULL DEFAULT 'STAFF'");
    await _safeAddColumn('employees', 'storeScope', "TEXT NOT NULL DEFAULT 'OWN_STORE'");
    await _safeAddColumn('employees', 'primaryStoreId', 'TEXT NULL');

    // 3. RBAC 기본 설정 추가 (기본값: 비활성화로 후방 호환성 유지)
    try {
      // Note: system_settings 테이블이 존재한다고 가정
      await customStatement(
        "INSERT OR IGNORE INTO system_settings (key, value, updated_at) "
        "VALUES ('rbac_enabled', 'false', CAST(strftime('%s', 'now') AS INTEGER))"
      );
    } catch (e) {
      debugPrint('[Migration] System settings seed skipped: $e');
    }

    // 4. 기존 직원 역할 마이그레이션
    try {
      await customStatement('''
        UPDATE employees
        SET default_role = CASE
          WHEN UPPER(role) = 'MANAGER' THEN 'OWNER'
          WHEN UPPER(role) = 'ADMIN' THEN 'OWNER'
          WHEN UPPER(role) = 'CASHIER' THEN 'STAFF'
          WHEN UPPER(role) = 'KITCHEN' THEN 'STAFF'
          ELSE 'STAFF'
        END,
        store_scope = CASE
          WHEN UPPER(role) IN ('MANAGER', 'ADMIN') THEN 'ALL_STORES'
          ELSE 'OWN_STORE'
        END
      ''');
    } catch (e) {
      debugPrint('[Migration] Data update skipped: $e');
    }

    // 5. 권한 시드 데이터 삽입
    await _seedRBACPermissions();

    // 5b. 역할별 기본 권한 시드 및 admin OWNER 지정
    await _seedDefaultRolePermissions();
    await _ensureAdminOwnerRole();

    // 6. 인덱스 생성
    try {
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_role_permissions_role '
        'ON role_permissions(role)'
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_user_roles_user '
        'ON user_roles(user_id)'
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_store_assignments_user '
        'ON store_assignments(user_id)'
      );
    } catch (e) {
      debugPrint('[Migration] Index creation skipped: $e');
    }
  }

  /// v12 → v13 마이그레이션: system_settings 테이블
  Future<void> _migrateSystemSettings(Migrator m) async {
    await _safeCreateTable(m, systemSettings, 'system_settings');

    // 기본 설정들 (없으면 생성)
    try {
      await customStatement(
        "INSERT OR IGNORE INTO system_settings (key, value, updated_at) VALUES ('rbac_enabled', 'false', CAST(strftime('%s', 'now') AS INTEGER))"
      );
      await customStatement(
        "INSERT OR IGNORE INTO system_settings (key, value, updated_at) VALUES ('require_kitchen_approval', 'true', CAST(strftime('%s', 'now') AS INTEGER))"
      );
    } catch (e) {
      debugPrint('[Migration] System settings seed skipped: $e');
    }
  }

  Future<void> _migrateEmployeesRbacColumns() async {
    // Drift 테이블 정의(Employees)가 camelCase 컬럼명을 사용하고 있어
    // 실제 SQLite 컬럼명도 동일하게 맞춰준다.
    await _safeAddColumn('employees', 'defaultRole', "TEXT NOT NULL DEFAULT 'STAFF'");
    await _safeAddColumn('employees', 'storeScope', "TEXT NOT NULL DEFAULT 'OWN_STORE'");
    await _safeAddColumn('employees', 'primaryStoreId', 'TEXT NULL');
  }

  /// v14 → v15: Fix corrupt text timestamps in permissions and system_settings tables.
  /// CURRENT_TIMESTAMP inserts text like "2026-02-15 00:02:41", but Drift expects integer epoch seconds.
  Future<void> _migrateFixTimestampColumns() async {
    try {
      // Fix permissions.created_at: convert text timestamps to epoch seconds
      await customStatement('''
        UPDATE permissions
        SET created_at = CAST(strftime('%s', created_at) AS INTEGER)
        WHERE typeof(created_at) = 'text'
      ''');
    } catch (e) {
      debugPrint('[Migration v15] Fix permissions timestamps: $e');
    }

    try {
      // Fix system_settings.updated_at: convert text timestamps to epoch seconds
      await customStatement('''
        UPDATE system_settings
        SET updated_at = CAST(strftime('%s', updated_at) AS INTEGER)
        WHERE typeof(updated_at) = 'text'
      ''');
    } catch (e) {
      debugPrint('[Migration v15] Fix system_settings timestamps: $e');
    }
  }

  /// v27 → v28: Fix TEXT timestamps in kitchen_orders
  /// All datetime columns may contain "YYYY-MM-DD HH:MM:SS" text from
  /// SQLite CURRENT_TIMESTAMP default → convert to integer epoch seconds.
  Future<void> _migrateFixKitchenOrdersTimestamps() async {
    const columns = [
      'created_at',
      'updated_at',
      'started_at',
      'ready_at',
      'served_at',
      'cancelled_at',
    ];
    for (final col in columns) {
      try {
        await customStatement('''
          UPDATE kitchen_orders
          SET $col = CAST(strftime('%s', $col) AS INTEGER)
          WHERE typeof($col) = 'text'
        ''');
      } catch (e) {
        debugPrint('[Migration v28] Fix kitchen_orders.$col: $e');
      }
    }
  }

  /// RBAC 권한 시드 데이터 삽입
  Future<void> _seedRBACPermissions() async {
    try {
      final permissionsList = [
        // POS Module
        ['pos.open', 'pos', 'Open POS terminal', 0],
        ['pos.refund', 'pos', 'Process refunds', 0],
        ['pos.discount', 'pos', 'Apply discounts', 0],
        ['pos.price.override', 'pos', 'Override prices', 0],
        ['pos.cash.drawer.open', 'pos', 'Open cash drawer manually', 0],
        ['pos.delivery.create', 'pos', 'Create manual delivery orders', 0],

        // Orders Module
        ['order.create', 'order', 'Create orders', 0],
        ['order.cancel', 'order', 'Cancel orders', 0],
        ['order.view', 'order', 'View order history', 0],

        // Inventory Module
        ['inventory.view', 'inventory', 'View inventory levels', 0],
        ['inventory.edit', 'inventory', 'Edit product information', 0],
        ['inventory.adjust', 'inventory', 'Adjust stock levels', 0],
        ['inventory.writeoff', 'inventory', 'Write off damaged/lost items', 0],

        // Revenue Module (Sensitive)
        ['revenue.dashboard.view', 'revenue', 'View revenue dashboard', 1],
        ['revenue.daily.view', 'revenue', 'View daily revenue', 1],
        ['revenue.weekly.view', 'revenue', 'View weekly revenue', 1],
        ['revenue.monthly.view', 'revenue', 'View monthly revenue', 1],
        ['revenue.multistore.view', 'revenue', 'View multi-store revenue', 1],
        ['revenue.export', 'revenue', 'Export revenue reports', 1],
        ['revenue.pnl.view', 'revenue', 'View P&L statement', 1],

        // Staff Module
        ['staff.view', 'staff', 'View staff list', 0],
        ['staff.manage', 'staff', 'Add/edit/delete staff', 0],
        ['staff.role.assign', 'staff', 'Assign roles to staff', 0],

        // Settings Module
        ['settings.store.edit', 'settings', 'Edit store settings', 1],
        ['settings.tax.edit', 'settings', 'Edit tax settings', 1],
        ['settings.payment.edit', 'settings', 'Edit payment settings', 1],
        ['settings.integration.edit', 'settings', 'Edit integration settings', 1],
      ];

      for (var i = 0; i < permissionsList.length; i++) {
        final perm = permissionsList[i];
        await customStatement(
          "INSERT OR IGNORE INTO permissions (id, name, module, description, is_sensitive, created_at) "
          "VALUES (?, ?, ?, ?, ?, CAST(strftime('%s', 'now') AS INTEGER))",
          [
            'perm_${i + 1}', // Simple ID for seeding
            perm[0], // name
            perm[1], // module
            perm[2], // description
            perm[3], // is_sensitive
          ],
        );
      }

      // Note: 역할별 기본 권한 설정은 나중에 UI에서 Owner가 수동으로 설정
      // 또는 별도의 초기화 함수에서 처리
    } catch (e) {
      // 시드 데이터 삽입 실패 시 무시 (이미 존재하거나 다른 오류)
      debugPrint('RBAC seed data insertion failed: $e');
    }
  }

  /// 역할별 기본 권한 시드 데이터
  ///
  /// - OWNER: 모든 권한 활성화
  /// - AREA_MANAGER: 매출/재고/직원 관리, 설정 제외
  /// - STORE_MANAGER: 매출 조회, 재고 관리, 직원 조회
  /// - STAFF: POS, 주문 생성/조회만
  Future<void> _seedDefaultRolePermissions() async {
    try {
      // 현재 permissions 목록 조회
      final perms = await customSelect(
        'SELECT id, name FROM permissions',
      ).get();

      if (perms.isEmpty) {
        debugPrint('[Seed] No permissions found, skipping role_permissions seed');
        return;
      }

      // 첫 번째 직원 ID (updated_by 필드용)
      final firstEmployee = await customSelect(
        'SELECT id FROM employees ORDER BY id LIMIT 1',
      ).getSingleOrNull();
      final systemUserId = firstEmployee?.data['id'] as int? ?? 1;

      // 역할별 허용 권한 목록 정의 (null = 모든 권한)
      const Set<String>? ownerPermissions = null;
      const areaManagerPermissions = {
        'pos.open', 'pos.refund', 'pos.discount', 'pos.price.override', 'pos.cash.drawer.open', 'pos.delivery.create',
        'order.create', 'order.cancel', 'order.view',
        'inventory.view', 'inventory.edit', 'inventory.adjust', 'inventory.writeoff',
        'revenue.dashboard.view', 'revenue.daily.view', 'revenue.weekly.view',
        'revenue.monthly.view', 'revenue.multistore.view', 'revenue.export',
        'staff.view', 'staff.manage', 'staff.role.assign',
      };
      const storeManagerPermissions = {
        'pos.open', 'pos.refund', 'pos.discount', 'pos.cash.drawer.open', 'pos.delivery.create',
        'order.create', 'order.cancel', 'order.view',
        'inventory.view', 'inventory.edit', 'inventory.adjust',
        'revenue.dashboard.view', 'revenue.daily.view', 'revenue.weekly.view',
        'staff.view',
      };
      const staffPermissions = {
        'pos.open', 'pos.delivery.create',
        'order.create', 'order.view',
        'inventory.view',
      };

      final roles = <(String, Set<String>?)>[
        ('OWNER', ownerPermissions),
        ('AREA_MANAGER', areaManagerPermissions),
        ('STORE_MANAGER', storeManagerPermissions),
        ('STAFF', staffPermissions),
      ];

      int idx = 0;
      for (final (role, allowedPerms) in roles) {
        for (final perm in perms) {
          final permName = perm.data['name'] as String;
          final permId = perm.data['id'] as String;
          // OWNER는 모두 활성화, 나머지는 허용 목록에 있는 것만
          final isEnabled = allowedPerms == null || allowedPerms.contains(permName);
          final rpId = 'rp_${role}_$permId';
          await customStatement(
            "INSERT OR IGNORE INTO role_permissions "
            "(id, role, permission_id, is_enabled, updated_at, updated_by) "
            "VALUES (?, ?, ?, ?, CAST(strftime('%s', 'now') AS INTEGER), ?)",
            [rpId, role, permId, isEnabled ? 1 : 0, systemUserId],
          );
          idx++;
        }
      }

      debugPrint('[Seed] Default role_permissions seeded: $idx entries for 4 roles');
    } catch (e) {
      debugPrint('[Seed] role_permissions seed failed: $e');
    }
  }

  /// 첫 번째 직원(admin)에게 OWNER role을 부여 (user_roles에 없을 경우)
  Future<void> _ensureAdminOwnerRole() async {
    try {
      // 첫 번째 직원 조회
      final firstEmployee = await customSelect(
        'SELECT id FROM employees ORDER BY id LIMIT 1',
      ).getSingleOrNull();

      if (firstEmployee == null) return;

      final adminId = firstEmployee.data['id'] as int;

      // 이미 user_roles에 있으면 스킵
      final existing = await customSelect(
        'SELECT id FROM user_roles WHERE user_id = ?',
        variables: [Variable.withInt(adminId)],
      ).getSingleOrNull();

      if (existing != null) return;

      // OWNER role 부여 (user_roles: id, user_id, role, scope, assigned_at, assigned_by)
      await customStatement(
        "INSERT OR IGNORE INTO user_roles (id, user_id, role, scope, assigned_at, assigned_by) "
        "VALUES (?, ?, 'OWNER', 'ALL_STORES', CAST(strftime('%s', 'now') * 1000 AS INTEGER), ?)",
        ['ur_admin_owner', adminId, adminId],
      );

      debugPrint('[Seed] OWNER role assigned to admin (employee #$adminId)');
    } catch (e) {
      debugPrint('[Seed] Admin owner role seed failed: $e');
    }
  }
}
