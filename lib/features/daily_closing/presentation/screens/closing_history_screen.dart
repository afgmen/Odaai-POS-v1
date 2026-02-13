import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/daily_closing_provider.dart';
import '../../domain/services/pdf_export_service.dart';
import '../../domain/constants/closing_constants.dart';
import '../../../../database/app_database.dart';

class ClosingHistoryScreen extends ConsumerWidget {
  const ClosingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final closingsAsync = ref.watch(recentClosingsProvider(30));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.closingHistory),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
            },
            tooltip: l10n.selectPeriod,
          ),
        ],
      ),
      body: closingsAsync.when(
        data: (closings) {
          if (closings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noClosingHistory,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: closings.length,
            itemBuilder: (context, index) {
              final item = closings[index];
              return _ClosingHistoryCard(
                closing: item.closing,
                employee: item.employee,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                l10n.loadClosingHistoryFailed,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.tryAgainLater,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClosingHistoryCard extends ConsumerWidget {
  final DailyClosing closing;
  final Employee? employee;

  const _ClosingHistoryCard({
    required this.closing,
    required this.employee,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat =
        NumberFormat.currency(locale: 'ko_KR', symbol: '₩');
    final dateFormat = DateFormat('yyyy-MM-dd');

    final hasCashDifference = closing.actualCash != null &&
        closing.cashDifference != null &&
        closing.cashDifference!.abs() > ClosingConstants.acceptableCashDifference;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showDetailDialog(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(closing.closingDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (hasCashDifference)
                    const Icon(
                      Icons.warning,
                      color: Colors.orange,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      l10n.totalSales,
                      currencyFormat.format(closing.totalSales),
                      Icons.attach_money,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      l10n.totalTransactions,
                      l10n.transactionsCount(closing.totalTransactions),
                      Icons.receipt_long,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (closing.actualCash != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasCashDifference
                        ? Colors.orange.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 14,
                        color: hasCashDifference
                            ? Colors.orange.shade700
                            : Colors.green.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${l10n.cashDifference}: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        currencyFormat.format(closing.cashDifference!),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: hasCashDifference
                              ? Colors.orange.shade700
                              : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    employee?.name ?? l10n.unknown,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, size: 20),
                    onPressed: () => _generatePdf(context, ref),
                    tooltip: l10n.generatePdf,
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, size: 20),
                    onPressed: () => _showDetailDialog(context, ref),
                    tooltip: l10n.viewDetails,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat =
        NumberFormat.currency(locale: 'ko_KR', symbol: '₩');
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.closingDetails} - ${DateFormat('yyyy-MM-dd').format(closing.closingDate)}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(l10n.closingTime, dateFormat.format(closing.closedAt)),
              _buildDetailRow(l10n.assignedEmployee, employee?.name ?? l10n.unknown),
              const Divider(),
              _buildDetailRow(l10n.totalTransactions, l10n.transactionsCount(closing.totalTransactions)),
              _buildDetailRow(l10n.totalSales, currencyFormat.format(closing.totalSales)),
              _buildDetailRow(
                  l10n.averageTransaction, currencyFormat.format(closing.averageTransaction)),
              const Divider(),
              _buildDetailRow(l10n.cash, currencyFormat.format(closing.cashSales)),
              _buildDetailRow(l10n.card, currencyFormat.format(closing.cardSales)),
              _buildDetailRow(l10n.qr, currencyFormat.format(closing.qrSales)),
              _buildDetailRow(l10n.transferSales, currencyFormat.format(closing.transferSales)),
              const Divider(),
              _buildDetailRow(l10n.taxTotal, currencyFormat.format(closing.totalTax)),
              _buildDetailRow(l10n.discountTotal, currencyFormat.format(closing.totalDiscount)),
              if (closing.actualCash != null) ...[
                const Divider(),
                _buildDetailRow(
                    l10n.expectedCash, currencyFormat.format(closing.expectedCash)),
                _buildDetailRow(
                    l10n.actualCash, currencyFormat.format(closing.actualCash!)),
                _buildDetailRow(
                  l10n.cashDifference,
                  currencyFormat.format(closing.cashDifference!),
                  isWarning: closing.cashDifference!.abs() > 1000.0,
                ),
              ],
              if (closing.notes != null && closing.notes!.isNotEmpty) ...[
                const Divider(),
                Text(
                  l10n.specialNotes,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(closing.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isWarning ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdf(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final pdfService = ref.read(pdfExportServiceProvider);
      final file = await pdfService.generateClosingReport(
        closing,
        employee,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pdfSaved(file.path)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pdfGenerationFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
