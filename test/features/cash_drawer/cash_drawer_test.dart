import 'package:flutter_test/flutter_test.dart';

/// Pure business logic tests for cash drawer calculations.
/// These test the computation rules used in the cash drawer screen
/// without requiring a database or widget tree.

void main() {
  group('Cash drawer balance calculations', () {
    test('opening balance sets initial balance', () {
      const openAmount = 500000.0;
      const balanceBefore = 0.0;
      final balanceAfter = balanceBefore + openAmount;
      expect(balanceAfter, 500000.0);
    });

    test('deposit increases balance', () {
      const currentBalance = 500000.0;
      const depositAmount = 200000.0;
      final newBalance = currentBalance + depositAmount;
      expect(newBalance, 700000.0);
    });

    test('withdraw decreases balance', () {
      const currentBalance = 500000.0;
      const withdrawAmount = 100000.0;
      // Withdrawals are stored as negative amounts
      final effectiveAmount = -withdrawAmount;
      final newBalance = currentBalance + effectiveAmount;
      expect(newBalance, 400000.0);
    });

    test('sale increases balance', () {
      const currentBalance = 500000.0;
      const saleAmount = 150000.0;
      final newBalance = currentBalance + saleAmount;
      expect(newBalance, 650000.0);
    });

    test('refund decreases balance', () {
      const currentBalance = 500000.0;
      const refundAmount = 50000.0;
      final effectiveAmount = -refundAmount;
      final newBalance = currentBalance + effectiveAmount;
      expect(newBalance, 450000.0);
    });

    test('close resets balance to zero', () {
      const currentBalance = 750000.0;
      // Close amount = -currentBalance
      final closeAmount = -currentBalance;
      final newBalance = currentBalance + closeAmount;
      expect(newBalance, 0.0);
    });
  });

  group('Cash drawer effective amount logic', () {
    test('withdraw type produces negative amount', () {
      const amount = 100000.0;
      const type = 'withdraw';
      final isWithdraw = type == 'withdraw' || type == 'close';
      final effectiveAmount = isWithdraw ? -amount : amount;
      expect(effectiveAmount, -100000.0);
    });

    test('close type produces negative amount', () {
      const amount = 500000.0;
      const type = 'close';
      final isWithdraw = type == 'withdraw' || type == 'close';
      final effectiveAmount = isWithdraw ? -amount : amount;
      expect(effectiveAmount, -500000.0);
    });

    test('deposit type produces positive amount', () {
      const amount = 200000.0;
      const type = 'deposit';
      final isWithdraw = type == 'withdraw' || type == 'close';
      final effectiveAmount = isWithdraw ? -amount : amount;
      expect(effectiveAmount, 200000.0);
    });

    test('open type produces positive amount', () {
      const amount = 500000.0;
      const type = 'open';
      final isWithdraw = type == 'withdraw' || type == 'close';
      final effectiveAmount = isWithdraw ? -amount : amount;
      expect(effectiveAmount, 500000.0);
    });
  });

  group('Cash drawer close settlement', () {
    test('no difference when counted matches system balance', () {
      const systemBalance = 750000.0;
      const countedAmount = 750000.0;
      final diff = countedAmount - systemBalance;
      expect(diff, 0.0);
    });

    test('positive difference when counted exceeds system balance (over)', () {
      const systemBalance = 750000.0;
      const countedAmount = 760000.0;
      final diff = countedAmount - systemBalance;
      expect(diff, 10000.0);
      expect(diff > 0, true);
    });

    test('negative difference when counted is less (short)', () {
      const systemBalance = 750000.0;
      const countedAmount = 740000.0;
      final diff = countedAmount - systemBalance;
      expect(diff, -10000.0);
      expect(diff < 0, true);
    });

    test('close always resets balance to zero regardless of counted', () {
      const systemBalance = 750000.0;
      // Close log always stores: amount = -currentBalance, balanceAfter = 0
      final closeAmount = -systemBalance;
      final balanceAfter = systemBalance + closeAmount;
      expect(balanceAfter, 0.0);
    });
  });

  group('Cash drawer daily summary calculations', () {
    test('totals by transaction type', () {
      // Simulating log entries
      final logs = [
        _LogEntry('open', 500000),
        _LogEntry('sale', 150000),
        _LogEntry('sale', 80000),
        _LogEntry('deposit', 100000),
        _LogEntry('withdraw', -50000),
        _LogEntry('refund', -30000),
      ];

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

      expect(totalDeposits, 600000); // 500000 (open) + 100000 (deposit)
      expect(totalSales, 230000); // 150000 + 80000
      expect(totalRefunds, 30000);
      expect(totalWithdraws, 50000);
    });

    test('running balance is consistent', () {
      double balance = 0;

      // Open with 500k
      balance += 500000;
      expect(balance, 500000);

      // Sale of 150k
      balance += 150000;
      expect(balance, 650000);

      // Withdraw 50k
      balance += -50000;
      expect(balance, 600000);

      // Refund 30k
      balance += -30000;
      expect(balance, 570000);

      // Deposit 100k
      balance += 100000;
      expect(balance, 670000);

      // Close (takes all money out)
      balance += -670000;
      expect(balance, 0);
    });
  });

  group('Cash drawer edge cases', () {
    test('multiple opens and closes in theory', () {
      double balance = 0;
      balance += 500000; // open
      balance += -500000; // close
      expect(balance, 0);
      balance += 300000; // re-open
      expect(balance, 300000);
    });

    test('zero amount handling', () {
      const currentBalance = 500000.0;
      const amount = 0.0;
      final newBalance = currentBalance + amount;
      expect(newBalance, currentBalance);
    });

    test('large amounts', () {
      const currentBalance = 999999999.0;
      const saleAmount = 1.0;
      final newBalance = currentBalance + saleAmount;
      expect(newBalance, 1000000000.0);
    });
  });
}

class _LogEntry {
  final String type;
  final double amount;
  _LogEntry(this.type, this.amount);
}
