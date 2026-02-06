import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/products_dao.dart';
import 'daos/sales_dao.dart';
import 'daos/sync_dao.dart';
import 'tables/employees.dart';
import 'tables/products.dart';
import 'tables/promotions.dart';
import 'tables/sales.dart';
import 'tables/sync_queue.dart';

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
  ],
  daos: [
    ProductsDao,
    SalesDao,
    SyncDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedInitialData();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1 && to == 2) {
          // Promotions 테이블 추가
          await m.createTable(promotions);
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

  Future<void> _seedInitialData() async {
    // 기본 관리자 계정 (비밀번호: admin123, PIN: 1234)
    // PIN 해시: SHA-256('1234') = 03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4
    await into(employees).insert(
      EmployeesCompanion.insert(
        username: 'admin',
        name: 'Administrator',
        passwordHash: 'admin123', // TODO: bcrypt 해시로 변경
        role: const Value('admin'),
        pin: const Value('03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4'),
      ),
    );

    // 테스트용 기본 상품 (바코드 포함 — 스캔 테스트용)
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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web 플랫폼은 현재 지원되지 않습니다. '
        'Android, iOS, Desktop에서 실행하세요.',
      );
    }

    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'oda_pos.db'));

    if (!kReleaseMode) {
      // ignore: avoid_print
      print('📁 Database path: ${file.path}');
    }

    return NativeDatabase.createInBackground(
      file,
      logStatements: !kReleaseMode,
    );
  });
}
