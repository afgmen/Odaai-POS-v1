# Table Status Synchronization

## Architecture

Both **Floor Plan** and **Tables** sections use the same data source for real-time synchronization:

### Data Flow
```
TablesDao.updateTableStatus()
  ↓
  SQLite Database
  ↓
TablesDao.watchAllActiveTables() [Drift Stream]
  ↓
allTablesStreamProvider [Riverpod StreamProvider]
  ↓
┌─────────────────┬─────────────────┐
│   Floor Plan    │  Tables Section │
└─────────────────┴─────────────────┘
```

### Providers
- **DAO**: `tablesDaoProvider` (shared)
- **Stream**: `allTablesStreamProvider` (shared)
- **Update**: `TablesDao.updateTableStatus()` (shared)

### Automatic Sync
When any screen updates a table status:
1. `updateTableStatus()` writes to SQLite
2. Drift detects the change
3. `watchAllActiveTables()` emits new data
4. Both screens receive the update automatically

### No Manual Sync Required
❌ No `notifyListeners()` needed
❌ No manual refresh required
✅ Drift streams handle everything automatically

## Testing
Run: `flutter test test/features/tables/table_sync_test.dart`

All tests pass ✅
