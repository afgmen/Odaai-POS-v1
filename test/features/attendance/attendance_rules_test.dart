import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/features/attendance/domain/services/attendance_service.dart';

/// Test the pure computation parts of attendance business rules.
/// Since AttendanceService requires a real DAO (DatabaseAccessor),
/// we test the result classes and replicate the pure logic formulas
/// that the service uses internally.

// ─── Pure logic replicated from AttendanceService ───────────
// These mirror the exact formulas used in the service.

bool isLate(DateTime checkIn, DateTime scheduledStart) {
  final lateThreshold = scheduledStart.add(const Duration(minutes: 15));
  return checkIn.isAfter(lateThreshold);
}

bool isEarlyLeave(DateTime checkOut, DateTime scheduledEnd) {
  final earlyLeaveThreshold = scheduledEnd.subtract(const Duration(minutes: 30));
  return checkOut.isBefore(earlyLeaveThreshold);
}

/// Calculate night minutes (22:00-06:00)
int calculateNightMinutes(DateTime start, DateTime end) {
  int nightMinutes = 0;
  DateTime current = start;

  while (current.isBefore(end)) {
    final nextHour = DateTime(
      current.year, current.month, current.day, current.hour + 1,
    );
    final segmentEnd = nextHour.isAfter(end) ? end : nextHour;

    if (current.hour >= 22 || current.hour < 6) {
      nightMinutes += segmentEnd.difference(current).inMinutes;
    }

    current = segmentEnd;
  }

  return nightMinutes;
}

/// Calculate work time breakdown
({int totalMinutes, int regularMinutes, int overtimeMinutes, int nightMinutes})
    calculateWorkTime({
  required DateTime checkIn,
  required DateTime checkOut,
  required DateTime scheduledStart,
  required DateTime scheduledEnd,
}) {
  final totalMinutes = checkOut.difference(checkIn).inMinutes;
  final scheduledMinutes = scheduledEnd.difference(scheduledStart).inMinutes;
  final regularMinutes = totalMinutes > scheduledMinutes ? scheduledMinutes : totalMinutes;
  final overtimeMinutes = totalMinutes > scheduledMinutes ? totalMinutes - scheduledMinutes : 0;
  final nightMinutes = calculateNightMinutes(checkIn, checkOut);

  return (
    totalMinutes: totalMinutes,
    regularMinutes: regularMinutes,
    overtimeMinutes: overtimeMinutes,
    nightMinutes: nightMinutes,
  );
}

/// Count weekdays in month (matches _countWeekdaysInMonth)
int countWeekdaysInMonth(int year, int month) {
  final lastDay = DateTime(year, month + 1, 0);
  int count = 0;
  for (int day = 1; day <= lastDay.day; day++) {
    final date = DateTime(year, month, day);
    if (date.weekday != DateTime.saturday && date.weekday != DateTime.sunday) {
      count++;
    }
  }
  return count;
}

/// Calculate leave days excluding weekends (matches _calculateLeaveDays)
double calculateLeaveDays(DateTime start, DateTime end) {
  int days = 0;
  DateTime current = start;
  while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
    if (current.weekday != DateTime.saturday && current.weekday != DateTime.sunday) {
      days++;
    }
    current = current.add(const Duration(days: 1));
  }
  return days.toDouble();
}

// ─── Tests ──────────────────────────────────────────────────

void main() {
  group('isLate detection', () {
    test('not late when checking in exactly on time', () {
      final scheduled = DateTime(2024, 1, 15, 9, 0);
      final checkIn = DateTime(2024, 1, 15, 9, 0);
      expect(isLate(checkIn, scheduled), false);
    });

    test('not late when checking in 14 minutes after', () {
      final scheduled = DateTime(2024, 1, 15, 9, 0);
      final checkIn = DateTime(2024, 1, 15, 9, 14);
      expect(isLate(checkIn, scheduled), false);
    });

    test('not late at exactly 15 minute boundary', () {
      final scheduled = DateTime(2024, 1, 15, 9, 0);
      final checkIn = DateTime(2024, 1, 15, 9, 15);
      expect(isLate(checkIn, scheduled), false);
    });

    test('late when checking in 16 minutes after', () {
      final scheduled = DateTime(2024, 1, 15, 9, 0);
      final checkIn = DateTime(2024, 1, 15, 9, 16);
      expect(isLate(checkIn, scheduled), true);
    });

    test('late when checking in 1 hour after', () {
      final scheduled = DateTime(2024, 1, 15, 9, 0);
      final checkIn = DateTime(2024, 1, 15, 10, 0);
      expect(isLate(checkIn, scheduled), true);
    });

    test('not late when checking in early', () {
      final scheduled = DateTime(2024, 1, 15, 9, 0);
      final checkIn = DateTime(2024, 1, 15, 8, 30);
      expect(isLate(checkIn, scheduled), false);
    });
  });

  group('isEarlyLeave detection', () {
    test('not early leave when checking out exactly at end', () {
      final scheduledEnd = DateTime(2024, 1, 15, 18, 0);
      final checkOut = DateTime(2024, 1, 15, 18, 0);
      expect(isEarlyLeave(checkOut, scheduledEnd), false);
    });

    test('not early leave when checking out after end', () {
      final scheduledEnd = DateTime(2024, 1, 15, 18, 0);
      final checkOut = DateTime(2024, 1, 15, 18, 30);
      expect(isEarlyLeave(checkOut, scheduledEnd), false);
    });

    test('not early leave when leaving 29 minutes before end', () {
      final scheduledEnd = DateTime(2024, 1, 15, 18, 0);
      final checkOut = DateTime(2024, 1, 15, 17, 31);
      expect(isEarlyLeave(checkOut, scheduledEnd), false);
    });

    test('not early leave at exactly 30 min boundary', () {
      final scheduledEnd = DateTime(2024, 1, 15, 18, 0);
      final checkOut = DateTime(2024, 1, 15, 17, 30);
      expect(isEarlyLeave(checkOut, scheduledEnd), false);
    });

    test('early leave when leaving 31 minutes before end', () {
      final scheduledEnd = DateTime(2024, 1, 15, 18, 0);
      final checkOut = DateTime(2024, 1, 15, 17, 29);
      expect(isEarlyLeave(checkOut, scheduledEnd), true);
    });

    test('early leave when leaving 2 hours early', () {
      final scheduledEnd = DateTime(2024, 1, 15, 18, 0);
      final checkOut = DateTime(2024, 1, 15, 16, 0);
      expect(isEarlyLeave(checkOut, scheduledEnd), true);
    });
  });

  group('calculateWorkTime - total minutes', () {
    test('8 hour shift = 480 minutes', () {
      final result = calculateWorkTime(
        checkIn: DateTime(2024, 1, 15, 9, 0),
        checkOut: DateTime(2024, 1, 15, 17, 0),
        scheduledStart: DateTime(2024, 1, 15, 9, 0),
        scheduledEnd: DateTime(2024, 1, 15, 17, 0),
      );
      expect(result.totalMinutes, 480);
    });

    test('half day = 240 minutes', () {
      final result = calculateWorkTime(
        checkIn: DateTime(2024, 1, 15, 9, 0),
        checkOut: DateTime(2024, 1, 15, 13, 0),
        scheduledStart: DateTime(2024, 1, 15, 9, 0),
        scheduledEnd: DateTime(2024, 1, 15, 17, 0),
      );
      expect(result.totalMinutes, 240);
    });
  });

  group('calculateWorkTime - regular vs overtime', () {
    test('no overtime when working exactly scheduled time', () {
      final result = calculateWorkTime(
        checkIn: DateTime(2024, 1, 15, 9, 0),
        checkOut: DateTime(2024, 1, 15, 17, 0),
        scheduledStart: DateTime(2024, 1, 15, 9, 0),
        scheduledEnd: DateTime(2024, 1, 15, 17, 0),
      );
      expect(result.regularMinutes, 480);
      expect(result.overtimeMinutes, 0);
    });

    test('overtime when working beyond scheduled end', () {
      final result = calculateWorkTime(
        checkIn: DateTime(2024, 1, 15, 9, 0),
        checkOut: DateTime(2024, 1, 15, 19, 0),
        scheduledStart: DateTime(2024, 1, 15, 9, 0),
        scheduledEnd: DateTime(2024, 1, 15, 17, 0),
      );
      expect(result.totalMinutes, 600);
      expect(result.regularMinutes, 480);
      expect(result.overtimeMinutes, 120);
    });

    test('regular capped at actual when leaving early', () {
      final result = calculateWorkTime(
        checkIn: DateTime(2024, 1, 15, 9, 0),
        checkOut: DateTime(2024, 1, 15, 13, 0),
        scheduledStart: DateTime(2024, 1, 15, 9, 0),
        scheduledEnd: DateTime(2024, 1, 15, 17, 0),
      );
      expect(result.regularMinutes, 240);
      expect(result.overtimeMinutes, 0);
    });

    test('1 hour overtime', () {
      final result = calculateWorkTime(
        checkIn: DateTime(2024, 1, 15, 9, 0),
        checkOut: DateTime(2024, 1, 15, 18, 0),
        scheduledStart: DateTime(2024, 1, 15, 9, 0),
        scheduledEnd: DateTime(2024, 1, 15, 17, 0),
      );
      expect(result.overtimeMinutes, 60);
    });

    test('totalMinutes = regularMinutes + overtimeMinutes', () {
      final result = calculateWorkTime(
        checkIn: DateTime(2024, 1, 15, 9, 0),
        checkOut: DateTime(2024, 1, 15, 19, 30),
        scheduledStart: DateTime(2024, 1, 15, 9, 0),
        scheduledEnd: DateTime(2024, 1, 15, 17, 0),
      );
      expect(result.totalMinutes, result.regularMinutes + result.overtimeMinutes);
    });
  });

  group('calculateWorkTime - night minutes', () {
    test('no night minutes for daytime shift', () {
      final result = calculateWorkTime(
        checkIn: DateTime(2024, 1, 15, 9, 0),
        checkOut: DateTime(2024, 1, 15, 17, 0),
        scheduledStart: DateTime(2024, 1, 15, 9, 0),
        scheduledEnd: DateTime(2024, 1, 15, 17, 0),
      );
      expect(result.nightMinutes, 0);
    });

    test('night minutes for evening shift ending at midnight', () {
      final result = calculateWorkTime(
        checkIn: DateTime(2024, 1, 15, 20, 0),
        checkOut: DateTime(2024, 1, 16, 0, 0),
        scheduledStart: DateTime(2024, 1, 15, 20, 0),
        scheduledEnd: DateTime(2024, 1, 16, 0, 0),
      );
      // 22:00-00:00 = 120 night minutes
      expect(result.nightMinutes, 120);
    });

    test('night minutes for early morning shift', () {
      final result = calculateWorkTime(
        checkIn: DateTime(2024, 1, 15, 4, 0),
        checkOut: DateTime(2024, 1, 15, 8, 0),
        scheduledStart: DateTime(2024, 1, 15, 4, 0),
        scheduledEnd: DateTime(2024, 1, 15, 8, 0),
      );
      // 04:00-06:00 = 120 night minutes
      expect(result.nightMinutes, 120);
    });

    test('full night shift has all night minutes', () {
      final result = calculateWorkTime(
        checkIn: DateTime(2024, 1, 15, 22, 0),
        checkOut: DateTime(2024, 1, 16, 6, 0),
        scheduledStart: DateTime(2024, 1, 15, 22, 0),
        scheduledEnd: DateTime(2024, 1, 16, 6, 0),
      );
      expect(result.nightMinutes, 480);
      expect(result.totalMinutes, 480);
    });

    test('partial night shift: 21:00-01:00', () {
      final result = calculateWorkTime(
        checkIn: DateTime(2024, 1, 15, 21, 0),
        checkOut: DateTime(2024, 1, 16, 1, 0),
        scheduledStart: DateTime(2024, 1, 15, 21, 0),
        scheduledEnd: DateTime(2024, 1, 16, 1, 0),
      );
      // 21:00-22:00 = 0 night, 22:00-01:00 = 180 night
      expect(result.nightMinutes, 180);
      expect(result.totalMinutes, 240);
    });

    test('night minutes never exceed total minutes', () {
      final result = calculateWorkTime(
        checkIn: DateTime(2024, 1, 15, 22, 0),
        checkOut: DateTime(2024, 1, 16, 6, 0),
        scheduledStart: DateTime(2024, 1, 15, 22, 0),
        scheduledEnd: DateTime(2024, 1, 16, 6, 0),
      );
      expect(result.nightMinutes, lessThanOrEqualTo(result.totalMinutes));
    });
  });

  group('countWeekdaysInMonth', () {
    test('January 2024 has 23 weekdays', () {
      // Jan 2024: Mon Jan 1 → Wed Jan 31
      expect(countWeekdaysInMonth(2024, 1), 23);
    });

    test('February 2024 has 21 weekdays (leap year)', () {
      expect(countWeekdaysInMonth(2024, 2), 21);
    });

    test('February 2023 has 20 weekdays (non-leap year)', () {
      expect(countWeekdaysInMonth(2023, 2), 20);
    });
  });

  group('calculateLeaveDays', () {
    test('single weekday = 1 day', () {
      // Wednesday
      expect(calculateLeaveDays(
        DateTime(2024, 1, 15),
        DateTime(2024, 1, 15),
      ), 1.0);
    });

    test('Mon-Fri = 5 days', () {
      expect(calculateLeaveDays(
        DateTime(2024, 1, 15), // Monday
        DateTime(2024, 1, 19), // Friday
      ), 5.0);
    });

    test('Mon-Sun (full week) = 5 weekdays', () {
      expect(calculateLeaveDays(
        DateTime(2024, 1, 15), // Monday
        DateTime(2024, 1, 21), // Sunday
      ), 5.0);
    });

    test('Saturday only = 0 days', () {
      expect(calculateLeaveDays(
        DateTime(2024, 1, 20), // Saturday
        DateTime(2024, 1, 20),
      ), 0.0);
    });

    test('two weeks = 10 weekdays', () {
      expect(calculateLeaveDays(
        DateTime(2024, 1, 15), // Monday
        DateTime(2024, 1, 26), // Friday (next week)
      ), 10.0);
    });
  });

  group('MonthlyAttendanceReport formatting', () {
    test('formattedTotalWorkTime for 0 minutes', () {
      final report = _createReport(totalWorkMinutes: 0, overtimeMinutes: 0);
      expect(report.formattedTotalWorkTime, '0h 0m');
    });

    test('formattedTotalWorkTime for 510 minutes (8h30m)', () {
      final report = _createReport(totalWorkMinutes: 510, overtimeMinutes: 0);
      expect(report.formattedTotalWorkTime, '8h 30m');
    });

    test('formattedOvertimeWorkTime for 90 minutes (1h30m)', () {
      final report = _createReport(totalWorkMinutes: 0, overtimeMinutes: 90);
      expect(report.formattedOvertimeWorkTime, '1h 30m');
    });

    test('formattedTotalWorkTime for exact hours', () {
      final report = _createReport(totalWorkMinutes: 480, overtimeMinutes: 0);
      expect(report.formattedTotalWorkTime, '8h 0m');
    });
  });

  group('CheckInResult', () {
    test('default isLate is false', () {
      final result = CheckInResult(success: true);
      expect(result.isLate, false);
    });

    test('stores all fields correctly', () {
      final now = DateTime(2024, 1, 15, 9, 16);
      final result = CheckInResult(
        success: true,
        logId: 42,
        isLate: true,
        message: 'Checked in late.',
        checkInTime: now,
      );
      expect(result.success, true);
      expect(result.logId, 42);
      expect(result.isLate, true);
      expect(result.message, 'Checked in late.');
      expect(result.checkInTime, now);
    });
  });

  group('CheckOutResult', () {
    test('default isEarlyLeave is false', () {
      final result = CheckOutResult(success: true);
      expect(result.isEarlyLeave, false);
    });

    test('stores all fields correctly', () {
      final now = DateTime(2024, 1, 15, 17, 0);
      final result = CheckOutResult(
        success: true,
        isEarlyLeave: false,
        totalMinutes: 480,
        overtimeMinutes: 0,
        message: 'Checked out successfully.',
        checkOutTime: now,
      );
      expect(result.totalMinutes, 480);
      expect(result.overtimeMinutes, 0);
    });
  });

  group('WorkTimeBreakdown', () {
    test('constructor stores all fields', () {
      final breakdown = WorkTimeBreakdown(
        totalMinutes: 600,
        regularMinutes: 480,
        overtimeMinutes: 120,
        nightMinutes: 0,
      );
      expect(breakdown.totalMinutes, 600);
      expect(breakdown.regularMinutes, 480);
      expect(breakdown.overtimeMinutes, 120);
      expect(breakdown.nightMinutes, 0);
    });
  });

  group('LeaveRequestResult', () {
    test('successful result', () {
      final result = LeaveRequestResult(success: true, requestId: 1);
      expect(result.success, true);
      expect(result.requestId, 1);
      expect(result.errorMessage, isNull);
    });

    test('failed result with error message', () {
      final result = LeaveRequestResult(
        success: false,
        errorMessage: 'Insufficient balance',
      );
      expect(result.success, false);
      expect(result.errorMessage, 'Insufficient balance');
    });
  });
}

MonthlyAttendanceReport _createReport({
  required int totalWorkMinutes,
  required int overtimeMinutes,
}) {
  return MonthlyAttendanceReport(
    employeeId: 1,
    year: 2024,
    month: 1,
    totalWorkDays: 22,
    actualWorkDays: 20,
    absentDays: 2,
    lateDays: 3,
    earlyLeaveDays: 1,
    totalWorkMinutes: totalWorkMinutes,
    overtimeMinutes: overtimeMinutes,
    nightMinutes: 0,
    statusCounts: {'completed': 20, 'absent': 2},
  );
}
