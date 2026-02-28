import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/database_providers.dart';

/// BillRequestScreen — 라운드별 아이템 목록 + 할인 + 세금 + 결제
/// Phase 3: TableDetailModal [청구서 요청] 에서 진입
class BillRequestScreen extends ConsumerWidget {
  final int saleId;
  final int tableId;
  final String tableNumber;

  const BillRequestScreen({
    super.key,
    required this.saleId,
    required this.tableId,
    required this.tableNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final salesDao = ref.watch(salesDaoProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.requestBill} — Table $tableNumber'),
        backgroundColor: Colors.purple.shade50,
        foregroundColor: Colors.purple,
      ),
      body: FutureBuilder<Sale>(
        future: salesDao.getSaleById(saleId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final sale = snapshot.data!;
          return FutureBuilder<List<SaleItem>>(
            future: salesDao.getSaleItems(saleId),
            builder: (context, itemsSnapshot) {
              if (!itemsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = itemsSnapshot.data!;
              return _BillContent(
                sale: sale,
                items: items,
                tableNumber: tableNumber,
              );
            },
          );
        },
      ),
    );
  }
}

class _BillContent extends StatelessWidget {
  final Sale sale;
  final List<SaleItem> items;
  final String tableNumber;

  const _BillContent({
    required this.sale,
    required this.items,
    required this.tableNumber,
  });

  List<Widget> _buildGroupedItems(List<SaleItem> items) {
    final grouped = <int, List<SaleItem>>{};
    for (final item in items) {
      final round = item.roundNumber;
      grouped.putIfAbsent(round, () => []).add(item);
    }
    final sortedRounds = grouped.keys.toList()..sort();

    // Only show round headers if there are multiple rounds
    if (sortedRounds.length <= 1) {
      return items.map((item) => _BillItemRow(item: item)).toList();
    }

    return sortedRounds.expand((round) => [
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Round $round',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
      ...grouped[round]!.map((item) => _BillItemRow(item: item)),
    ]).toList();
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = items.fold<double>(0, (sum, i) => sum + i.total);
    final tax = sale.tax;
    final discount = sale.discount;
    final total = sale.total;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Center(
            child: Column(
              children: [
                const Icon(Icons.receipt_long, size: 48, color: Colors.purple),
                const SizedBox(height: 8),
                Text(
                  'Table $tableNumber',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Bill #${sale.id}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Divider(height: 32),

          // 아이템 목록 (grouped by round)
          ..._buildGroupedItems(items),

          const Divider(height: 24),

          // 소계
          _SummaryRow(label: 'Subtotal', amount: subtotal),
          if (discount > 0)
            _SummaryRow(
                label: 'Discount', amount: -discount, color: Colors.green),
          if (tax > 0) _SummaryRow(label: 'Tax', amount: tax),
          const Divider(height: 16),
          _SummaryRow(
            label: 'TOTAL',
            amount: total,
            isBold: true,
            fontSize: 20,
          ),

          const SizedBox(height: 32),

          // 결제 버튼
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: PaymentModal 연결
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment processing...')),
                );
              },
              icon: const Icon(Icons.payment, size: 24),
              label: const Text('Proceed to Payment',
                  style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillItemRow extends StatelessWidget {
  final SaleItem item;

  const _BillItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${item.quantity} × ${_formatCurrency(item.unitPrice)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(item.total),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0)}đ';
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isBold;
  final double fontSize;
  final Color? color;

  const _SummaryRow({
    required this.label,
    required this.amount,
    this.isBold = false,
    this.fontSize = 14,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            '${amount < 0 ? '-' : ''}${amount.abs().toStringAsFixed(0)}đ',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
