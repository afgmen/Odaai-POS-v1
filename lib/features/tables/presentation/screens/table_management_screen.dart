import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/app_database.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../floor_plan/data/floor_plan_providers.dart';
import '../../../floor_plan/presentation/widgets/floor_zone_widget.dart';
import '../../../floor_plan/presentation/widgets/floor_element_widget.dart';
import '../../data/tables_providers.dart';
import '../widgets/table_widget.dart';
import '../widgets/status_filter_tabs.dart';
import 'reservations_screen.dart';
import '../../../floor_plan/presentation/modals/add_zone_modal.dart';
import '../../../floor_plan/presentation/modals/add_element_modal.dart';
import '../../../floor_plan/presentation/modals/add_table_modal.dart';
import '../../../kds/data/kitchen_cancellation_provider.dart';

/// Table Layout Screen (Phase 0: Floor Plan Designer 통합)
class TableManagementScreen extends ConsumerStatefulWidget {
  const TableManagementScreen({super.key});

  @override
  ConsumerState<TableManagementScreen> createState() =>
      _TableManagementScreenState();
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
    debugPrint('[Tables] TableManagementScreen rebuilt at ${DateTime.now()}');
    
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tableManagement),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
                icon: const Icon(Icons.table_restaurant),
                text: l10n.tableLayout),
            Tab(
                icon: const Icon(Icons.event_note),
                text: l10n.reservationManagement),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _FloorPlanDesignerTab(),
          const ReservationsScreen(),
        ],
      ),
    );
  }
}

/// Floor Plan Designer Tab (Phase 0)
/// zones → elements → tables 순서로 Stack 렌더링
/// 하단 toolbar: [Add Zone] [Add Element] [Add Table] [Preview] [Save]
class _FloorPlanDesignerTab extends ConsumerStatefulWidget {
  const _FloorPlanDesignerTab();

  @override
  ConsumerState<_FloorPlanDesignerTab> createState() =>
      _FloorPlanDesignerTabState();
}

class _FloorPlanDesignerTabState extends ConsumerState<_FloorPlanDesignerTab> {
  int? _selectedTableId;   // 선택된 테이블 ID (하이라이트용)
  int? _selectedZoneId;    // 선택된 구역 ID (하이라이트용)
  int? _selectedElementId; // 선택된 요소 ID (하이라이트용)

  /// InteractiveViewer의 현재 변환(스케일·이동)을 추적
  final TransformationController _transformationController =
      TransformationController();

  /// 캔버스 컨테이너의 화면 위치를 가져오기 위한 키
  final GlobalKey _canvasContainerKey = GlobalKey();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filteredTablesAsync = ref.watch(filteredTablesProvider);
    final zonesAsync = ref.watch(allZonesStreamProvider);
    final elementsAsync = ref.watch(allElementsStreamProvider);

    // B-UAT: KDS 취소 알림 감지
    final cancellations = ref.watch(kitchenCancellationProvider);
    // 새 취소 알림이 있으면 SnackBar로 표시 (최신 1개)
    ref.listen(kitchenCancellationProvider, (prev, next) {
      if (next.isNotEmpty && (prev == null || prev.isEmpty || next.first.orderId != prev.first.orderId)) {
        final notification = next.first;
        final tableInfo = notification.tableNumber != null
            ? ' (Table: ${notification.tableNumber})'
            : '';
        final reasonInfo = notification.reason != null
            ? ': ${notification.reason}'
            : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cancel, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚠️ Kitchen cancelled order #${notification.orderId}$tableInfo$reasonInfo',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ref.read(kitchenCancellationProvider.notifier).dismiss(notification.orderId);
              },
            ),
          ),
        );
      }
    });

    return Scaffold(
      body: Column(
        children: [
          // B-UAT: KDS 취소 알림 배너 (미확인 알림이 있을 때)
          if (cancellations.isNotEmpty)
            Material(
              color: Colors.red.shade50,
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Kitchen Cancellations', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      content: SizedBox(
                        width: 360,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: cancellations.map((n) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.warning_amber, color: Colors.orange),
                            title: Text('Order #${n.orderId}${n.tableNumber != null ? ' — Table: ${n.tableNumber}' : ''}'),
                            subtitle: Text(n.reason ?? 'No reason provided'),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                ref.read(kitchenCancellationProvider.notifier).dismiss(n.orderId);
                              },
                            ),
                          )).toList(),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            ref.read(kitchenCancellationProvider.notifier).dismissAll();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Dismiss All'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.cancel, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${cancellations.length} kitchen cancellation${cancellations.length > 1 ? 's' : ''} — tap to review',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.red, size: 18),
                    ],
                  ),
                ),
              ),
            ),

          // 상태 필터 탭 + 통계
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                const Expanded(child: StatusFilterTabs()),
                const SizedBox(width: 8),
                _buildStatistics(ref),
              ],
            ),
          ),

          // 캔버스
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  key: _canvasContainerKey,
                  color: const Color(0xFFF5F5F5),
                  child: LayoutBuilder(
                builder: (context, constraints) {
                  return InteractiveViewer(
                    transformationController: _transformationController,
                    boundaryMargin: const EdgeInsets.all(100),
                    minScale: 0.5,
                    maxScale: 2.0,
                    child: SizedBox(
                      width: 1000,
                      height: 700,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Layer 1: Zones (바닥)
                          ...zonesAsync.when(
                            data: (zones) => zones.map((zone) =>
                                FloorZoneWidget(
                                  key: ValueKey('zone_${zone.id}'),
                                  zone: zone,
                                  isDraggable: true,
                                  isSelected: _selectedZoneId == zone.id,
                                  onTap: () {
                                    setState(() {
                                      _selectedZoneId = _selectedZoneId == zone.id ? null : zone.id;
                                      _selectedElementId = null;
                                      _selectedTableId = null;
                                    });
                                    _showZoneDetail(context, ref, zone);
                                  },
                                  onDragEnd: (offset) =>
                                      _handleZoneDragEnd(ref, zone, offset),
                                )),
                            loading: () => <Widget>[],
                            error: (_, _) => <Widget>[],
                          ),

                          // Layer 2: Elements (중간)
                          ...elementsAsync.when(
                            data: (elements) => elements.map((element) =>
                                FloorElementWidget(
                                  key: ValueKey('element_${element.id}'),
                                  element: element,
                                  isDraggable: true,
                                  isSelected: _selectedElementId == element.id,
                                  onTap: () {
                                    setState(() {
                                      _selectedElementId = _selectedElementId == element.id ? null : element.id;
                                      _selectedZoneId = null;
                                      _selectedTableId = null;
                                    });
                                    _showElementDetail(context, ref, element);
                                  },
                                  onDragEnd: (offset) => _handleElementDragEnd(
                                      ref, element, offset),
                                )),
                            loading: () => <Widget>[],
                            error: (_, _) => <Widget>[],
                          ),

                          // Layer 3: Tables (최상단)
                          ...filteredTablesAsync.when(
                            data: (tables) => tables.map((table) =>
                                TableWidget(
                                  key: ValueKey(table.id),
                                  table: table,
                                  isSelected: _selectedTableId == table.id,
                                  onTap: () {
                                    setState(() {
                                      _selectedTableId = _selectedTableId == table.id
                                          ? null
                                          : table.id;
                                      _selectedZoneId = null;
                                      _selectedElementId = null;
                                    });
                                    _showTableDetail(context, ref, table);
                                  },
                                  onDragEnd: (offset) => _handleTableDragEnd(
                                      context, ref, table, offset),
                                )),
                            loading: () => <Widget>[],
                            error: (_, _) => <Widget>[],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
                // Zoom level indicator (bottom-right overlay)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: ListenableBuilder(
                    listenable: _transformationController,
                    builder: (context, _) {
                      final scale = _transformationController.value.getMaxScaleOnAxis();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(scale * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Bottom Toolbar
          _buildBottomToolbar(context, ref, l10n),
        ],
      ),
    );
  }

  /// Statistics badges
  Widget _buildStatistics(WidgetRef ref) {
    // Use the reactive stream provider so badges update in real-time
    final countAsync = ref.watch(tableCountByStatusProvider);

    return countAsync.when(
      data: (counts) {
        final emptyCount = counts['AVAILABLE'] ?? 0;
        final busyCount = counts.entries
            .where((e) => e.key != 'AVAILABLE')
            .fold(0, (sum, e) => sum + e.value);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatBadge('Empty', emptyCount, Colors.green),
            const SizedBox(width: 6),
            _buildStatBadge('Busy', busyCount, Colors.red),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(8)),
            child: Text('$count',
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Bottom toolbar: [Add Zone] [Add Element] [Add Table] [Preview] [Save]
  Widget _buildBottomToolbar(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ToolbarButton(
            icon: Icons.dashboard_outlined,
            label: l10n.addZone,
            onPressed: () => _showAddZoneDialog(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.door_front_door,
            label: l10n.addElement,
            onPressed: () => _showAddElementDialog(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.add_circle_outline,
            label: l10n.addTable,
            onPressed: () => _showAddTableDialog(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.fit_screen_outlined,
            label: 'Reset View',
            onPressed: _resetView,
          ),
          _ToolbarButton(
            icon: Icons.visibility_outlined,
            label: l10n.preview,
            onPressed: () => _showPreview(context, ref),
          ),
          _ToolbarButton(
            icon: Icons.save_outlined,
            label: l10n.saveLayout,
            color: Colors.green,
            onPressed: () => _saveLayout(context),
          ),
        ],
      ),
    );
  }

  // ─── Zone Handlers ───

  void _showAddZoneDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => const AddZoneModal(),
    );
    
    if (result == true && context.mounted) {
      // Zone list will auto-refresh via stream provider
    }
  }

    void _showZoneDetail(BuildContext context, WidgetRef ref, FloorZone zone) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AddZoneModal(existingZone: zone),
    );
    if (mounted) setState(() => _selectedZoneId = null);
    if (result == true && context.mounted) {
      // Zone list will auto-refresh via stream provider
    }
  }

  Future<void> _handleZoneDragEnd(
      WidgetRef ref, FloorZone zone, Offset canvasOffset) async {
    final dao = ref.read(floorZoneDaoProvider);
    await dao.updateZonePositionAndSize(
      zoneId: zone.id,
      posX: canvasOffset.dx,
      posY: canvasOffset.dy,
      width: zone.width,
      height: zone.height,
    );
  }

  // ─── Element Handlers ───

  void _showAddElementDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => const AddElementModal(),
    );
    
    if (result == true && context.mounted) {
      // Element list will auto-refresh via stream provider
    }
  }

    void _showElementDetail(
      BuildContext context, WidgetRef ref, FloorElement element) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(element.label ?? element.elementType),
        content: Text(
            'Type: ${element.elementType}\nPosition: (${element.posX.toInt()}, ${element.posY.toInt()})'),
        actions: [
          TextButton(
            onPressed: () async {
              final dao = ref.read(floorElementDaoProvider);
              await dao.deleteElement(element.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    if (mounted) setState(() => _selectedElementId = null);
  }

  Future<void> _handleElementDragEnd(
      WidgetRef ref, FloorElement element, Offset canvasOffset) async {
    final dao = ref.read(floorElementDaoProvider);
    await dao.updateElementPosition(
      elementId: element.id,
      posX: canvasOffset.dx,
      posY: canvasOffset.dy,
    );
  }

  // ─── Table Handlers ───

  void _showAddTableDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => const AddTableModal(),
    );
    
    if (result == true && context.mounted) {
      // Table list will auto-refresh via stream provider
    }
  }

    void _showTableDetail(
      BuildContext context, WidgetRef ref, RestaurantTable table) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AddTableModal(existingTable: table),
    );
    // 모달 닫히면 선택 해제
    if (mounted) {
      setState(() => _selectedTableId = null);
    }
    if (result == true && context.mounted) {
      // Table list will auto-refresh via stream provider
    }
  }

  
  Future<void> _handleTableDragEnd(BuildContext context, WidgetRef ref,
      RestaurantTable table, Offset canvasOffset) async {
    final dao = ref.read(tablesDaoProvider);
    await dao.updateTablePosition(
      tableId: table.id,
      x: canvasOffset.dx,
      y: canvasOffset.dy,
    );
  }

  // ─── View Controls ───

  void _resetView() {
    _transformationController.value = Matrix4.identity();
  }

  // ─── Preview & Save ───

  void _showPreview(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Floor Plan Preview'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: const _FloorPlanPreview(),
            ),
          ],
        ),
      ),
    );
  }

  void _saveLayout(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Layout saved automatically ✓'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

/// Toolbar button widget
class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: c),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w500, color: c)),
          ],
        ),
      ),
    );
  }
}

/// Shape option widget for Add Table dialog

/// Read-only preview of floor plan (no drag)
class _FloorPlanPreview extends ConsumerWidget {
  const _FloorPlanPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(allTablesStreamProvider);
    final zonesAsync = ref.watch(allZonesStreamProvider);
    final elementsAsync = ref.watch(allElementsStreamProvider);

    return Container(
      color: const Color(0xFFF5F5F5),
      child: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(50),
        minScale: 0.5,
        maxScale: 2.0,
        child: SizedBox(
          width: 1000,
          height: 700,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Zones (read-only)
              ...zonesAsync.when(
                data: (zones) => zones.map((zone) => FloorZoneWidget(
                      zone: zone,
                      isDraggable: false,
                    )),
                loading: () => <Widget>[],
                error: (_, _) => <Widget>[],
              ),
              // Elements (read-only)
              ...elementsAsync.when(
                data: (elements) => elements.map((el) => FloorElementWidget(
                      element: el,
                      isDraggable: false,
                    )),
                loading: () => <Widget>[],
                error: (_, _) => <Widget>[],
              ),
              // Tables (read-only)
              ...tablesAsync.when(
                data: (tables) => tables.map((table) => TableWidget(
                      table: table,
                      onTap: () {},
                      isDraggable: false,
                    )),
                loading: () => <Widget>[],
                error: (_, _) => <Widget>[],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
