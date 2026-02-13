import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/app_database.dart';
import '../constants/closing_constants.dart';

/// PdfExportService Provider
final pdfExportServiceProvider = Provider<PdfExportService>((ref) {
  return PdfExportService();
});

/// PDF 리포트 생성 서비스
class PdfExportService {
  final currencyFormat = NumberFormat.currency(locale: 'ko_KR', symbol: '₩');
  final dateFormat = DateFormat('yyyy-MM-dd');
  final timeFormat = DateFormat('HH:mm');

  /// 일일 마감 PDF 생성
  Future<File> generateClosingReport(
    DailyClosing closing,
    Employee? employee,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 제목
              pw.Header(
                level: 0,
                child: pw.Text(
                  '일일 마감 리포트',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // 마감 정보
              _buildInfoSection(closing, employee),
              pw.SizedBox(height: 20),

              // 매출 요약
              _buildSalesSummary(closing),
              pw.SizedBox(height: 20),

              // 결제 수단별 매출
              _buildPaymentBreakdown(closing),
              pw.SizedBox(height: 20),

              // 시재 관리
              if (closing.actualCash != null)
                _buildCashReconciliation(closing),

              // 특이사항
              if (closing.notes != null && closing.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                _buildNotes(closing),
              ],

              pw.Spacer(),

              // 서명란
              _buildSignatureSection(employee),
            ],
          );
        },
      ),
    );

    // 파일 저장
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'closing_${dateFormat.format(closing.closingDate)}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// 정보 섹션
  pw.Widget _buildInfoSection(DailyClosing closing, Employee? employee) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildInfoRow('마감 날짜', dateFormat.format(closing.closingDate)),
          _buildInfoRow('마감 시각',
              '${dateFormat.format(closing.closedAt)} ${timeFormat.format(closing.closedAt)}'),
          _buildInfoRow('마감 담당', employee?.name ?? '알 수 없음'),
        ],
      ),
    );
  }

  /// 매출 요약
  pw.Widget _buildSalesSummary(DailyClosing closing) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '매출 요약',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            _buildTableRow('총 거래 건수', '${closing.totalTransactions}건'),
            _buildTableRow('총 매출', currencyFormat.format(closing.totalSales)),
            _buildTableRow('평균 거래 금액',
                currencyFormat.format(closing.averageTransaction)),
            _buildTableRow('총 세금', currencyFormat.format(closing.totalTax)),
            _buildTableRow('총 할인', currencyFormat.format(closing.totalDiscount)),
          ],
        ),
      ],
    );
  }

  /// 결제 수단별 매출
  pw.Widget _buildPaymentBreakdown(DailyClosing closing) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '결제 수단별 매출',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            _buildTableRow('현금', currencyFormat.format(closing.cashSales)),
            _buildTableRow('카드', currencyFormat.format(closing.cardSales)),
            _buildTableRow('QR 결제', currencyFormat.format(closing.qrSales)),
            _buildTableRow('계좌이체', currencyFormat.format(closing.transferSales)),
          ],
        ),
      ],
    );
  }

  /// 시재 관리
  pw.Widget _buildCashReconciliation(DailyClosing closing) {
    final isDifferenceAcceptable =
        (closing.cashDifference?.abs() ?? 0) <= ClosingConstants.acceptableCashDifference;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '시재 관리',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            _buildTableRow('예상 현금',
                currencyFormat.format(closing.expectedCash)),
            _buildTableRow('실제 현금',
                currencyFormat.format(closing.actualCash!)),
            _buildTableRow(
              '차액',
              currencyFormat.format(closing.cashDifference!),
              valueColor: isDifferenceAcceptable
                  ? PdfColors.green
                  : PdfColors.red,
            ),
          ],
        ),
      ],
    );
  }

  /// 특이사항
  pw.Widget _buildNotes(DailyClosing closing) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '특이사항',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Text(closing.notes!),
        ),
      ],
    );
  }

  /// 서명란
  pw.Widget _buildSignatureSection(Employee? employee) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('마감 담당자:'),
            pw.SizedBox(height: 30),
            pw.Text('서명: _________________'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('확인자:'),
            pw.SizedBox(height: 30),
            pw.Text('서명: _________________'),
          ],
        ),
      ],
    );
  }

  // 헬퍼 메서드
  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text(value),
        ],
      ),
    );
  }

  pw.TableRow _buildTableRow(
    String label,
    String value, {
    PdfColor? valueColor,
  }) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: valueColor,
            ),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }
}
