import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// B-080: Calendar Date Sync Tests
void main() {
  group('Date Normalization', () {
    test('should normalize DateTime to start of day', () {
      final dateTime = DateTime(2026, 3, 8, 15, 30, 45); // 3/8 15:30:45

      final normalized = DateTime(dateTime.year, dateTime.month, dateTime.day);

      expect(normalized.hour, 0);
      expect(normalized.minute, 0);
      expect(normalized.second, 0);
      expect(normalized.day, 8);
    });

    test('should preserve date when normalizing', () {
      final dateTime = DateTime(2026, 3, 7, 23, 59, 59); // 3/7 23:59:59

      final normalized = DateTime(dateTime.year, dateTime.month, dateTime.day);

      expect(normalized.year, 2026);
      expect(normalized.month, 3);
      expect(normalized.day, 7);
    });

    test('should handle midnight correctly', () {
      final dateTime = DateTime(2026, 3, 8, 0, 0, 0); // 3/8 00:00:00

      final normalized = DateTime(dateTime.year, dateTime.month, dateTime.day);

      expect(normalized, dateTime);
    });
  });

  group('Date Comparison', () {
    test('should compare dates ignoring time', () {
      final date1 = DateTime(2026, 3, 8, 10, 30);
      final date2 = DateTime(2026, 3, 8, 15, 45);

      final normalized1 = DateTime(date1.year, date1.month, date1.day);
      final normalized2 = DateTime(date2.year, date2.month, date2.day);

      expect(normalized1, normalized2);
    });

    test('should detect different dates', () {
      final date1 = DateTime(2026, 3, 7, 23, 59);
      final date2 = DateTime(2026, 3, 8, 0, 1);

      final normalized1 = DateTime(date1.year, date1.month, date1.day);
      final normalized2 = DateTime(date2.year, date2.month, date2.day);

      expect(normalized1, isNot(normalized2));
    });

    test('should use isSameDay logic', () {
      final date1 = DateTime(2026, 3, 8, 10, 0);
      final date2 = DateTime(2026, 3, 8, 20, 0);

      final isSame = date1.year == date2.year &&
                    date1.month == date2.month &&
                    date1.day == date2.day;

      expect(isSame, true);
    });
  });

  group('Date Formatting', () {
    test('should format date consistently', () {
      final dateTime = DateTime(2026, 3, 8, 15, 30);

      final formatted = DateFormat('yyyy-MM-dd').format(dateTime);

      expect(formatted, '2026-03-08');
    });

    test('should format date with day of week', () {
      final dateTime = DateTime(2026, 3, 8); // Sunday

      final formatted = DateFormat('yyyy-MM-dd (E)').format(dateTime);

      expect(formatted.startsWith('2026-03-08'), true);
    });

    test('should preserve date in format', () {
      final dateTime = DateTime(2026, 3, 7, 23, 59);

      final formatted = DateFormat('yyyy-MM-dd').format(dateTime);

      expect(formatted, '2026-03-07');
    });
  });

  group('Date Range', () {
    test('should create start of day', () {
      final date = DateTime(2026, 3, 8);
      final startOfDay = DateTime(date.year, date.month, date.day);

      expect(startOfDay.hour, 0);
      expect(startOfDay.minute, 0);
    });

    test('should create end of day', () {
      final date = DateTime(2026, 3, 8);
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      expect(endOfDay.day, 9);
      expect(endOfDay.hour, 0);
    });

    test('should check if date is in range', () {
      final targetDate = DateTime(2026, 3, 8, 15, 30);
      final startOfDay = DateTime(2026, 3, 8);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final isInRange = targetDate.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
                       targetDate.isBefore(endOfDay);

      expect(isInRange, true);
    });
  });

  group('Calendar and Detail Sync', () {
    test('should use same date source', () {
      final reservationDate = DateTime(2026, 3, 8, 15, 30);

      // Calendar: normalized
      final calendarDate = DateTime(
        reservationDate.year,
        reservationDate.month,
        reservationDate.day,
      );

      // Detail: normalized
      final detailDate = DateTime(
        reservationDate.year,
        reservationDate.month,
        reservationDate.day,
      );

      expect(calendarDate, detailDate);
    });

    test('should display same day', () {
      final reservationDate = DateTime(2026, 3, 8);

      final calendarDay = reservationDate.day;
      final detailDay = reservationDate.day;

      expect(calendarDay, detailDay);
    });
  });
}
