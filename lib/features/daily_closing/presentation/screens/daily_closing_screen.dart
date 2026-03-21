import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/permission_gate_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/permission_modules.dart';
import '../../../../database/app_database.dart';
import '../../data/daily_closing_dao.dart';
import '../../providers/daily_closing_provider.dart';
import '../../domain/services/closing_service.dart';
import '../../domain/services/pdf_export_service.dart';
import '../../domain/constants/closing_constants.dart';
import '../widgets/closing_summary_card.dart';
import '../widgets/payment_breakdown_widget.dart';
import '../widgets/cash_count_dialog.dart';
import 'closing_history_screen.dart';
import '../../../user_guide/configs/daily_closing_tutorial.dart';
import '../../../user_guide/configs/tutorial_registry.dart';
import '../../../user_guide/presentation/widgets/help_button.dart';
import '../../../../providers/currency_provider.dart';

class DailyClosingScreen extends ConsumerStatefulWidget {
  const DailyClosingScreen({super.key});

  @override
  ConsumerState<DailyClosingScreen> createState() => _DailyClosingScreenState();
}

class _DailyClosingScreenState extends ConsumerState<DailyClosingScreen> {
  late DateTime selectedDate;
  double? actualCash;
  final notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        actualCash = null;
      });
    }
  }

  Future<void> _performClosing() async {
    final l10n = AppLocalizations.of(context)!;
    final closingService = ref.read(closingServiceProvider);

    ClosingResult result;
    try {
      result = await closingService.performClosing(
        date: selectedDate,
        actualCash: actualCash,
        notes: notesController.text.isEmpty ? null : notesController.text,
      );
    } catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 26),
              SizedBox(width: 10),
              Text('Closing Failed'),
            ],
          ),
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.green,
        ),
      );

      final shouldGeneratePdf = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.generatePdf),
          content: Text(l10n.savePdfQuestion(l10n.dailyClosingReport)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.generate),
            ),
          ],
        ),
      );

      if (shouldGeneratePdf == true && result.closingId != null) {
        await _generatePdf(result.closingId!);
      }

      // 화면 초기화
      setState(() {
        selectedDate = DateTime.now();
        actualCash = null;
        notesController.clear();
      });
    } else {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 26),
              SizedBox(width: 10),
              Text('Closing Failed'),
            ],
          ),
          content: Text(
            result.message,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _generatePdf(int closingId) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // B-103: PDF 생성용 단건 읽기 — DAO 직접 호출
      final closingAsync = await ref
          .read(dailyClosingDaoProvider)
          .getClosingByDate(selectedDate);

      if (closingAsync == null) {
        throw Exception(l10n.loadingClosingData);
      }

      final pdfService = ref.read(pdfExportServiceProvider);
      final file = await pdfService.generateClosingReport(
        closingAsync,
        null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pdfSaved(file.path)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pdfGenerationFailed(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PermissionGateWidget(
      permission: PermissionModules.REVENUE_DAILY_VIEW,
      fallback: Scaffold(
        appBar: AppBar(
          title: Text(l10n.dailyClosing),
        ),
        body: const Center(
          child: AccessDeniedCard(
            message: 'No permission to view daily sales',
          ),
        ),
      ),
      child: _buildClosingContent(context),
    );
  }

  Widget _buildClosingContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final aggregationAsync = ref.watch(salesAggregationProvider(selectedDate));
    final closingAsync = ref.watch(closingByDateProvider(selectedDate));

    final tutorialConfig = TutorialRegistry.getTutorial('daily_closing_tutorial');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dailyClosing),
        actions: [
          if (tutorialConfig != null)
            HelpButton(
              config: tutorialConfig,
              style: HelpButtonStyle.icon,
            ),
          IconButton(
            key: DailyClosingTutorialKeys.historyButton,
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ClosingHistoryScreen(),
                ),
              );
            },
            tooltip: l10n.closingHistory,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              key: DailyClosingTutorialKeys.dateSelector,
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(l10n.closingDate),
                subtitle: Text(
                  DateFormat('yyyy-MM-dd').format(selectedDate),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: () => _selectDate(context),
              ),
            ),
            const SizedBox(height: 16),

            closingAsync.when(
              data: (closing) {
                if (closing != null) {
                  return Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${l10n.alreadyClosed} (${DateFormat('yyyy-MM-dd HH:mm').format(closing.closedAt)})',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),

            aggregationAsync.when(
              data: (aggregation) {
                final hasNoSales = aggregation == null || aggregation.totalTransactions == 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 매출 없음 경고 배너 (버튼은 여전히 표시)
                    if (hasNoSales) ...[
                      Card(
                        color: Colors.orange.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.orange.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.orange.shade700, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.noSalesForDate,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade800,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'You can still perform closing to record this date.',
                                      style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 매출 있을 때만 요약 카드/결제 내역/현금 관리 표시
                    if (!hasNoSales) ..._buildSalesWidgets(aggregation),

                    _buildNotesSection(),
                    const SizedBox(height: 24),

                    _buildActionButtons(closingAsync.value),
                  ],
                );
              },
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text(
                        l10n.loadClosingHistoryFailed,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.tryAgainLater,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 매출 있을 때만 표시할 위젯 목록 (aggregation non-null 보장)
  List<Widget> _buildSalesWidgets(SalesAggregation? aggregation) {
    if (aggregation == null) return [];
    return [
      ClosingSummaryCard(
        aggregation: aggregation,
        tutorialKey: DailyClosingTutorialKeys.summaryCard,
      ),
      const SizedBox(height: 16),
      PaymentBreakdownWidget(
        aggregation: aggregation,
        tutorialKey: DailyClosingTutorialKeys.paymentBreakdown,
      ),
      const SizedBox(height: 16),
      _buildCashManagement(aggregation),
      const SizedBox(height: 16),
    ];
  }

  Widget _buildCashManagement(SalesAggregation aggregation) {
    final l10n = AppLocalizations.of(context)!;
    final priceFormatter = ref.watch(priceFormatterProvider);
    return Card(
      key: DailyClosingTutorialKeys.cashReconciliation,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.cashReconciliation,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow(
              l10n.expectedCash,
              priceFormatter.format(aggregation.cashSales),
              isBold: true,
            ),
            if (actualCash != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                l10n.actualCash,
                priceFormatter.format(actualCash!),
                isBold: true,
              ),
              const SizedBox(height: 8),
              _buildCashDifference(aggregation.cashSales, actualCash!),
            ],
            const SizedBox(height: 16),
            SizedBox(
              key: DailyClosingTutorialKeys.actualCashButton,
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit),
                label: Text(actualCash == null ? l10n.enterActualCash : l10n.editActualCash(l10n.actualCash)),
                onPressed: () => _showCashCountDialog(aggregation.cashSales),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashDifference(double expected, double actual) {
    final l10n = AppLocalizations.of(context)!;
    final priceFormatter = ref.watch(priceFormatterProvider);
    final difference = actual - expected;
    final isAcceptable = difference.abs() <= ClosingConstants.acceptableCashDifference;
    final color = isAcceptable ? Colors.green : Colors.red;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l10n.cashDifference,
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          priceFormatter.format(difference),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      key: DailyClosingTutorialKeys.notesSection,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.specialNotes,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                hintText: l10n.notesPlaceholder,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(DailyClosing? closing) {
    final l10n = AppLocalizations.of(context)!;
    final canClose = closing == null;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: Text('PDF ${l10n.save}'),
            onPressed: canClose
                ? null
                : () async {
                    await _generatePdf(closing.id);
                  },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            key: DailyClosingTutorialKeys.performClosingButton,
            icon: const Icon(Icons.lock),
            label: Text(l10n.performClosing),
            onPressed: canClose ? _performClosing : null,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Future<void> _showCashCountDialog(double expectedCash) async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) => CashCountDialog(expectedCash: expectedCash),
    );

    if (result != null) {
      setState(() {
        actualCash = result;
      });
    }
  }
}
