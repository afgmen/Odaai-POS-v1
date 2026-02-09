import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

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

    // ── 요약 시트 ──
    final summarySheetName = labels['sheetSummary'] ?? '요약';
    final summarySheet = excel[summarySheetName];
    summarySheet.appendRow([
      TextCellValue(labels['title'] ?? 'Oda POS 매출 리포트'),
    ]);
    summarySheet.appendRow([
      TextCellValue(labels['periodText'] ?? '기간: ${DateFormat('yyyy-MM-dd').format(from)} ~ ${DateFormat('yyyy-MM-dd').format(to)}'),
    ]);
    summarySheet.appendRow([TextCellValue('')]);
    summarySheet.appendRow([
      TextCellValue(labels['item'] ?? '항목'),
      TextCellValue(labels['value'] ?? '값'),
    ]);
    summarySheet.appendRow([
      TextCellValue(labels['totalSales'] ?? '총 매출'),
      DoubleCellValue(totalSales),
    ]);
    summarySheet.appendRow([
      TextCellValue(labels['orderCount'] ?? '주문 수'),
      IntCellValue(orderCount),
    ]);
    summarySheet.appendRow([
      TextCellValue(labels['avgOrder'] ?? '평균 주문금액'),
      DoubleCellValue(avgOrder),
    ]);
    summarySheet.appendRow([
      TextCellValue(labels['growthRate'] ?? '성장률 (%)'),
      DoubleCellValue(growth),
    ]);

    // ── 일별 매출 시트 ──
    final dailySheetName = labels['sheetDaily'] ?? '일별 매출';
    final dailySheet = excel[dailySheetName];
    dailySheet.appendRow([
      TextCellValue(labels['date'] ?? '날짜'),
      TextCellValue(labels['sales'] ?? '매출'),
      TextCellValue(labels['orderCount'] ?? '주문 수'),
    ]);
    for (final d in dailyData) {
      dailySheet.appendRow([
        TextCellValue(DateFormat('yyyy-MM-dd').format(d.date)),
        DoubleCellValue(d.totalSales),
        IntCellValue(d.orderCount),
      ]);
    }

    // ── 결제 방법별 시트 ──
    final paymentSheetName = labels['sheetPayment'] ?? '결제 방법별';
    final paymentSheet = excel[paymentSheetName];
    paymentSheet.appendRow([
      TextCellValue(labels['paymentMethod'] ?? '결제 방법'),
      TextCellValue(labels['sales'] ?? '매출'),
    ]);
    for (final entry in paymentData.entries) {
      paymentSheet.appendRow([
        TextCellValue(_paymentLabel(entry.key, labels)),
        DoubleCellValue(entry.value),
      ]);
    }

    // ── 상품별 매출 시트 ──
    final productSheetName = labels['sheetProduct'] ?? '상품별 매출';
    final productSheet = excel[productSheetName];
    productSheet.appendRow([
      TextCellValue(labels['rank'] ?? '순위'),
      TextCellValue(labels['productName'] ?? '상품명'),
      TextCellValue(labels['quantitySold'] ?? '판매 수량'),
      TextCellValue(labels['sales'] ?? '매출'),
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

    // 기본 Sheet1 삭제
    excel.delete('Sheet1');

    // 파일 저장
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'oda_pos_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
    final filePath = '${dir.path}/$fileName';
    final fileBytes = excel.save();
    if (fileBytes != null) {
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
    }

    return filePath;
  }

  static String _paymentLabel(String method, Map<String, String> labels) => switch (method) {
        'cash' => labels['cash'] ?? '현금',
        'card' => labels['card'] ?? '카드',
        'qr' => labels['qr'] ?? 'QR',
        'transfer' => labels['transfer'] ?? '이체',
        _ => method,
      };
}
