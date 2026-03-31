import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/database_providers.dart';

class SplitBillModal extends ConsumerStatefulWidget {
  final Sale sale;
  final List<SaleItem> items;

  const SplitBillModal({super.key, required this.sale, required this.items});

  @override
  ConsumerState<SplitBillModal> createState() => _SplitBillModalState();
}

class _SplitBillModalState extends ConsumerState<SplitBillModal> {
  // Fix #19: 통화 기호 ₫ 통일 (đ → ₫)
  final priceFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
  int _splitCount = 2;
  
  @override
  Widget build(BuildContext context) {
    final perPersonAmount = (widget.sale.total / _splitCount).ceil().toDouble();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Row(
              children: [
                const Icon(Icons.splitscreen, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Text('Split Bill', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Split between:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 16),
                      IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: _splitCount > 2 ? () => setState(() => _splitCount--) : null, color: AppTheme.primary),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(border: Border.all(color: AppTheme.primary), borderRadius: BorderRadius.circular(8)), child: Text('$_splitCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _splitCount < 10 ? () => setState(() => _splitCount++) : null, color: AppTheme.primary),
                      const Text('people'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total:', style: TextStyle(fontSize: 16)), Text(priceFormatter.format(widget.sale.total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
                        const Divider(height: 24),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Per Person ($_splitCount):'), Text(priceFormatter.format(perPersonAmount), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary))]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...List.generate(_splitCount, (i) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: AppTheme.primary, child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      title: Text('Person ${i + 1}'),
                      trailing: Text(priceFormatter.format(perPersonAmount), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  )),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _processSplit,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(vertical: 16), minimumSize: const Size(double.infinity, 0)),
              child: const Text('Process Split', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processSplit() async {
    final db = ref.read(databaseProvider);
    final perPersonAmount = (widget.sale.total / _splitCount).ceil().toDouble();
    
    try {
      for (int i = 0; i < _splitCount; i++) {
        await db.into(db.sales).insert(SalesCompanion.insert(
          saleNumber: '${widget.sale.saleNumber}-S${i + 1}',
          subtotal: drift.Value(perPersonAmount),
          tax: drift.Value(0.0),
          discount: drift.Value(0.0),
          total: drift.Value(perPersonAmount),
          paymentMethod: 'pending',
          status: drift.Value('pending'),
          orderType: drift.Value(widget.sale.orderType),
          tableId: drift.Value(widget.sale.tableId),
          employeeId: drift.Value(widget.sale.employeeId),
        ));
      }
      
      await (db.update(db.sales)..where((t) => t.id.equals(widget.sale.id))).write(SalesCompanion(status: const drift.Value('split')));
      
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill split successfully'), backgroundColor: AppTheme.success));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    }
  }
}
