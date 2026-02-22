import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../database/app_database.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/tables_providers.dart';
import '../widgets/table_widget.dart';
import '../widgets/status_filter_tabs.dart';
import 'reservations_screen.dart';

/// Table Layout Screen
class TableManagementScreen extends ConsumerStatefulWidget {
  const TableManagementScreen({super.key});

  @override
  ConsumerState<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends ConsumerState<TableManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tableManagement),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.table_restaurant), text: l10n.tableLayout),
            Tab(icon: const Icon(Icons.event_note), text: l10n.reservationManagement),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TableLayoutTab(),
          const ReservationsScreen(),
        ],
      ),
    );
  }
}

/// Table Layout Tab
class _TableLayoutTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final filteredTablesAsync = ref.watch(filteredTablesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tableLayout),
        actions: [
          // Statistics display
          _buildStatistics(ref),
          const SizedBox(width: 8),

          // Add table button
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: l10n.addTable,
            onPressed: () => _showAddTableDialog(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 상태 필터 탭
          const StatusFilterTabs(),

          // 테이블 레이아웃 캔버스
          Expanded(
            child: filteredTablesAsync.when(
              data: (tables) {
                if (tables.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.table_restaurant,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noTables,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showAddTableDialog(context, ref),
                          icon: const Icon(Icons.add),
                          label: Text(l10n.addTable),
                        ),
                      ],
                    ),
                  );
                }

                return _buildTableCanvas(context, ref, tables);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(l10n.errorOccurred(err.toString())),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Statistics display widget
  static Widget _buildStatistics(WidgetRef ref) {
    final availableCountAsync = ref.watch(availableTableCountProvider);
    final occupiedCountAsync = ref.watch(occupiedTableCountProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          availableCountAsync.when(
            data: (count) => _buildStatBadge('Empty', count, Colors.green),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          occupiedCountAsync.when(
            data: (count) => _buildStatBadge('Occupied', count, Colors.red),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  static Widget _buildStatBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 테이블 캔버스 (드래그앤드롭)
  static Widget _buildTableCanvas(
      BuildContext context, WidgetRef ref, List<RestaurantTable> tables) {
    return Container(
      color: Colors.grey[100],
      child: Stack(
        children: tables.map((table) {
          return TableWidget(
            table: table,
            onTap: () => _showTableDetail(context, ref, table),
            onDragEnd: (offset) => _handleTableDragEnd(context, ref, table, offset),
          );
        }).toList(),
      ),
    );
  }

  /// 테이블 드래그 종료 처리
  static Future<void> _handleTableDragEnd(
      BuildContext context, WidgetRef ref, RestaurantTable table, Offset offset) async {
    final dao = ref.read(tablesDaoProvider);

    // 캔버스 경계 체크 (0-1000 범위)
    final x = offset.dx.clamp(0.0, 1000.0);
    final y = offset.dy.clamp(0.0, 1000.0);

    await dao.updateTablePosition(
      tableId: table.id,
      x: x,
      y: y,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Table ${table.tableNumber} position updated'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  /// 테이블 상세 모달
  static void _showTableDetail(BuildContext context, WidgetRef ref, RestaurantTable table) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Table ${table.tableNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${table.status}'),
            Text('Seats: ${table.seats}'),
            Text('Position: (${table.positionX.toInt()}, ${table.positionY.toInt()})'),
            if (table.occupiedAt != null)
              Text('Occupied at: ${_formatTime(table.occupiedAt!)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditTableDialog(context, ref, table);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  /// Add table dialog
  static void _showAddTableDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tableNumberController = TextEditingController();
    final seatsController = TextEditingController(text: '4');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addTable),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tableNumberController,
              decoration: InputDecoration(
                labelText: l10n.tableNumber,
                hintText: l10n.tableNumberHint,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: seatsController,
              decoration: InputDecoration(
                labelText: l10n.seatsCount,
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final tableNumber = tableNumberController.text.trim();
              final seats = int.tryParse(seatsController.text) ?? 4;

              if (tableNumber.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.tableNumberRequired)),
                );
                return;
              }

              final dao = ref.read(tablesDaoProvider);
              await dao.createTable(
                RestaurantTablesCompanion.insert(
                  tableNumber: tableNumber,
                  seats: drift.Value(seats),
                  positionX: const drift.Value(100),
                  positionY: const drift.Value(100),
                ),
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.tableAdded(tableNumber))),
                );
              }
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }

  /// 테이블 수정 다이얼로그
  static void _showEditTableDialog(BuildContext context, WidgetRef ref, RestaurantTable table) {
    final tableNumberController =
        TextEditingController(text: table.tableNumber);
    final seatsController = TextEditingController(text: '${table.seats}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Table ${table.tableNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tableNumberController,
              decoration: const InputDecoration(labelText: 'Table Number'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: seatsController,
              decoration: const InputDecoration(labelText: 'Seats'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Table'),
                  content: Text('Delete table ${table.tableNumber}?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                final dao = ref.read(tablesDaoProvider);
                await dao.softDeleteTable(table.id);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Table ${table.tableNumber} deleted')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              final tableNumber = tableNumberController.text.trim();
              final seats = int.tryParse(seatsController.text) ?? table.seats;

              final dao = ref.read(tablesDaoProvider);
              await dao.updateTableInfo(
                tableId: table.id,
                tableNumber: tableNumber,
                seats: seats,
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Table info updated')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
