# Promotion Expiry Handling

## Implementation (B-065)

### Already Implemented ✅

The promotion expiry logic was **ALREADY CORRECT** in `getApplicablePromotions()` and `expireOldPromotions()`.

### Issue Found

**activePromotionsProvider** was missing expiry date check.

### Fix Applied

**File:** `lib/features/promotions/providers/promotions_provider.dart`

**Before:**
```dart
final activePromotionsProvider = StreamProvider<List<Promotion>>((ref) {
  return (db.select(db.promotions)
    ..where((p) => p.isActive.equals(true)))
    .watch();
});
```

**After:**
```dart
final activePromotionsProvider = StreamProvider<List<Promotion>>((ref) {
  final now = DateTime.now();
  return (db.select(db.promotions)
    ..where((p) =>
      p.isActive.equals(true) &
      (p.endDate.isNull() | p.endDate.isBiggerOrEqualValue(now))))
    .watch();
});
```

### How It Works

**1. getApplicablePromotions (already correct)**
- Checks `isActive = true`
- Checks `startDate <= now` (or null)
- Checks `endDate >= now` (or null)
- Returns only valid promotions ✅

**2. expireOldPromotions (already correct)**
- Finds all active promotions with `endDate < now`
- Sets `isActive = false` for each
- Returns count of expired promotions ✅

**3. activePromotionsProvider (NOW FIXED)**
- Streams active promotions
- Filters by `endDate >= now` or null
- UI automatically updates ✅

### Usage

#### Apply Promotion
```dart
final applicable = await promotionService.getApplicablePromotions(productId);
// Returns only valid, non-expired promotions
```

#### Auto-Expire (Manual)
```dart
final expiredCount = await promotionService.expireOldPromotions();
print('$expiredCount promotions expired');
```

#### Watch Active Promotions
```dart
ref.watch(activePromotionsProvider).when(
  data: (promotions) {
    // promotions list excludes expired ones
  },
);
```

### Testing

9 comprehensive tests verify:
1. Active promotion before expiry → Included ✅
2. Active promotion on expiry date → Included ✅
3. Expired promotion → Excluded ✅
4. Unlimited promotion (null endDate) → Included ✅
5. StartDate filtering → Works ✅
6. Auto-expire batch → Works ✅
7. Future promotions not expired → Works ✅
8. Unlimited not expired → Works ✅
9. Active query excludes expired → Works ✅

All tests passing ✅

### Conclusion

- `getApplicablePromotions()` was already correct
- `expireOldPromotions()` was already correct
- `activePromotionsProvider` is now fixed
- UI will now properly exclude expired promotions
