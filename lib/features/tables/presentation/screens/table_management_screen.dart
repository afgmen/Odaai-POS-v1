import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../database/app_database.dart';
import '../../data/tables_providers.dart';
import '../widgets/table_widget.dart';
import '../widgets/status_filter_tabs.dart';
import 'reservations_screen.dart';

/// 테이블 레이아웃 화면
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('테이블 관리'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.table_restaurant), text: '테이블 레이아웃'),
            Tab(icon: Icon(Icons.event_note), text: '예약 관리'),
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

/// 테이블 레이아웃 탭
class _TableLayoutTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredTablesAsync = ref.watch(filteredTablesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('테이블 레이아웃'),
        actions: [
          // 통계 표시
          _buildStatistics(ref),
          const SizedBox(width: 8),

          // 테이블 추가 버튼
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: '테이블 추가',
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
                          '테이블이 없습니다',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showAddTableDialog(context, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('테이블 추가'),
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
                    Text('오류 발생: ${err.toString()}'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 통계 표시 위젯
  static Widget _buildStatistics(WidgetRef ref) {
    final availableCountAsync = ref.watch(availableTableCountProvider);
    final occupiedCountAsync = ref.watch(occupiedTableCountProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          availableCountAsync.when(
            data: (count) => _buildStatBadge('빈 테이블', count, Colors.green),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          occupiedCountAsync.when(
            data: (count) => _buildStatBadge('점유 중', count, Colors.red),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  static Widget _buildStatBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
          content: Text('테이블 ${table.tableNumber} 위치 업데이트'),
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
        title: Text('테이블 ${table.tableNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('상태: ${table.status}'),
            Text('좌석: ${table.seats}명'),
            Text('위치: (${table.positionX.toInt()}, ${table.positionY.toInt()})'),
            if (table.occupiedAt != null)
              Text('착석 시간: ${_formatTime(table.occupiedAt!)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditTableDialog(context, ref, table);
            },
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }

  /// 테이블 추가 다이얼로그
  static void _showAddTableDialog(BuildContext context, WidgetRef ref) {
    final tableNumberController = TextEditingController();
    final seatsController = TextEditingController(text: '4');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('테이블 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tableNumberController,
              decoration: const InputDecoration(
                labelText: '테이블 번호',
                hintText: '예: 1, A1, VIP-1',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: seatsController,
              decoration: const InputDecoration(
                labelText: '좌석 수',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final tableNumber = tableNumberController.text.trim();
              final seats = int.tryParse(seatsController.text) ?? 4;

              if (tableNumber.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('테이블 번호를 입력하세요')),
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
                  SnackBar(content: Text('테이블 $tableNumber 추가됨')),
                );
              }
            },
            child: const Text('추가'),
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
        title: Text('테이블 ${table.tableNumber} 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tableNumberController,
              decoration: const InputDecoration(labelText: '테이블 번호'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: seatsController,
              decoration: const InputDecoration(labelText: '좌석 수'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('테이블 삭제'),
                  content: Text('테이블 ${table.tableNumber}를 삭제하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('삭제'),
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
                    SnackBar(content: Text('테이블 ${table.tableNumber} 삭제됨')),
                  );
                }
              }
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
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
                  const SnackBar(content: Text('테이블 정보 업데이트됨')),
                );
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
