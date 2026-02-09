import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../database/app_database.dart';

/// 영수증 데이터 모델
class ReceiptData {
  final String saleNumber;
  final List<SaleItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final String paymentMethod;
  final double cashPaid;
  final DateTime saleDate;
  final String storeName;

  const ReceiptData({
    required this.saleNumber,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    required this.total,
    required this.paymentMethod,
    this.cashPaid = 0,
    required this.saleDate,
    this.storeName = 'Oda POS',
  });

  double get change =>
      paymentMethod == 'cash' ? (cashPaid - total).clamp(0, double.infinity) : 0;

  String paymentLabelFrom(Map<String, String> labels) => switch (paymentMethod) {
        'cash' => labels['cash'] ?? 'Cash',
        'card' => labels['card'] ?? 'Card',
        'qr' => 'QR',
        'transfer' => labels['transfer'] ?? 'Transfer',
        _ => paymentMethod,
      };
}

/// 영수증 PDF 생성 서비스
class ReceiptPdfService {
  // 한글 폰트 로딩 (캐싱용)
  static pw.Font? _koreanFont;

  /// 한글 폰트 로드 (실패 시 null 반환)
  static Future<pw.Font?> _loadKoreanFont() async {
    if (_koreanFont != null) return _koreanFont!;

    try {
      final fontData = await rootBundle.load('assets/fonts/NotoSansKR-Regular.ttf');
      _koreanFont = pw.Font.ttf(fontData);
      return _koreanFont!;
    } catch (e) {
      print('Warning: Failed to load Korean font: $e');
      print('Using default PDF font instead');
      return null;
    }
  }

  /// 80mm 폭 영수증 PDF 문서 생성
  static Future<pw.Document> generateReceipt(ReceiptData data, {Map<String, String> labels = const {}}) async {
    // 한글 폰트 로드 시도 (실패해도 계속 진행)
    final koreanFont = await _loadKoreanFont();

    // 80mm 열감지 용지 (기본 영수증 프린터)
    final pageFormat = PdfPageFormat(
      80 * PdfPageFormat.mm,
      double.infinity,     // 자동 높이
      marginAll: 4 * PdfPageFormat.mm,
    );

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ── 상점명 ─────────────────────
              _buildHeader(data), // Use default font
              pw.SizedBox(height: 4),

              // ── 주문번호 + 날짜 ──────────────
              _buildOrderInfo(data, labels),
              _dashedDivider(),

              // ── 상품 목록 ────────────────────
              _buildItemsTable(data, labels),
              _dashedDivider(),

              // ── 금액 요약 ────────────────────
              _buildSummary(data, labels),
              _dashedDivider(),

              // ── 결제 정보 ────────────────────
              _buildPaymentInfo(data, labels),
              _dashedDivider(),

              // ── 감사 메시지 ──────────────────
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  labels['thankYou'] ?? 'Thank you!',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 12),
            ],
          );
        },
      ),
    );

    return doc;
  }

  /// A4 영수증 (일반 프린터용)
  static Future<pw.Document> generateReceiptA4(ReceiptData data, {Map<String, String> labels = const {}}) async {
    // 한글 폰트 로드
    final koreanFont = await _loadKoreanFont();

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Container(
              width: 280,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(data),
                  pw.SizedBox(height: 6),
                  _buildOrderInfo(data, labels),
                  _dashedDivider(),
                  _buildItemsTable(data, labels),
                  _dashedDivider(),
                  _buildSummary(data, labels),
                  _dashedDivider(),
                  _buildPaymentInfo(data, labels),
                  _dashedDivider(),
                  pw.SizedBox(height: 12),
                  pw.Center(
                    child: pw.Text(
                      labels['thankYou'] ?? 'Thank you!',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return doc;
  }

  // ── 내부 빌더 메서드들 ─────────────────────────

  static pw.Widget _buildHeader(ReceiptData data) {
    return pw.Column(
      children: [
        pw.Center(
          child: pw.Text(
            data.storeName,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildOrderInfo(ReceiptData data, Map<String, String> labels) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('${labels['orderNumber'] ?? 'Order #'}:', style: pw.TextStyle(fontSize: 9)),
            pw.Text(data.saleNumber, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('${labels['date'] ?? 'Date'}:', style: pw.TextStyle(fontSize: 9)),
            pw.Text(_formatDateTime(data.saleDate), style: pw.TextStyle(fontSize: 9)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(ReceiptData data, Map<String, String> labels) {
    return pw.Column(
      children: [
        // 헤더
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 4,
                child: pw.Text(labels['productName'] ?? 'Product', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(
                width: 24,
                child: pw.Text(labels['quantity'] ?? 'Qty', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
              ),
              pw.SizedBox(
                width: 42,
                child: pw.Text(labels['unitPrice'] ?? 'Price', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
              ),
              pw.SizedBox(
                width: 46,
                child: pw.Text(labels['subtotal'] ?? 'Subtotal', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
              ),
            ],
          ),
        ),
        // 상품 행
        ...data.items.map((item) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 1),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text(item.productName, style: pw.TextStyle(fontSize: 9), maxLines: 1),
                  ),
                  pw.SizedBox(
                    width: 24,
                    child: pw.Text('${item.quantity}', style: pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center),
                  ),
                  pw.SizedBox(
                    width: 42,
                    child: pw.Text(_fmt(item.unitPrice), style: pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right),
                  ),
                  pw.SizedBox(
                    width: 46,
                    child: pw.Text(_fmt(item.total), style: pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  static pw.Widget _buildSummary(ReceiptData data, Map<String, String> labels) {
    return pw.Column(
      children: [
        _summaryRow(labels['subtotal'] ?? 'Subtotal', _fmt(data.subtotal)),
        if (data.discount > 0)
          _summaryRow(labels['discount'] ?? 'Discount', '-${_fmt(data.discount)}', isDiscount: true),
        pw.SizedBox(height: 2),
        _summaryRow(labels['total'] ?? 'Total', _fmt(data.total), isBold: true),
      ],
    );
  }

  static pw.Widget _buildPaymentInfo(ReceiptData data, Map<String, String> labels) {
    return pw.Column(
      children: [
        _summaryRow(labels['paymentMethod'] ?? 'Payment', data.paymentLabelFrom(labels)),
        if (data.paymentMethod == 'cash') ...[
          _summaryRow(labels['cashPaid'] ?? 'Paid', _fmt(data.cashPaid)),
          _summaryRow(labels['change'] ?? 'Change', _fmt(data.change), isBold: true),
        ],
      ],
    );
  }

  // ── 유틸리티 ─────────────────────────────────

  static pw.Widget _summaryRow(String label, String value, {bool isBold = false, bool isDiscount = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isBold ? 11 : 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isBold ? 12 : 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _dashedDivider() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Container(
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(
              width: 0.5,
              style: pw.BorderStyle.dashed,
            ),
          ),
        ),
      ),
    );
  }

  static String _fmt(double price) {
    return price.toInt().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  static String _formatDateTime(DateTime dt) {
    return '${dt.year}-${_p(dt.month)}-${_p(dt.day)} '
        '${_p(dt.hour)}:${_p(dt.minute)}:${_p(dt.second)}';
  }

  static String _p(int v) => v.toString().padLeft(2, '0');
}
