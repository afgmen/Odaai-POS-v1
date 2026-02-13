import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/daily_closing_dao.dart';

class PaymentBreakdownWidget extends StatelessWidget {
  final SalesAggregation aggregation;
  final GlobalKey? tutorialKey;

  const PaymentBreakdownWidget({
    super.key,
    required this.aggregation,
    this.tutorialKey,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat =
        NumberFormat.currency(locale: 'ko_KR', symbol: '₩');

    final paymentMethods = [
      PaymentMethodData(
        label: l10n.cash,
        amount: aggregation.cashSales,
        icon: Icons.payments,
        color: Colors.green,
      ),
      PaymentMethodData(
        label: l10n.card,
        amount: aggregation.cardSales,
        icon: Icons.credit_card,
        color: Colors.blue,
      ),
      PaymentMethodData(
        label: l10n.qrPaymentSales,
        amount: aggregation.qrSales,
        icon: Icons.qr_code,
        color: Colors.purple,
      ),
      PaymentMethodData(
        label: l10n.transferSales,
        amount: aggregation.transferSales,
        icon: Icons.account_balance,
        color: Colors.orange,
      ),
    ];

    return Card(
      key: tutorialKey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payment, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.paymentMethodBreakdown,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...paymentMethods.map((method) {
              final percentage = aggregation.totalSales > 0
                  ? (method.amount / aggregation.totalSales * 100)
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          method.icon,
                          size: 16,
                          color: method.color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            method.label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          currencyFormat.format(method.amount),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(method.color),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class PaymentMethodData {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  PaymentMethodData({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });
}
