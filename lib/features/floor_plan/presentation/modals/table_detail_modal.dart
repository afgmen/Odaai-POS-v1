import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/database_providers.dart';
import '../../../pos/presentation/modals/cancel_reason_modal.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../tables/domain/enums/table_status.dart';
import '../../../tables/data/tables_providers.dart';
import '../../../pos/presentation/screens/pos_main_screen.dart';
import '../../../pos/presentation/screens/bill_request_screen.dart';
import '../../../pos/data/models/order_type.dart';
import 'table_move_modal.dart';
import 'table_merge_modal.dart';

/// TableDetailModal — 사용 중인 테이블의 상세 정보 + 액션 버튼
/// Phase 2: [추가주문] [청구서요청] [테이블이동] [주문취소]
class TableDetailModal extends ConsumerWidget {
  final RestaurantTable table;

  const TableDetailModal({super.key, required this.table});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final status = TableStatus.fromString(table.status);
    final duration = table.occupiedAt != null
        ? DateTime.now().difference(table.occupiedAt!)
        : Duration.zero;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              // 테이블 번호 + 상태 뱃지
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.15),
                  border: Border.all(color: status.color, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    table.tableNumber,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: status.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Table ${table.tableNumber}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: status.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: status.color,
                            ),
                          ),
                        ),
                        if (table.occupiedAt != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.access_time,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(duration),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 32),

          // 테이블 정보
          _InfoRow(label: l10n.seatsCount, value: '${table.seats}'),
          _InfoRow(label: 'Shape', value: table.shape),
          if (table.currentSaleId != null)
            _InfoRow(label: 'Sale ID', value: '#${table.currentSaleId}'),

          const SizedBox(height: 24),

          // 액션 버튼 그리드
          Text(
            'Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),

          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 3.0,
            children: [
              _ActionButton(
                icon: Icons.add_shopping_cart,
                label: 'Add Order',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  // Phase 3: PosMainScreen으로 이동 (추가 주문)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PosMainScreen(
                        tableId: table.id,
                        tableNumber: table.tableNumber,
                        orderType: OrderType.dineIn,
                        existingSaleId: table.currentSaleId,
                      ),
                    ),
                  );
                },
              ),
              _ActionButton(
                icon: Icons.receipt_long,
                label: 'Request Bill',
                color: Colors.purple,
                onTap: () {
                  Navigator.pop(context);
                  if (table.currentSaleId != null) {
                    // Phase 3: BillRequestScreen으로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BillRequestScreen(
                          saleId: table.currentSaleId!,
                          tableId: table.id,
                          tableNumber: table.tableNumber,
                        ),
                      ),
                    );
                  } else {
                    _updateTableStatus(ref, table.id, 'CHECKOUT');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Bill requested for Table ${table.tableNumber}')),
                    );
                  }
                },
              ),
              _ActionButton(
                icon: Icons.swap_horiz,
                label: l10n.moveTable,
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => TableMoveModal(sourceTable: table),
                  );
                },
              ),
              _ActionButton(
                icon: Icons.merge,
                label: 'Merge Table',
                color: AppTheme.primary,
                onTap: () => _showMergeModal(context, ref),
              ),

              _ActionButton(
                icon: Icons.cancel_outlined,
                label: 'Cancel Order',
                color: Colors.red,
                onTap: () => _confirmCancelOrder(context, ref),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 닫기
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.close),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTableStatus(
      WidgetRef ref, int tableId, String status) async {
    final dao = ref.read(tablesDaoProvider);
    await dao.updateTableStatus(tableId: tableId, status: status);
  }


  void _showMergeModal(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => TableMergeModal(currentTable: table, currentSaleId: table.currentSaleId),
    );
  }

  void _confirmCancelOrder(BuildContext context, WidgetRef ref) async {
    // Show cancel reason modal
    await showDialog<String>(
      context: context,
      builder: (ctx) => CancelReasonModal(
        onConfirm: (reason) async {
          // Save cancellation reason to DB
          await _saveCancellation(ref, reason);
          
          // Update table status
          await _updateTableStatus(ref, table.id, 'AVAILABLE');
          
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Order cancelled for Table ${table.tableNumber}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _saveCancellation(WidgetRef ref, String reason) async {
    final db = ref.read(databaseProvider);
    if (table.currentSaleId == null) return;

    try {
      await (db.update(db.sales)..where((s) => s.id.equals(table.currentSaleId!)))
          .write(
        SalesCompanion(
          status: const Value('cancelled'),
          cancellationReason: Value(reason),
          cancelledAt: Value(DateTime.now()),
        ),
      );
      debugPrint('[Cancel] Sale ${table.currentSaleId} cancelled: $reason');
    } catch (e) {
      debugPrint('[Cancel] Error saving cancellation: $e');
    }
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
