import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// 조건부 import: 플랫폼에 따라 적절한 DB 연결 사용
import 'connection/unsupported.dart'
    if (dart.library.ffi) 'connection/native.dart'
    if (dart.library.html) 'connection/web.dart' as connection;

import 'daos/customers_dao.dart';
import 'daos/employees_dao.dart';
import 'daos/products_dao.dart';
import 'daos/sales_dao.dart';
import 'daos/sync_dao.dart';
import '../features/loyalty/data/loyalty_dao.dart';
import '../features/backup/data/backup_dao.dart';
import '../features/attendance/data/attendance_dao.dart';
import '../features/kds/data/kitchen_orders_dao.dart';
import '../features/tables/data/tables_dao.dart';
import '../features/tables/data/reservations_dao.dart';
import 'tables/employees.dart';
import 'tables/products.dart';
import 'tables/promotions.dart';
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(connection.openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedInitialData();
        await _seedMembershipTiers();
        await _seedLoyaltySettings();

        // 포인트 트랜잭션 인덱스 생성
        await customStatement(
          'CREATE INDEX idx_point_transactions_customer_created '
          'ON point_transactions(customer_id, created_at DESC)'
        );
        await customStatement(
          'CREATE INDEX idx_point_transactions_sale '
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
      },
      beforeOpen: (details) async {
        if (!kIsWeb) {
          await customStatement('PRAGMA journal_mode = WAL');
          await customStatement('PRAGMA synchronous = NORMAL');
        }
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// 컬럼이 이미 존재하면 무시하는 안전한 ALTER TABLE
  Future<void> _safeAddColumn(String table, String column, String type) async {
    try {
      await customStatement('ALTER TABLE $table ADD COLUMN $column $type');
    } catch (_) {
      // 이미 존재하는 경우 무시
    }
  }

  /// 테이블이 이미 존재하면 무시하는 안전한 CREATE TABLE
  Future<void> _safeCreateTable(Migrator m, TableInfo table, String tableName) async {
    try {
      final result = await customSelect(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        variables: [Variable.withString(tableName)],
      ).get();
      if (result.isEmpty) {
        await m.createTable(table);
      }
    } catch (_) {
      try {
        await m.createTable(table);
      } catch (_) {
        // 이미 존재하는 경우 무시
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

    // 3. 인덱스 생성
    try {
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_point_transactions_customer_created '
        'ON point_transactions(customer_id, created_at DESC)'
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_point_transactions_sale '
        'ON point_transactions(sale_id) WHERE sale_id IS NOT NULL'
      );
    } catch (_) {
      // 인덱스가 이미 존재하면 무시
    }

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
    } catch (_) {
      // 마이그레이션 실패 시 무시 (새 데이터베이스인 경우)
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
    } catch (_) {
      // 이미 존재하는 경우 무시
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
            description: const Value('기본 포인트 적립률 (1%)'),
            category: 'points',
          ),
          LoyaltySettingsCompanion.insert(
            settingKey: 'min_redeem_points',
            settingValue: '1000',
            settingType: 'int',
            description: const Value('최소 사용 포인트'),
            category: 'points',
          ),
          LoyaltySettingsCompanion.insert(
            settingKey: 'max_redeem_percent',
            settingValue: '50',
            settingType: 'int',
            description: const Value('최대 사용 비율 (%)'),
            category: 'points',
          ),
          LoyaltySettingsCompanion.insert(
            settingKey: 'point_unit',
            settingValue: '100',
            settingType: 'int',
            description: const Value('포인트 사용 단위'),
            category: 'points',
          ),
          LoyaltySettingsCompanion.insert(
            settingKey: 'point_expiry_months',
            settingValue: '0',
            settingType: 'int',
            description: const Value('포인트 유효기간 (개월, 0=무제한)'),
            category: 'points',
          ),
          LoyaltySettingsCompanion.insert(
            settingKey: 'auto_upgrade_enabled',
            settingValue: 'true',
            settingType: 'bool',
            description: const Value('자동 등급 승급 활성화'),
            category: 'membership',
          ),
          LoyaltySettingsCompanion.insert(
            settingKey: 'birthday_bonus_points',
            settingValue: '1000',
            settingType: 'int',
            description: const Value('생일 보너스 포인트'),
            category: 'membership',
          ),
        ], mode: InsertMode.insertOrIgnore);
      });
    } catch (_) {
      // 이미 존재하는 경우 무시
    }
  }

  Future<void> _seedInitialData() async {
    await into(employees).insert(
      EmployeesCompanion.insert(
        username: 'admin',
        name: 'Administrator',
        passwordHash: 'admin123',
        role: const Value('admin'),
        pin: const Value('03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4'),
      ),
    );

    await batch((batch) {
      batch.insertAll(products, [
        ProductsCompanion.insert(
          sku: 'DEMO001',
          name: '테스트 감자칩',
          barcode: const Value('4000386123457'),
          price: const Value(10000),
          cost: const Value(7000),
          stock: const Value(100),
          minStock: const Value(10),
          category: const Value('식품'),
        ),
        ProductsCompanion.insert(
          sku: 'DEMO002',
          name: '테스트 라면',
          barcode: const Value('8800001234568'),
          price: const Value(5000),
          cost: const Value(3000),
          stock: const Value(50),
          minStock: const Value(5),
          category: const Value('식품'),
        ),
        ProductsCompanion.insert(
          sku: 'DEMO003',
          name: '테스트 음료',
          barcode: const Value('6901234567890'),
          price: const Value(25000),
          cost: const Value(18000),
          stock: const Value(30),
          minStock: const Value(10),
          category: const Value('음료'),
        ),
      ]);
    });
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
    } catch (_) {
      // 인덱스가 이미 존재하면 무시
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
            description: const Value('자동 백업 활성화'),
            category: 'schedule',
          ),
          BackupSettingsCompanion.insert(
            settingKey: 'backup_frequency',
            settingValue: 'daily',
            settingType: 'string',
            description: const Value('백업 주기 (daily/weekly/monthly)'),
            category: 'schedule',
          ),
          BackupSettingsCompanion.insert(
            settingKey: 'backup_time',
            settingValue: '02:00',
            settingType: 'time',
            description: const Value('백업 시간 (HH:mm)'),
            category: 'schedule',
          ),
          BackupSettingsCompanion.insert(
            settingKey: 'backup_on_close',
            settingValue: 'false',
            settingType: 'bool',
            description: const Value('앱 종료 시 백업'),
            category: 'schedule',
          ),

          // 저장소 설정
          BackupSettingsCompanion.insert(
            settingKey: 'max_backups_to_keep',
            settingValue: '30',
            settingType: 'int',
            description: const Value('보관할 최대 백업 수'),
            category: 'storage',
          ),
          BackupSettingsCompanion.insert(
            settingKey: 'local_backup_enabled',
            settingValue: 'true',
            settingType: 'bool',
            description: const Value('로컬 백업 활성화'),
            category: 'storage',
          ),

          // 클라우드 설정
          BackupSettingsCompanion.insert(
            settingKey: 'cloud_backup_enabled',
            settingValue: 'false',
            settingType: 'bool',
            description: const Value('클라우드 백업 활성화'),
            category: 'cloud',
          ),
          BackupSettingsCompanion.insert(
            settingKey: 'cloud_auto_upload',
            settingValue: 'true',
            settingType: 'bool',
            description: const Value('백업 후 자동 업로드'),
            category: 'cloud',
          ),

          // 보안 설정
          BackupSettingsCompanion.insert(
            settingKey: 'encryption_enabled',
            settingValue: 'false',
            settingType: 'bool',
            description: const Value('백업 암호화 활성화'),
            category: 'security',
          ),
          BackupSettingsCompanion.insert(
            settingKey: 'compression_enabled',
            settingValue: 'true',
            settingType: 'bool',
            description: const Value('백업 압축 활성화'),
            category: 'security',
          ),
        ], mode: InsertMode.insertOrIgnore);
      });
    } catch (_) {
      // 이미 존재하는 경우 무시
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
    } catch (_) {
      // 인덱스가 이미 존재하면 무시
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
    } catch (_) {
      // 마이그레이션 실패 시 무시 (새 데이터베이스인 경우)
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
    } catch (_) {
      // 인덱스가 이미 존재하면 무시
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
    } catch (_) {
      // 인덱스가 이미 존재하면 무시
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
    } catch (_) {
      // 이미 존재하는 경우 무시
    }
  }
}
