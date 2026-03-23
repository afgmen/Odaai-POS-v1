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
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
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
              // Title
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Daily Closing Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Closing info
              _buildInfoSection(closing, employee),
              pw.SizedBox(height: 20),

              // Sales summary
              _buildSalesSummary(closing),
              pw.SizedBox(height: 20),

              // Payment breakdown
              _buildPaymentBreakdown(closing),
              pw.SizedBox(height: 20),

              // Cash reconciliation
              if (closing.actualCash != null)
                _buildCashReconciliation(closing),

              // Notes
              if (closing.notes != null && closing.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                _buildNotes(closing),
              ],

              pw.Spacer(),

              // Signature section
              _buildSignatureSection(employee),
            ],
          );
        },
      ),
    );

        // Save file
    // B-UAT: Try documents directory, fallback to temp directory on error
    Directory? directory;
    try {
      directory = await getApplicationDocumentsDirectory();
    } catch (_) {
      directory = await getTemporaryDirectory();
    }

    final fileName = 'closing_${dateFormat.format(closing.closingDate)}.pdf';
    final file = File('${directory.path}/$fileName');

    // Ensure directory exists
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    final pdfBytes = await pdf.save();
    await file.writeAsBytes(pdfBytes);

    return file;
  }

  /// Info section
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
          _buildInfoRow('Closing Date', dateFormat.format(closing.closingDate)),
          _buildInfoRow('Closing Time',
              '${dateFormat.format(closing.closedAt)} ${timeFormat.format(closing.closedAt)}'),
          _buildInfoRow('Closed By', employee?.name ?? 'Unknown'),
        ],
      ),
    );
  }

  /// Sales summary
  pw.Widget _buildSalesSummary(DailyClosing closing) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Sales Summary',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            _buildTableRow('Total Transactions', '${closing.totalTransactions}'),
            _buildTableRow('Total Sales', currencyFormat.format(closing.totalSales)),
            _buildTableRow('Average Transaction',
                currencyFormat.format(closing.averageTransaction)),
            _buildTableRow('Total Tax', currencyFormat.format(closing.totalTax)),
            _buildTableRow('Total Discount', currencyFormat.format(closing.totalDiscount)),
          ],
        ),
      ],
    );
  }

  /// Payment breakdown
  pw.Widget _buildPaymentBreakdown(DailyClosing closing) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Sales by Payment Method',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            _buildTableRow('Cash', currencyFormat.format(closing.cashSales)),
            _buildTableRow('Card', currencyFormat.format(closing.cardSales)),
            _buildTableRow('QR Payment', currencyFormat.format(closing.qrSales)),
            _buildTableRow('Bank Transfer', currencyFormat.format(closing.transferSales)),
          ],
        ),
      ],
    );
  }

  /// Cash reconciliation
  pw.Widget _buildCashReconciliation(DailyClosing closing) {
    final isDifferenceAcceptable =
        (closing.cashDifference?.abs() ?? 0) <= ClosingConstants.acceptableCashDifference;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Cash Reconciliation',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            _buildTableRow('Expected Cash',
                currencyFormat.format(closing.expectedCash)),
            _buildTableRow('Actual Cash',
                currencyFormat.format(closing.actualCash!)),
            _buildTableRow(
              'Difference',
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

  /// Notes
  pw.Widget _buildNotes(DailyClosing closing) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Notes',
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

  /// Signature section
  pw.Widget _buildSignatureSection(Employee? employee) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Closed By:'),
            pw.SizedBox(height: 30),
            pw.Text('Signature: _________________'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Verified By:'),
            pw.SizedBox(height: 30),
            pw.Text('Signature: _________________'),
          ],
        ),
      ],
    );
  }

  // Helper methods
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
