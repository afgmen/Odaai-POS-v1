import 'dart:io' as dart_io;

import 'package:drift/drift.dart' hide Column;
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../database/app_database.dart';
import '../../../database/daos/products_dao.dart';

// ─────────────────────────────────────────────
// Excel 열 정의 (순서 중요)
// ─────────────────────────────────────────────
const List<String> _defaultExcelHeaders = [
  'SKU',        // 0
  '상품명',      // 1
  '바코드',      // 2
  '카테고리',    // 3
  '판매가',      // 4
  '원가',        // 5
  '재고',        // 6
  '최소재고',    // 7
];

/// 엑셀 업로드 결과 모델
class ExcelUploadResult {
  final int inserted;   // 새로 추가된 상품 수
  final int updated;    // 기존 상품 중 업데이트된 수
  final List<String> errors; // 행별 오류 메시지

  const ExcelUploadResult({
    required this.inserted,
    required this.updated,
    required this.errors,
  });

  int get totalProcessed => inserted + updated;
}

/// 상품 엑셀 다운로드/업로드 서비스
class ExcelService {
  const ExcelService._();

  // ════════════════════════════════════════════
  //  DOWNLOAD — 현재 상품 목록을 엑셀로 내보내기
  // ════════════════════════════════════════════
  static Future<String?> downloadProducts({
    required List<Product> products,
    required BuildContext context,
    Map<String, String> labels = const {},
  }) async {
    try {
      final excel = Excel.createExcel();

      final sheetName = labels['sheetName'] ?? '상품목록';
      // 기본 시트 이름 변경
      final defaultName = excel.tables.keys.first;
      excel.rename(defaultName, sheetName);
      final sheet = excel[sheetName];

      // ── 헤더 행 스타일 ──────────────────────
      // AppTheme.primary = 0xFF3182F6
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('FF3182F6'),
        fontColorHex: ExcelColor.white,
        fontSize: 11,
        horizontalAlign: HorizontalAlign.Center,
      );

      final excelHeaders = [
        'SKU',
        labels['headerProductName'] ?? _defaultExcelHeaders[1],
        labels['headerBarcode'] ?? _defaultExcelHeaders[2],
        labels['headerCategory'] ?? _defaultExcelHeaders[3],
        labels['headerSellingPrice'] ?? _defaultExcelHeaders[4],
        labels['headerCostPrice'] ?? _defaultExcelHeaders[5],
        labels['headerStock'] ?? _defaultExcelHeaders[6],
        labels['headerMinStock'] ?? _defaultExcelHeaders[7],
      ];

      for (int col = 0; col < excelHeaders.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
        );
        cell.value = TextCellValue(excelHeaders[col]);
        cell.cellStyle = headerStyle;
      }

      // ── 열 너비 설정 ────────────────────────
      final widths = [14.0, 22.0, 16.0, 14.0, 12.0, 12.0, 8.0, 8.0];
      for (int col = 0; col < widths.length; col++) {
        sheet.setColumnWidth(col, widths[col]);
      }

      // ── 짝수 행 배경색 스타일 ─────────────────
      // AppTheme.background = 0xFFF5F5F7
      final evenRowStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('FFF5F5F7'),
      );

      // ── 데이터 행 ────────────────────────────
      for (int i = 0; i < products.length; i++) {
        final p = products[i];
        final row = i + 1;

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue(p.sku);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(p.name);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = TextCellValue(p.barcode ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
            .value = TextCellValue(p.category ?? '');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
            .value = DoubleCellValue(p.price);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
            .value = DoubleCellValue(p.cost);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
            .value = IntCellValue(p.stock);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row))
            .value = IntCellValue(p.minStock);

        // 교대 행 색칠
        if (i % 2 == 1) {
          for (int col = 0; col < excelHeaders.length; col++) {
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
                .cellStyle = evenRowStyle;
          }
        }
      }

      // ── 파일 저장 (네이티브 저장 다이얼로그) ──
      final bytes = excel.save();
      if (bytes == null) return null;

      final fileName = 'oda_products_${_dateTag()}.xlsx';

      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: labels['dialogSaveTitle'] ?? '엑셀 파일 저장',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (savedPath == null) return null; // 사용자 취소

      // 저장된 경로에 바이트 직접 작성
      await _writeBytes(savedPath, bytes);

      return savedPath;
    } catch (e, stack) {
      debugPrint('[ExcelService] downloadProducts 오류: $e\n$stack');
      return null;
    }
  }

  // ════════════════════════════════════════════
  //  UPLOAD — 엑셀 파일로부터 상품 읽기 (Upsert)
  // ════════════════════════════════════════════
  static Future<ExcelUploadResult?> uploadProducts({
    required ProductsDao dao,
    required AppDatabase db,
    required BuildContext context,
    Map<String, String> labels = const {},
  }) async {
    // ── 파일 선택 다이얼로그 ──────────────────
    final pickerResult = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      dialogTitle: labels['dialogSelectTitle'] ?? '엑셀 파일 선택',
    );
    if (pickerResult == null || pickerResult.files.isEmpty) return null;

    final file = pickerResult.files.single;
    final bytes = file.bytes;
    if (bytes == null) return null;

    return _parseAndUpsert(dao, db, bytes, labels: labels);
  }

  // ════════════════════════════════════════════
  //  내부: 엑셀 파싱 + Upsert 실행
  // ════════════════════════════════════════════
  static Future<ExcelUploadResult> _parseAndUpsert(
    ProductsDao dao,
    AppDatabase db,
    Uint8List bytes, {
    Map<String, String> labels = const {},
  }) async {
    final excel = Excel.decodeBytes(bytes);

    // 첫 번째 시트 사용
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName]!;

    int inserted = 0;
    int updated = 0;
    final errors = <String>[];

    // 첫 번째 행이 헤더인지 확인 → 헤더 행 스킵
    final startRow = _detectHeaderRow(sheet);

    for (int row = startRow; row < sheet.maxRows; row++) {
      try {
        final rowData = sheet.row(row);

        // ── 셀 값 추출 ──────────────────────
        final sku = _readStr(rowData, 0);
        if (sku == null || sku.trim().isEmpty) continue; // 빈 행 스킵

        final name = _readStr(rowData, 1);
        if (name == null || name.trim().isEmpty) {
          errors.add(labels['rowNameEmpty']?.replaceAll('{row}', '${row + 1}') ?? '행 ${row + 1}: 상품명이 비어있습니다');
          continue;
        }

        final barcode = _readStr(rowData, 2);
        final category = _readStr(rowData, 3);
        final price = _readNum(rowData, 4) ?? 0.0;
        final cost = _readNum(rowData, 5) ?? 0.0;
        final stock = _readNum(rowData, 6)?.toInt() ?? 0;
        final minStock = _readNum(rowData, 7)?.toInt() ?? 0;

        // ── 유효성 검사 ───────────────────
        if (price < 0) {
          errors.add(labels['rowPriceError']?.replaceAll('{row}', '${row + 1}') ?? '행 ${row + 1}: 판매가는 0 이상이어야 합니다');
          continue;
        }
        if (cost < 0) {
          errors.add(labels['rowCostError']?.replaceAll('{row}', '${row + 1}') ?? '행 ${row + 1}: 원가는 0 이상이어야 합니다');
          continue;
        }
        if (stock < 0) {
          errors.add(labels['rowStockError']?.replaceAll('{row}', '${row + 1}') ?? '행 ${row + 1}: 재고는 0 이상이어야 합니다');
          continue;
        }

        // ── SKU로 기존 상품 조회 (Upsert) ───
        final existing = await dao.getProductBySku(sku.trim());

        if (existing != null) {
          // UPDATE: 기존 상품 정보 갱신 (재고는 유지)
          await (db.update(db.products)
              ..where((p) => p.id.equals(existing.id)))
              .write(ProductsCompanion(
                name: Value(name.trim()),
                barcode: Value(barcode?.trim()),
                category: Value(category?.trim()),
                price: Value(price),
                cost: Value(cost),
                minStock: Value(minStock),
                updatedAt: Value(DateTime.now()),
                needsSync: const Value(true),
              ));
          updated++;
        } else {
          // INSERT: 새 상품 추가
          await dao.createProduct(ProductsCompanion.insert(
            sku: sku.trim(),
            name: name.trim(),
            barcode: Value(barcode?.trim()),
            category: Value(category?.trim()),
            price: Value(price),
            cost: Value(cost),
            stock: Value(stock),
            minStock: Value(minStock),
            needsSync: const Value(true),
          ));
          inserted++;
        }
      } catch (e) {
        errors.add(labels['rowError']?.replaceAll('{row}', '${row + 1}').replaceAll('{error}', e.toString()) ?? '행 ${row + 1}: ${e.toString()}');
      }
    }

    return ExcelUploadResult(
      inserted: inserted,
      updated: updated,
      errors: errors,
    );
  }

  // ════════════════════════════════════════════
  //  유틸리티
  // ════════════════════════════════════════════

  /// 헤더 행 감지 (첫 행의 첫 셀이 'SKU'이면 row=1로 스킵)
  static int _detectHeaderRow(Sheet sheet) {
    if (sheet.maxRows == 0) return 0;
    final firstRow = sheet.row(0);
    final firstCell = _readStr(firstRow, 0);
    if (firstCell != null && firstCell.trim().toUpperCase() == 'SKU') return 1;
    return 0;
  }

  /// 행 데이터에서 문자열 읽기
  static String? _readStr(List<Data?> rowData, int col) {
    if (col >= rowData.length) return null;
    final cell = rowData[col];
    if (cell == null || cell.value == null) return null;
    final v = cell.value;
    if (v is TextCellValue) return v.value.text;   // TextSpan → .text
    if (v is IntCellValue) return v.value.toString();
    if (v is DoubleCellValue) return v.value.toString();
    return null;
  }

  /// 행 데이터에서 숫자 읽기 (Double)
  static double? _readNum(List<Data?> rowData, int col) {
    if (col >= rowData.length) return null;
    final cell = rowData[col];
    if (cell == null || cell.value == null) return null;
    final v = cell.value;
    if (v is DoubleCellValue) return v.value;
    if (v is IntCellValue) return v.value.toDouble();
    if (v is TextCellValue) return double.tryParse(v.value.text ?? '');
    return null;
  }

  /// 파일 경로에 바이트 직접 작성
  static Future<void> _writeBytes(String path, List<int> bytes) async {
    final file = dart_io.File(path);
    await file.writeAsBytes(bytes);
  }

  /// 날짜 태그 생성 (YYYYMMDD)
  static String _dateTag() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }
}
