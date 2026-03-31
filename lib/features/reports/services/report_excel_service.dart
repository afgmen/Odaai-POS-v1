import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

import '../../../database/daos/sales_dao.dart';

/// 매출 리포트 엑셀 내보내기 서비스
class ReportExcelService {
  /// 매출 리포트를 엑셀 파일로 생성
  static Future<String> exportSalesReport({
    required List<DailySalesData> dailyData,
    required Map<String, double> paymentData,
    required List<ProductSalesStats> topProducts,
    required double totalSales,
    required int orderCount,
    required double avgOrder,
    required double growth,
    required DateTime from,
    required DateTime to,
    Map<String, String> labels = const {},
  }) async {
    final excel = Excel.createExcel();

    // ── Summary sheet ──
    final summarySheetName = labels['sheetSummary'] ?? 'Summary';
    final summarySheet = excel[summarySheetName];
    summarySheet.appendRow([
      TextCellValue(labels['title'] ?? 'Oda POS Sales Report'),
    ]);
    summarySheet.appendRow([
      TextCellValue(labels['periodText'] ?? 'Period: ${DateFormat('yyyy-MM-dd').format(from)} ~ ${DateFormat('yyyy-MM-dd').format(to)}'),
    ]);
    summarySheet.appendRow([TextCellValue('')]);
    summarySheet.appendRow([
      TextCellValue(labels['item'] ?? 'Item'),
      TextCellValue(labels['value'] ?? 'Value'),
    ]);
    summarySheet.appendRow([
      TextCellValue(labels['totalSales'] ?? 'Total Sales'),
      DoubleCellValue(totalSales),
    ]);
    summarySheet.appendRow([
      TextCellValue(labels['orderCount'] ?? 'Order Count'),
      IntCellValue(orderCount),
    ]);
    summarySheet.appendRow([
      TextCellValue(labels['avgOrder'] ?? 'Avg Order Value'),
      DoubleCellValue(avgOrder),
    ]);
    summarySheet.appendRow([
      TextCellValue(labels['growthRate'] ?? 'Growth Rate (%)'),
      DoubleCellValue(growth),
    ]);

    // ── Daily sales sheet ──
    final dailySheetName = labels['sheetDaily'] ?? 'Daily Sales';
    final dailySheet = excel[dailySheetName];
    dailySheet.appendRow([
      TextCellValue(labels['date'] ?? 'Date'),
      TextCellValue(labels['sales'] ?? 'Sales'),
      TextCellValue(labels['orderCount'] ?? 'Orders'),
    ]);
    for (final d in dailyData) {
      dailySheet.appendRow([
        TextCellValue(DateFormat('yyyy-MM-dd').format(d.date)),
        DoubleCellValue(d.totalSales),
        IntCellValue(d.orderCount),
      ]);
    }

    // ── Payment method sheet ──
    final paymentSheetName = labels['sheetPayment'] ?? 'By Payment';
    final paymentSheet = excel[paymentSheetName];
    paymentSheet.appendRow([
      TextCellValue(labels['paymentMethod'] ?? 'Payment Method'),
      TextCellValue(labels['sales'] ?? 'Sales'),
    ]);
    for (final entry in paymentData.entries) {
      paymentSheet.appendRow([
        TextCellValue(_paymentLabel(entry.key, labels)),
        DoubleCellValue(entry.value),
      ]);
    }

    // ── Product sales sheet ──
    final productSheetName = labels['sheetProduct'] ?? 'By Product';
    final productSheet = excel[productSheetName];
    productSheet.appendRow([
      TextCellValue(labels['rank'] ?? 'Rank'),
      TextCellValue(labels['productName'] ?? 'Product Name'),
      TextCellValue(labels['quantitySold'] ?? 'Qty Sold'),
      TextCellValue(labels['sales'] ?? 'Sales'),
    ]);
    for (var i = 0; i < topProducts.length; i++) {
      final p = topProducts[i];
      productSheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(p.productName),
        IntCellValue(p.totalQuantity),
        DoubleCellValue(p.totalSales),
      ]);
    }

    // Delete default Sheet1
    excel.delete('Sheet1');

    final fileName =
        'oda_pos_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
    // RPT-006: Pass fileName so the excel package downloads with the correct name on web.
    // Previously, excel.save() auto-downloaded as "FlutterExcel.xlsx" and then
    // downloadExcelBytes triggered a second download — causing two files.
    excel.save(fileName: kIsWeb ? fileName : null);

    return fileName;
  }

  static String _paymentLabel(String method, Map<String, String> labels) => switch (method) {
        'cash' => labels['cash'] ?? 'Cash',
        'card' => labels['card'] ?? 'Card',
        'qr' => labels['qr'] ?? 'QR',
        'transfer' => labels['transfer'] ?? 'Transfer',
        _ => method,
      };
}
