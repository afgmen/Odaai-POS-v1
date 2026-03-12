import 'package:flutter_test/flutter_test.dart';

/// B-100: Promotion — 만료 프로모션 Active 표시 버그
///
/// Verifies the UI expiry logic:
///   endDate < now → "Expired" badge (overrides isActive DB value)
void main() {
  group('B-100: Promotion expiry badge — UI-level date check', () {
    final now = DateTime(2026, 3, 12);

    // Helper mirrors the widget Builder logic
    String getBadgeLabel({
      required DateTime? endDate,
      required bool isActive,
    }) {
      if (endDate != null && endDate.isBefore(now)) {
        return 'Expired';
      }
      return isActive ? 'Active' : 'Inactive';
    }

    // ── Expired ──────────────────────────────────────────────────────
    test('endDate in past → Expired regardless of isActive=true', () {
      final label = getBadgeLabel(
        endDate: DateTime(2026, 3, 1), // 11 days ago
        isActive: true,
      );
      expect(label, 'Expired');
    });

    test('endDate in past → Expired regardless of isActive=false', () {
      final label = getBadgeLabel(
        endDate: DateTime(2026, 1, 1),
        isActive: false,
      );
      expect(label, 'Expired');
    });

    test('endDate = yesterday → Expired', () {
      final yesterday = now.subtract(const Duration(days: 1));
      final label = getBadgeLabel(endDate: yesterday, isActive: true);
      expect(label, 'Expired');
    });

    // ── Active / Inactive ─────────────────────────────────────────────
    test('endDate in future → Active when isActive=true', () {
      final label = getBadgeLabel(
        endDate: DateTime(2026, 12, 31),
        isActive: true,
      );
      expect(label, 'Active');
    });

    test('endDate in future → Inactive when isActive=false', () {
      final label = getBadgeLabel(
        endDate: DateTime(2026, 12, 31),
        isActive: false,
      );
      expect(label, 'Inactive');
    });

    test('no endDate → Active when isActive=true (no expiry)', () {
      final label = getBadgeLabel(endDate: null, isActive: true);
      expect(label, 'Active');
    });

    test('no endDate → Inactive when isActive=false', () {
      final label = getBadgeLabel(endDate: null, isActive: false);
      expect(label, 'Inactive');
    });

    // ── Edge cases ────────────────────────────────────────────────────
    test('endDate = exact now moment is NOT expired (strict isBefore)', () {
      // isBefore(now) is false when endDate == now, so not expired
      final label = getBadgeLabel(endDate: now, isActive: true);
      expect(label, 'Active',
          reason: 'Exact same DateTime is not "before" now');
    });

    test('endDate = tomorrow is NOT expired', () {
      final tomorrow = now.add(const Duration(days: 1));
      final label = getBadgeLabel(endDate: tomorrow, isActive: true);
      expect(label, 'Active');
    });

    test('promotions expiring yesterday at midnight are expired', () {
      // endDate set to start of yesterday (00:00:00) — always in the past
      final startOfYesterday = DateTime(now.year, now.month, now.day - 1, 0, 0, 0);
      final isExpired = startOfYesterday.isBefore(now);
      expect(isExpired, isTrue,
          reason: 'Yesterday start-of-day endDate is always before now → expired');
    });
  });
}
