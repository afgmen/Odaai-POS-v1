import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/database/app_database.dart';
import 'package:oda_pos/database/tables/products.dart';
import 'package:oda_pos/database/tables/categories.dart';
import 'package:oda_pos/features/backup/data/backup_dao.dart';
import 'package:oda_pos/features/backup/domain/services/backup_service.dart';
import 'package:drift/drift.dart' hide Column;

void main() {
  late AppDatabase database;
  late BackupDao backupDao;
  late BackupService backupService;

  setUp(() {
    database = AppDatabase.forTesting();
    backupDao = BackupDao(database);
    backupService = BackupService(backupDao, database);
  });

  tearDown() async {
    await database.close();
  });

  group('Backup Creation', () {
    test('create backup successfully', () async {
      // Insert test data
      await database.categories.insertOne(
        CategoriesCompanion.insert(
          categoryName: 'Beverages',
          sortOrder: 1,
        ),
      );

      await database.products.insertOne(
        ProductsCompanion.insert(
          productName: 'Coffee',
          price: 3.50,
          categoryId: Value(1),
        ),
      );

      // Create backup
      final result = await backupService.createBackup(
        type: BackupType.manual,
      );

      expect(result.success, isTrue);
      expect(result.backupId, isNotNull);
      expect(result.backupFile, isNotNull);
      expect(result.fileSize, greaterThan(0));
    });

    test('backup file exists after creation', () async {
      final result = await backupService.createBackup();

      expect(result.success, isTrue);
      expect(result.backupFile, isNotNull);
      expect(result.backupFile!.existsSync(), isTrue);
    });

    test('backup log is created', () async {
      final result = await backupService.createBackup(
        type: BackupType.auto,
      );

      expect(result.success, isTrue);

      final logs = await backupDao.getAllBackupLogs(limit: 1);
      expect(logs.length, 1);
      expect(logs.first.backupType, 'auto');
      expect(logs.first.status, 'completed');
    });

    test('backup includes database version', () async {
      final result = await backupService.createBackup();

      final logs = await backupDao.getAllBackupLogs(limit: 1);
      expect(logs.first.databaseVersion, database.schemaVersion);
    });
  });

  group('Backup Restore', () {
    test('restore backup successfully', () async {
      // Create original data
      await database.categories.insertOne(
        CategoriesCompanion.insert(
          categoryName: 'Main Dishes',
          sortOrder: 1,
        ),
      );

      await database.products.insertOne(
        ProductsCompanion.insert(
          productName: 'Pho',
          price: 8.00,
          categoryId: Value(1),
        ),
      );

      // Create backup
      final backupResult = await backupService.createBackup();
      expect(backupResult.success, isTrue);

      // Clear database
      await database.delete(database.products).go();
      await database.delete(database.categories).go();

      final productsAfterClear = await database.products.select().get();
      expect(productsAfterClear.length, 0);

      // Restore backup
      final restoreResult = await backupService.restoreBackup(
        backupResult.backupFile!.path,
      );

      expect(restoreResult.success, isTrue);

      // Verify data restored
      final products = await database.products.select().get();
      final categories = await database.categories.select().get();

      expect(products.length, 1);
      expect(categories.length, 1);
      expect(products.first.productName, 'Pho');
      expect(categories.first.categoryName, 'Main Dishes');
    });

    test('restore handles missing file', () async {
      final result = await backupService.restoreBackup('/invalid/path.db');

      expect(result.success, isFalse);
      expect(result.errorMessage, isNotNull);
    });

    test('restore validates database version compatibility', () async {
      // This is a placeholder - actual implementation depends on version check
      final backupResult = await backupService.createBackup();
      expect(backupResult.success, isTrue);

      // Restore should succeed for same version
      final restoreResult = await backupService.restoreBackup(
        backupResult.backupFile!.path,
      );

      expect(restoreResult.success, isTrue);
    });
  });

  group('Data Integrity', () {
    test('backup preserves all table data', () async {
      // Insert multiple categories
      await database.categories.insertAll([
        CategoriesCompanion.insert(categoryName: 'Cat 1', sortOrder: 1),
        CategoriesCompanion.insert(categoryName: 'Cat 2', sortOrder: 2),
        CategoriesCompanion.insert(categoryName: 'Cat 3', sortOrder: 3),
      ]);

      // Insert multiple products
      await database.products.insertAll([
        ProductsCompanion.insert(productName: 'Product 1', price: 10.0, categoryId: Value(1)),
        ProductsCompanion.insert(productName: 'Product 2', price: 20.0, categoryId: Value(2)),
        ProductsCompanion.insert(productName: 'Product 3', price: 30.0, categoryId: Value(3)),
      ]);

      final categoriesBeforeBackup = await database.categories.select().get();
      final productsBeforeBackup = await database.products.select().get();

      // Backup
      final backupResult = await backupService.createBackup();
      expect(backupResult.success, isTrue);

      // Clear
      await database.delete(database.products).go();
      await database.delete(database.categories).go();

      // Restore
      await backupService.restoreBackup(backupResult.backupFile!.path);

      final categoriesAfterRestore = await database.categories.select().get();
      final productsAfterRestore = await database.products.select().get();

      expect(categoriesAfterRestore.length, categoriesBeforeBackup.length);
      expect(productsAfterRestore.length, productsBeforeBackup.length);
    });

    test('backup preserves foreign key relationships', () async {
      await database.categories.insertOne(
        CategoriesCompanion.insert(categoryName: 'Drinks', sortOrder: 1),
      );

      await database.products.insertOne(
        ProductsCompanion.insert(
          productName: 'Juice',
          price: 4.00,
          categoryId: Value(1),
        ),
      );

      final backupResult = await backupService.createBackup();
      await database.delete(database.products).go();
      await database.delete(database.categories).go();

      await backupService.restoreBackup(backupResult.backupFile!.path);

      final products = await database.products.select().get();
      expect(products.first.categoryId, 1);
    });
  });

  group('Error Handling', () {
    test('handles corrupted backup file gracefully', () async {
      // Create a corrupted file
      final tempDir = Directory.systemTemp;
      final corruptedFile = File('${tempDir.path}/corrupted.db');
      await corruptedFile.writeAsString('NOT A VALID DATABASE FILE');

      final result = await backupService.restoreBackup(corruptedFile.path);

      expect(result.success, isFalse);
      expect(result.errorMessage, isNotNull);

      await corruptedFile.delete();
    });

    test('handles empty backup file', () async {
      final tempDir = Directory.systemTemp;
      final emptyFile = File('${tempDir.path}/empty.db');
      await emptyFile.writeAsBytes([]);

      final result = await backupService.restoreBackup(emptyFile.path);

      expect(result.success, isFalse);

      await emptyFile.delete();
    });
  });

  group('Backup Cleanup', () {
    test('delete old backups by age', () async {
      // Create multiple backups
      await backupService.createBackup();
      await Future.delayed(Duration(milliseconds: 100));
      await backupService.createBackup();
      await Future.delayed(Duration(milliseconds: 100));
      await backupService.createBackup();

      final logs = await backupDao.getAllBackupLogs();
      expect(logs.length, greaterThanOrEqualTo(3));

      // Delete backups older than 30 days
      await backupService.deleteOldBackups(daysToKeep: 30);

      // All recent backups should still exist
      final remainingLogs = await backupDao.getAllBackupLogs();
      expect(remainingLogs.length, greaterThan(0));
    });

    test('delete backup by ID', () async {
      final result = await backupService.createBackup();
      expect(result.success, isTrue);

      final deleteSuccess = await backupService.deleteBackup(result.backupId!);
      expect(deleteSuccess, isTrue);

      final logs = await backupDao.getBackupLogById(result.backupId!);
      expect(logs, isNull);
    });
  });
}
