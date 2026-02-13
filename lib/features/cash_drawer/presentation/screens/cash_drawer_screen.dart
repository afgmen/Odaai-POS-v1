import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/currency_provider.dart';
import '../../providers/cash_drawer_provider.dart';

/// 시재 관리 (Cash Drawer) 화면
class CashDrawerScreen extends ConsumerWidget {
  const CashDrawerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final logsAsync = ref.watch(todayCashLogsProvider);
    final balanceAsync = ref.watch(currentDrawerBalanceProvider);
    final isOpenedAsync = ref.watch(isTodayOpenedProvider);
    final priceFormatter = ref.watch(priceFormatterProvider);
    final currencyFormat = NumberFormat('#,###');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text(l10n.cashDrawerManagement), centerTitle: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 현재 시재 카드 ─────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance_wallet, color: AppTheme.primary, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.currentCashDrawer, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                          balanceAsync.when(
                            data: (balance) => Text(
                              priceFormatter.format(balance),
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                            ),
                            loading: () => const Text('...', style: TextStyle(fontSize: 28)),
                            error: (_, __) => Text(priceFormatter.format(0), style: const TextStyle(fontSize: 28)),
                          ),
                        ],
                      ),
                    ),
                    isOpenedAsync.when(
                      data: (isOpened) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isOpened ? AppTheme.success.withAlpha(20) : AppTheme.error.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOpened ? l10n.openStatus : l10n.closedStatus,
                          style: TextStyle(
                            color: isOpened ? AppTheme.success : AppTheme.error,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ─── 액션 버튼 ──────────────────────────
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.lock_open,
                    label: l10n.openDrawer,
                    color: AppTheme.success,
                    onTap: () => _showAmountDialog(context, ref, l10n.openDrawer, 'open'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.lock,
                    label: l10n.closeDrawer,
                    color: AppTheme.error,
                    onTap: () => _showCloseDialog(context, ref),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.add,
                    label: l10n.deposit,
                    color: AppTheme.primary,
                    onTap: () => _showAmountDialog(context, ref, l10n.deposit, 'deposit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.remove,
                    label: l10n.withdraw,
                    color: Colors.orange,
                    onTap: () => _showAmountDialog(context, ref, l10n.withdraw, 'withdraw'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ─── 오늘 시재 로그 ─────────────────────
            Text(l10n.todayTransactions, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            logsAsync.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text(l10n.noTransactionsToday, style: const TextStyle(color: AppTheme.textSecondary))),
                    ),
                  );
                }

                // 요약 계산
                double totalDeposits = 0;
                double totalWithdraws = 0;
                double totalSales = 0;
                double totalRefunds = 0;
                for (final log in logs) {
                  switch (log.type) {
                    case 'deposit':
                    case 'open':
                      totalDeposits += log.amount;
                      break;
                    case 'withdraw':
                    case 'close':
                      totalWithdraws += log.amount.abs();
                      break;
                    case 'sale':
                      totalSales += log.amount;
                      break;
                    case 'refund':
                      totalRefunds += log.amount.abs();
                      break;
                  }
                }

                return Column(
                  children: [
                    // 요약 카드
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            _SummaryItem(label: l10n.deposit, value: totalDeposits, color: AppTheme.success),
                            _SummaryItem(label: l10n.salesLabel, value: totalSales, color: AppTheme.primary),
                            _SummaryItem(label: l10n.refundLabel, value: totalRefunds, color: AppTheme.warning),
                            _SummaryItem(label: l10n.withdraw, value: totalWithdraws, color: AppTheme.error),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 상세 로그
                    ...logs.map((log) => Card(
                          child: ListTile(
                            leading: _LogIcon(type: log.type),
                            title: Text(_logTypeLabel(context, log.type),
                                style: const TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: Text(
                              '${timeFormat.format(log.createdAt)}${log.note != null ? ' · ${log.note}' : ''}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${log.amount >= 0 ? '+' : ''}${priceFormatter.format(log.amount.abs())}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: log.amount >= 0 ? AppTheme.success : AppTheme.error,
                                  ),
                                ),
                                Text(
                                  l10n.balance(priceFormatter.format(log.balanceAfter, includeSymbol: false)),
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(l10n.msgError(e.toString())),
            ),
          ],
        ),
      ),
    );
  }

  String _logTypeLabel(BuildContext context, String type) {
    final l10n = AppLocalizations.of(context)!;
    return switch (type) {
      'open' => l10n.openDrawer,
      'close' => l10n.closeDrawer,
      'deposit' => l10n.deposit,
      'withdraw' => l10n.withdraw,
      'sale' => l10n.salesLabel,
      'refund' => l10n.refundLabel,
      _ => type,
    };
  }

  void _showAmountDialog(BuildContext context, WidgetRef ref, String title, String type) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.amountLabel,
                  prefixText: '${ref.read(priceFormatterProvider).currency.symbol} ',
                  prefixIcon: const Icon(Icons.payments)
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: InputDecoration(labelText: l10n.memoLabel, prefixIcon: const Icon(Icons.note)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                if (amount <= 0) return;

                final dao = ref.read(cashDrawerDaoProvider);
                final currentBalance = await dao.getCurrentDrawerBalance();

                final isWithdraw = type == 'withdraw' || type == 'close';
                final effectiveAmount = isWithdraw ? -amount : amount;
                final newBalance = currentBalance + effectiveAmount;

                await dao.logCashDrawer(CashDrawerLogsCompanion.insert(
                  type: type,
                  amount: effectiveAmount,
                  balanceBefore: currentBalance,
                  balanceAfter: newBalance,
                  note: Value(noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim()),
                ));

                // Provider 새로고침
                ref.invalidate(currentDrawerBalanceProvider);
                ref.invalidate(isTodayOpenedProvider);

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(l10n.confirm),
            ),
          ],
        );
      },
    );
  }

  void _showCloseDialog(BuildContext context, WidgetRef ref) async {
    final dao = ref.read(cashDrawerDaoProvider);
    final currentBalance = await dao.getCurrentDrawerBalance();
    final priceFormatter = ref.read(priceFormatterProvider);
    final currencyFormat = NumberFormat('#,###');
    final countCtrl = TextEditingController();

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(l10n.closeSettlement),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.systemBalance(priceFormatter.format(currentBalance, includeSymbol: false)),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: countCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.actualCashAmount,
                  prefixText: '${priceFormatter.currency.symbol} ',
                  prefixIcon: const Icon(Icons.calculate),
                  hintText: l10n.countCashHint,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            ElevatedButton(
              onPressed: () async {
                final counted = double.tryParse(countCtrl.text) ?? 0;
                final diff = counted - currentBalance;
                final note = diff == 0
                    ? l10n.normalClose
                    : '${l10n.difference('${diff > 0 ? '+' : ''}${priceFormatter.format(diff.abs(), includeSymbol: false)}')} (${l10n.actualCashAmount}: ${priceFormatter.format(counted, includeSymbol: false)})';

                await dao.logCashDrawer(CashDrawerLogsCompanion.insert(
                  type: 'close',
                  amount: -currentBalance,
                  balanceBefore: currentBalance,
                  balanceAfter: 0,
                  note: Value(note),
                ));

                ref.invalidate(currentDrawerBalanceProvider);
                ref.invalidate(isTodayOpenedProvider);

                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.closeComplete(note)), backgroundColor: AppTheme.success),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              child: Text(l10n.closeDrawer),
            ),
          ],
        );
      },
    );
  }
}

// ─── 위젯 ──────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends ConsumerWidget {
  final String label;
  final double value;
  final Color color;

  const _SummaryItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceFormatter = ref.watch(priceFormatterProvider);
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            priceFormatter.format(value),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _LogIcon extends StatelessWidget {
  final String type;
  const _LogIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = switch (type) {
      'open' => (Icons.lock_open, AppTheme.success),
      'close' => (Icons.lock, AppTheme.error),
      'deposit' => (Icons.arrow_downward, AppTheme.success),
      'withdraw' => (Icons.arrow_upward, AppTheme.error),
      'sale' => (Icons.shopping_cart, AppTheme.primary),
      'refund' => (Icons.undo, AppTheme.warning),
      _ => (Icons.circle, AppTheme.textSecondary),
    };
    return CircleAvatar(
      radius: 18,
      backgroundColor: color.withAlpha(20),
      child: Icon(icon, color: color, size: 18),
    );
  }
}
