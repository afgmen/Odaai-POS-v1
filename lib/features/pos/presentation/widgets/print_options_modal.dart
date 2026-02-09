import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../l10n/app_localizations.dart';
import '../../services/receipt_pdf_service.dart';

/// 인쇄 용지 타입
enum PrintFormat {
  receipt,
  a4;
}

extension PrintFormatL10n on PrintFormat {
  String getLabel(AppLocalizations l10n) => switch (this) {
        PrintFormat.receipt => l10n.receiptFormat,
        PrintFormat.a4 => l10n.a4Format,
      };

  String getDescription(AppLocalizations l10n) => switch (this) {
        PrintFormat.receipt => l10n.thermalPrinter,
        PrintFormat.a4 => l10n.regularPrinter,
      };
}

/// 인쇄 옵션 모달
/// - 용지 선택 (80mm / A4)
/// - 미리보기
/// - 인쇄 실행
class PrintOptionsModal extends StatefulWidget {
  final String saleNumber;
  final List<SaleItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final String paymentMethod;
  final double cashPaid;
  final DateTime saleDate;

  const PrintOptionsModal({
    super.key,
    required this.saleNumber,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    required this.total,
    required this.paymentMethod,
    this.cashPaid = 0,
    required this.saleDate,
  });

  @override
  State<PrintOptionsModal> createState() => _PrintOptionsModalState();
}

class _PrintOptionsModalState extends State<PrintOptionsModal> {
  PrintFormat _format = PrintFormat.receipt;
  bool _isPrinting = false;

  ReceiptData get _receiptData => ReceiptData(
        saleNumber: widget.saleNumber,
        items: widget.items,
        subtotal: widget.subtotal,
        discount: widget.discount,
        total: widget.total,
        paymentMethod: widget.paymentMethod,
        cashPaid: widget.cashPaid,
        saleDate: widget.saleDate,
      );

  Map<String, String> _buildReceiptLabels() {
    final l10n = AppLocalizations.of(context)!;
    return {
      'orderNumber': l10n.orderNumber,
      'date': l10n.receiptDate,
      'productName': l10n.productName,
      'quantity': l10n.quantity,
      'unitPrice': l10n.unitPrice,
      'subtotal': l10n.subtotal,
      'discount': l10n.discount,
      'total': l10n.total,
      'paymentMethod': l10n.paymentMethod,
      'cash': l10n.cash,
      'card': l10n.card,
      'transfer': l10n.transfer,
      'cashPaid': l10n.cashPaidAmount,
      'change': l10n.change,
      'thankYou': l10n.thankYouMessage,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 헤더 ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.receiptPrint,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 22, color: AppTheme.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.divider),
          const SizedBox(height: 16),

          // ── 용지 선택 ──────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.paperFormat,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: PrintFormat.values.map((fmt) {
                    final isActive = _format == fmt;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: fmt == PrintFormat.values.last ? 0 : 8),
                        child: InkWell(
                          onTap: () => setState(() => _format = fmt),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFFE8F0FE) : AppTheme.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive ? AppTheme.primary : AppTheme.divider,
                                width: isActive ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  fmt == PrintFormat.receipt ? Icons.receipt : Icons.description,
                                  size: 28,
                                  color: isActive ? AppTheme.primary : AppTheme.iconColor,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  fmt.getLabel(AppLocalizations.of(context)!),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                    color: isActive ? AppTheme.primary : AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  fmt.getDescription(AppLocalizations.of(context)!),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── 버튼 영역 ──────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 미리보기 버튼
                OutlinedButton.icon(
                  onPressed: _isPrinting ? null : _showPreview,
                  icon: const Icon(Icons.preview, size: 20),
                  label: Text(AppLocalizations.of(context)!.preview),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppTheme.primary),
                    foregroundColor: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                // 인쇄 버튼
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isPrinting ? null : _printReceipt,
                    icon: _isPrinting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.print, size: 22),
                    label: Text(
                      _isPrinting ? AppLocalizations.of(context)!.printing : AppLocalizations.of(context)!.print,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      disabledBackgroundColor: AppTheme.textDisabled,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// PDF 미리보기 표시 (printing 패키지의 PdfPreview 활용)
  void _showPreview() {
    final data = _receiptData;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            backgroundColor: AppTheme.cardWhite,
            elevation: 0,
            title: Text(
              AppLocalizations.of(context)!.receiptPreview,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppTheme.divider),
            ),
          ),
          body: PdfPreview(
            build: (_) async {
              final receiptLabels = _buildReceiptLabels();
              final doc = _format == PrintFormat.receipt
                  ? await ReceiptPdfService.generateReceipt(data, labels: receiptLabels)
                  : await ReceiptPdfService.generateReceiptA4(data, labels: receiptLabels);
              return doc.save();
            },
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            pdfFileName: AppLocalizations.of(context)!.receiptFileName(data.saleNumber),
          ),
        ),
      ),
    );
  }

  /// 직접 인쇄 (시스템 프린터 다이얼로그)
  Future<void> _printReceipt() async {
    setState(() => _isPrinting = true);

    try {
      final data = _receiptData;
      final receiptLabels = _buildReceiptLabels();
      final doc = _format == PrintFormat.receipt
          ? await ReceiptPdfService.generateReceipt(data, labels: receiptLabels)
          : await ReceiptPdfService.generateReceiptA4(data, labels: receiptLabels);

      final pdfBytes = await doc.save();

      await Printing.layoutPdf(
        onLayout: (_) => pdfBytes,
        name: AppLocalizations.of(context)!.receiptFileName(data.saleNumber),
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.printError(e.toString())),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }
}
