import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/reports_provider.dart';
import '../../services/report_excel_service.dart';
import '../widgets/date_range_picker.dart';
import '../widgets/kpi_summary_card.dart';
import '../widgets/payment_pie_chart.dart';
import '../widgets/product_bar_chart.dart';
import '../widgets/revenue_line_chart.dart';

/// 매출 통계/리포트 화면
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        titleSpacing: 16,
        title: Text(
          l10n.salesReport,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          // 엑셀 내보내기 버튼
          IconButton(
            onPressed: () => _exportExcel(context, ref),
            icon: const Icon(Icons.file_download_outlined),
            tooltip: l10n.exportExcel,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.divider),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 기간 선택 ──
            const DateRangePicker(),
            const SizedBox(height: 16),

            // ── KPI 카드 ──
            _buildKpiSection(ref, l10n),
            const SizedBox(height: 16),

            // ── 매출 추이 (Line chart) ──
            _buildRevenueChart(ref, l10n),
            const SizedBox(height: 16),

            // ── 결제 방법별 (Pie chart) ──
            _buildPaymentChart(ref, l10n),
            const SizedBox(height: 16),

            // ── 상품별 매출 (Bar chart) ──
            _buildProductChart(ref, l10n),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// KPI 카드 섹션
  Widget _buildKpiSection(WidgetRef ref, AppLocalizations l10n) {
    final totalAsync = ref.watch(reportTotalSalesProvider);
    final countAsync = ref.watch(reportOrderCountProvider);
    final avgAsync = ref.watch(reportAvgOrderProvider);
    final growthAsync = ref.watch(reportGrowthProvider);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        SizedBox(
          width: 170,
          child: totalAsync.when(
            data: (total) {
              final growth = growthAsync.valueOrNull;
              return KpiSummaryCard(
                title: l10n.totalSalesAmount,
                value: '₩${_fmt(total)}',
                icon: Icons.attach_money,
                color: AppTheme.primary,
                bgColor: const Color(0xFFE8F0FE),
                subtitle: growth != null
                    ? '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%'
                    : null,
              );
            },
            loading: () => _loadingCard(),
            error: (_, __) => _errorCard(l10n),
          ),
        ),
        SizedBox(
          width: 170,
          child: countAsync.when(
            data: (count) => KpiSummaryCard(
              title: l10n.orderCount,
              value: '$count${l10n.orderUnit}',
              icon: Icons.receipt_long,
              color: AppTheme.success,
              bgColor: const Color(0xFFE6FAF2),
            ),
            loading: () => _loadingCard(),
            error: (_, __) => _errorCard(l10n),
          ),
        ),
        SizedBox(
          width: 170,
          child: avgAsync.when(
            data: (avg) => KpiSummaryCard(
              title: l10n.avgOrderAmount,
              value: '₩${_fmt(avg)}',
              icon: Icons.bar_chart,
              color: AppTheme.warning,
              bgColor: const Color(0xFFFFF3E0),
            ),
            loading: () => _loadingCard(),
            error: (_, __) => _errorCard(l10n),
          ),
        ),
      ],
    );
  }

  /// 매출 추이 차트
  Widget _buildRevenueChart(WidgetRef ref, AppLocalizations l10n) {
    final asyncData = ref.watch(dailySalesChartProvider);

    return asyncData.when(
      data: (data) => RevenueLineChart(data: data),
      loading: () => _loadingContainer(height: 260),
      error: (_, __) => _errorContainer(height: 260, l10n: l10n),
    );
  }

  /// 결제 방법별 차트
  Widget _buildPaymentChart(WidgetRef ref, AppLocalizations l10n) {
    final asyncData = ref.watch(paymentPieChartProvider);

    return asyncData.when(
      data: (data) => PaymentPieChart(data: data),
      loading: () => _loadingContainer(height: 200),
      error: (_, __) => _errorContainer(height: 200, l10n: l10n),
    );
  }

  /// 상품별 매출 차트
  Widget _buildProductChart(WidgetRef ref, AppLocalizations l10n) {
    final asyncData = ref.watch(topProductsBarChartProvider);

    return asyncData.when(
      data: (data) => ProductBarChart(data: data),
      loading: () => _loadingContainer(height: 300),
      error: (_, __) => _errorContainer(height: 300, l10n: l10n),
    );
  }

  /// 엑셀 내보내기
  Future<void> _exportExcel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final dailyData = await ref.read(dailySalesChartProvider.future);
      final paymentData = await ref.read(paymentPieChartProvider.future);
      final topProducts = await ref.read(topProductsBarChartProvider.future);
      final totalSales = await ref.read(reportTotalSalesProvider.future);
      final orderCount = await ref.read(reportOrderCountProvider.future);
      final avgOrder = await ref.read(reportAvgOrderProvider.future);
      final growth = await ref.read(reportGrowthProvider.future);
      final range = ref.read(reportDateRangeProvider);

      final filePath = await ReportExcelService.exportSalesReport(
        dailyData: dailyData,
        paymentData: paymentData,
        topProducts: topProducts,
        totalSales: totalSales,
        orderCount: orderCount,
        avgOrder: avgOrder,
        growth: growth,
        from: range.from,
        to: range.to,
        labels: {
          'sheetSummary': l10n.reportSheetSummary,
          'title': l10n.reportTitle,
          'periodText': l10n.reportPeriod(
            DateFormat('yyyy-MM-dd').format(range.from),
            DateFormat('yyyy-MM-dd').format(range.to),
          ),
          'item': l10n.reportItem,
          'value': l10n.reportValue,
          'totalSales': l10n.reportTotalSales,
          'orderCount': l10n.reportOrderCount,
          'avgOrder': l10n.reportAvgOrder,
          'growthRate': l10n.reportGrowthRate,
          'sheetDaily': l10n.reportSheetDaily,
          'date': l10n.reportDate,
          'sales': l10n.reportSales,
          'sheetPayment': l10n.reportSheetPayment,
          'paymentMethod': l10n.paymentMethod,
          'sheetProduct': l10n.reportSheetProduct,
          'rank': l10n.reportRank,
          'productName': l10n.productName,
          'quantitySold': l10n.reportQuantitySold,
          'cash': l10n.cash,
          'card': l10n.card,
          'qr': l10n.qr,
          'transfer': l10n.transfer,
        },
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.excelSaved(filePath)),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportFailed(e.toString())),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  // ── 유틸리티 위젯 ──

  Widget _loadingCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: const SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppTheme.primary),
        ),
      ),
    );
  }

  Widget _errorCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: SizedBox(
        height: 80,
        child: Center(
          child: Text(l10n.error, style: const TextStyle(color: AppTheme.error)),
        ),
      ),
    );
  }

  Widget _loadingContainer({required double height}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: const Center(
        child:
            CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
      ),
    );
  }

  Widget _errorContainer({required double height, required AppLocalizations l10n}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Center(
        child: Text(l10n.errorOccurred, style: const TextStyle(color: AppTheme.error)),
      ),
    );
  }

  String _fmt(double price) {
    return price.toInt().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}
