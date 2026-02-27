import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../tables/data/tables_providers.dart';
import '../../../tables/domain/enums/table_status.dart';
import '../../data/floor_plan_providers.dart';
import '../widgets/floor_zone_widget.dart';
import '../widgets/floor_element_widget.dart';
import '../modals/new_order_modal.dart';
import '../modals/table_detail_modal.dart';

/// Floor Plan Operational Screen (Phase 2)
/// 읽기 전용 (드래그 불가), 실시간 상태 업데이트, 7가지 색상 코딩
class FloorPlanScreen extends ConsumerStatefulWidget {
  final bool previewMode;

  const FloorPlanScreen({super.key, this.previewMode = false});

  @override
  ConsumerState<FloorPlanScreen> createState() => _FloorPlanScreenState();
}

class _FloorPlanScreenState extends ConsumerState<FloorPlanScreen> {
  String? _selectedZoneFilter;
  late Timer _clockTimer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tablesAsync = ref.watch(allTablesStreamProvider);
    final zonesAsync = ref.watch(allZonesStreamProvider);
    final elementsAsync = ref.watch(allElementsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.floorPlan),
        centerTitle: false,
        actions: [
          // 디지털 시계
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _currentTime,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: Colors.greenAccent,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Zone 필터 칩 + 통계 스트립
          _buildZoneFilterAndStats(zonesAsync, tablesAsync),

          // 플로어 플랜 캔버스
          Expanded(
            child: Container(
              color: const Color(0xFFF5F5F5),
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(100),
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
                        data: (zones) => zones.map((z) => FloorZoneWidget(
                              zone: z,
                              isDraggable: false,
                            )),
                        loading: () => <Widget>[],
                        error: (_, __) => <Widget>[],
                      ),

                      // Elements (read-only)
                      ...elementsAsync.when(
                        data: (elements) =>
                            elements.map((e) => FloorElementWidget(
                                  element: e,
                                  isDraggable: false,
                                )),
                        loading: () => <Widget>[],
                        error: (_, __) => <Widget>[],
                      ),

                      // Tables (tappable, not draggable)
                      ...tablesAsync.when(
                        data: (tables) {
                          final filtered = _selectedZoneFilter == null
                              ? tables
                              : tables
                                  .where((t) =>
                                      t.zoneId.toString() == _selectedZoneFilter ||
                                      _selectedZoneFilter == 'all')
                                  .toList();
                          return filtered
                              .map((table) => _OperationalTableWidget(
                                    table: table,
                                    onTap: () => _onTableTap(context, ref, table),
                                  ));
                        },
                        loading: () => <Widget>[],
                        error: (_, __) => <Widget>[],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Zone 필터 칩 + 통계 스트립
  Widget _buildZoneFilterAndStats(
    AsyncValue<List<FloorZone>> zonesAsync,
    AsyncValue<List<RestaurantTable>> tablesAsync,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Colors.white,
      child: Column(
        children: [
          // Zone filter chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _selectedZoneFilter == null || _selectedZoneFilter == 'all',
                  onTap: () => setState(() => _selectedZoneFilter = null),
                ),
                ...zonesAsync.when(
                  data: (zones) => zones.map((z) => _FilterChip(
                        label: z.name,
                        isSelected: _selectedZoneFilter == z.id.toString(),
                        onTap: () =>
                            setState(() => _selectedZoneFilter = z.id.toString()),
                      )),
                  loading: () => <Widget>[],
                  error: (_, __) => <Widget>[],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // 통계 스트립
          tablesAsync.when(
            data: (tables) => _buildStatsStrip(tables),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsStrip(List<RestaurantTable> tables) {
    final counts = <String, int>{};
    for (final t in tables) {
      counts[t.status] = (counts[t.status] ?? 0) + 1;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TableStatus.values.map((status) {
          final count = counts[status.value] ?? 0;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: status.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(status.icon, size: 14, color: status.color),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: status.color,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 테이블 탭 핸들러
  void _onTableTap(BuildContext context, WidgetRef ref, RestaurantTable table) {
    final status = TableStatus.fromString(table.status);

    if (status == TableStatus.available) {
      // 빈 테이블 → NewOrderModal
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => NewOrderModal(table: table),
      );
    } else {
      // 사용 중 테이블 → TableDetailModal
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => TableDetailModal(table: table),
      );
    }
  }
}

/// 운영용 테이블 위젯 (드래그 불가, 경과시간 표시, CHECKOUT 펄싱)
class _OperationalTableWidget extends StatefulWidget {
  final RestaurantTable table;
  final VoidCallback onTap;

  const _OperationalTableWidget({
    required this.table,
    required this.onTap,
  });

  @override
  State<_OperationalTableWidget> createState() => _OperationalTableWidgetState();
}

class _OperationalTableWidgetState extends State<_OperationalTableWidget>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupPulse();
  }

  @override
  void didUpdateWidget(covariant _OperationalTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.table.status != widget.table.status) {
      _setupPulse();
    }
  }

  void _setupPulse() {
    final status = TableStatus.fromString(widget.table.status);
    if (status == TableStatus.checkout) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..repeat(reverse: true);
      _pulseAnimation =
          Tween<double>(begin: 0.6, end: 1.0).animate(_pulseController!);
    } else {
      _pulseController?.dispose();
      _pulseController = null;
      _pulseAnimation = null;
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  ({double w, double h, BorderRadius radius}) _shapeMetrics() {
    final shape = widget.table.shape;
    switch (shape) {
      case 'round':
        return (w: 100.0, h: 100.0, radius: BorderRadius.circular(50));
      case 'rectangle':
        return (w: 160.0, h: 100.0, radius: BorderRadius.circular(12));
      case 'square':
      default:
        return (w: 100.0, h: 100.0, radius: BorderRadius.circular(12));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = TableStatus.fromString(widget.table.status);
    final metrics = _shapeMetrics();

    Widget card = _buildCard(status, metrics);

    if (_pulseAnimation != null) {
      card = AnimatedBuilder(
        animation: _pulseAnimation!,
        builder: (_, child) => Opacity(
          opacity: _pulseAnimation!.value,
          child: child,
        ),
        child: card,
      );
    }

    return Positioned(
      left: widget.table.positionX,
      top: widget.table.positionY,
      child: GestureDetector(
        onTap: widget.onTap,
        child: card,
      ),
    );
  }

  Widget _buildCard(
      TableStatus status,
      ({double w, double h, BorderRadius radius}) metrics) {
    return Container(
      width: metrics.w,
      height: metrics.h,
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        border: Border.all(color: status.color, width: 2.5),
        borderRadius: metrics.radius,
        boxShadow: [
          BoxShadow(
            color: status.color.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 테이블 번호
          Text(
            widget.table.tableNumber,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: status.color,
            ),
          ),

          // 상태 뱃지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status.label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: status.color,
              ),
            ),
          ),

          // 경과 시간
          if (widget.table.occupiedAt != null &&
              status != TableStatus.available &&
              status != TableStatus.cleaning)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _formatDuration(
                    DateTime.now().difference(widget.table.occupiedAt!)),
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }
}

/// Zone filter chip
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
