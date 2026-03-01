import 'package:flutter/material.dart';
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
class _FloorPlanDesignerTab extends ConsumerWidget {
  const _FloorPlanDesignerTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final filteredTablesAsync = ref.watch(filteredTablesProvider);
    final zonesAsync = ref.watch(allZonesStreamProvider);
    final elementsAsync = ref.watch(allElementsStreamProvider);

    return Scaffold(
      body: Column(
        children: [
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
            child: Container(
              color: const Color(0xFFF5F5F5),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return InteractiveViewer(
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
                                  zone: zone,
                                  isDraggable: true,
                                  onTap: () =>
                                      _showZoneDetail(context, ref, zone),
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
                                  element: element,
                                  isDraggable: true,
                                  onTap: () =>
                                      _showElementDetail(context, ref, element),
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
                                  table: table,
                                  onTap: () =>
                                      _showTableDetail(context, ref, table),
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
          ),

          // Bottom Toolbar
          _buildBottomToolbar(context, ref, l10n),
        ],
      ),
    );
  }

  /// Statistics badges
  Widget _buildStatistics(WidgetRef ref) {
    final availableCountAsync = ref.watch(availableTableCountProvider);
    final occupiedCountAsync = ref.watch(occupiedTableCountProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        availableCountAsync.when(
          data: (count) => _buildStatBadge('Empty', count, Colors.green),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const SizedBox(width: 6),
        occupiedCountAsync.when(
          data: (count) => _buildStatBadge('Busy', count, Colors.red),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
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
    
    if (result == true && context.mounted) {
      // Zone list will auto-refresh via stream provider
    }
  }

  Future<void> _handleZoneDragEnd(
      WidgetRef ref, FloorZone zone, Offset offset) async {
    final dao = ref.read(floorZoneDaoProvider);
    await dao.updateZonePositionAndSize(
      zoneId: zone.id,
      posX: offset.dx.clamp(0, 1000),
      posY: offset.dy.clamp(0, 700),
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
      BuildContext context, WidgetRef ref, FloorElement element) {
    showDialog(
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
  }

  Future<void> _handleElementDragEnd(
      WidgetRef ref, FloorElement element, Offset offset) async {
    final dao = ref.read(floorElementDaoProvider);
    await dao.updateElementPosition(
      elementId: element.id,
      posX: offset.dx.clamp(0, 1000),
      posY: offset.dy.clamp(0, 700),
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
    
    if (result == true && context.mounted) {
      // Table list will auto-refresh via stream provider
    }
  }

  
  Future<void> _handleTableDragEnd(BuildContext context, WidgetRef ref,
      RestaurantTable table, Offset offset) async {
    final dao = ref.read(tablesDaoProvider);
    await dao.updateTablePosition(
      tableId: table.id,
      x: offset.dx.clamp(0, 1000),
      y: offset.dy.clamp(0, 700),
    );
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
class _ShapeOption extends StatelessWidget {
  final String label;
  final String shape;
  final bool isSelected;
  final VoidCallback onTap;

  const _ShapeOption({
    required this.label,
    required this.shape,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
                  isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: shape == 'round'
                  ? BorderRadius.circular(24)
                  : BorderRadius.circular(
                      shape == 'rectangle' ? 8 : 8),
              shape: BoxShape.rectangle,
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.blue : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              )),
        ],
      ),
    );
  }
}

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
