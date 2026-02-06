import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';

/// 영수증 화면
/// 결제 완료 후 주문 상세 정보를 영수증 형태로 표시
class ReceiptScreen extends StatelessWidget {
  final String saleNumber;
  final List<SaleItem> items;
  final double subtotal;
  final double discount;        // 할인금액
  final double total;
  final String paymentMethod;   // 'cash' | 'card' | 'qr'
  final double cashPaid;        // 현금 투입금액 (현금 결제 시만)
  final DateTime saleDate;

  const ReceiptScreen({
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

  // ── 결제 방법 라벨 매핑 ──────────────────────
  String get _paymentLabel => switch (paymentMethod) {
        'cash' => '현금',
        'card' => '카드',
        'qr' => 'QR',
        _ => paymentMethod,
      };

  String get _paymentIcon => switch (paymentMethod) {
        'cash' => '💵',
        'card' => '💳',
        'qr' => '📱',
        _ => '💰',
      };

  @override
  Widget build(BuildContext context) {
    final change = paymentMethod == 'cash' ? (cashPaid - total) : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        title: const Text(
          '영수증',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.divider),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 380,
            decoration: BoxDecoration(
              color: AppTheme.cardWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── 상단 로고 + 날짜 ──────────────────
                Padding(
                  padding: const EdgeInsets.only(top: 28, left: 24, right: 24, bottom: 4),
                  child: Column(
                    children: [
                      const Icon(Icons.point_of_sale, size: 36, color: AppTheme.primary),
                      const SizedBox(height: 6),
                      const Text(
                        'Oda POS',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(saleDate),
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),

                // ── 주문번호 ──────────────────────────
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '주문번호',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          saleNumber,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── 구분선 (점선) ──────────────────────
                const SizedBox(height: 18),
                _DashedDivider(),

                // ── 상품 목록 ──────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 헤더 행
                      Row(
                        children: const [
                          Expanded(child: Text('상품명', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary))),
                          SizedBox(width: 44, child: Text('수량', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary), textAlign: TextAlign.center)),
                          SizedBox(width: 70, child: Text('단가', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary), textAlign: TextAlign.end)),
                          SizedBox(width: 74, child: Text('소계', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary), textAlign: TextAlign.end)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 상품 행 리스트
                      ...items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.productName,
                                style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: 44,
                              child: Text(
                                '${item.quantity}',
                                style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 70,
                              child: Text(
                                '₩${_fmt(item.unitPrice)}',
                                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                                textAlign: TextAlign.end,
                              ),
                            ),
                            SizedBox(
                              width: 74,
                              child: Text(
                                '₩${_fmt(item.total)}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),

                // ── 구분선 ─────────────────────────────
                _DashedDivider(),

                // ── 금액 요약 ──────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: Column(
                    children: [
                      // 소계
                      _SummaryRow(label: '소계', value: subtotal),
                      // 할인 행 (할인이 있을 때만)
                      if (discount > 0) ...[
                        const SizedBox(height: 6),
                        _SummaryRow(label: '할인', value: discount, isDiscount: true),
                      ],
                      const SizedBox(height: 6),
                      // 합계 (볼드)
                      _SummaryRow(label: '합계', value: total, isBold: true),
                    ],
                  ),
                ),

                // ── 구분선 ─────────────────────────────
                _DashedDivider(),

                // ── 결제 정보 ──────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 결제 방법
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('결제 방법', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                          Text(
                            '$_paymentIcon $_paymentLabel',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                      // 현금 결제 시 투입금액 + 거스름돈
                      if (paymentMethod == 'cash') ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('투입금액', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                            Text(
                              '₩${_fmt(cashPaid)}',
                              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('거스름돈', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                            Text(
                              '₩${_fmt(change)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.success),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // ── 구분선 ─────────────────────────────
                _DashedDivider(),

                // ── 감사 메시지 ─────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    '이용해 주셔서 감사합니다!',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // ── 하단: 새 주문 버튼 ────────────────────
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('새 주문', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}

// ── 유틸리티 헬퍼 ──────────────────────────────────

/// 금액 포맷 (천단위 콤마)
String _fmt(double price) {
  return price.toInt().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
}

/// 날짜·시간 포맷
String _formatDateTime(DateTime dt) {
  return '${dt.year}-${_p(dt.month)}-${_p(dt.day)} '
      '${_p(dt.hour)}:${_p(dt.minute)}';
}

String _p(int v) => v.toString().padLeft(2, '0');

// ── 금액 요약 행 ──────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;
  final bool isDiscount;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isDiscount ? AppTheme.error : (isBold ? AppTheme.textPrimary : AppTheme.textSecondary),
          ),
        ),
        Text(
          isDiscount ? '-₩${_fmt(value)}' : '₩${_fmt(value)}',
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: isDiscount ? AppTheme.error : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ── 점선 구분선 ──────────────────────────────────

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: CustomPaint(
        size: const Size(double.infinity, 1),
        painter: _DashedLinePainter(),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.divider
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const gapWidth = 5.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
