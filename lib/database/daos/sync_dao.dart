import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/sync_queue.dart';

part 'sync_dao.g.dart';

@DriftAccessor(tables: [SyncQueue])
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(super.database);

  Future<void> enqueue({
    required String entityType,
    required int entityId,
    required String action,
    required String payload,
  }) async {
    await into(syncQueue).insert(
      SyncQueueCompanion.insert(
        entityType: entityType,
        entityId: entityId,
        action: action,
        payload: payload,
      ),
    );
  }

  Future<List<SyncQueueData>> getPendingItems() {
    return (select(syncQueue)
          ..where((q) => q.status.equals('pending'))
          ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
        .get();
  }

  Future<int> markSynced(int id) {
    return (update(syncQueue)..where((q) => q.id.equals(id)))
        .write(SyncQueueCompanion(
      status: const Value('synced'),
      syncedAt: Value(DateTime.now()),
    ));
  }

  Future<int> markFailed(int id) async {
    final item = await (select(syncQueue)..where((q) => q.id.equals(id)))
        .getSingle();

    return (update(syncQueue)..where((q) => q.id.equals(id)))
        .write(SyncQueueCompanion(
      status: const Value('failed'),
      retryCount: Value(item.retryCount + 1),
    ));
  }

  Future<int> clearSynced() {
    return (delete(syncQueue)..where((q) => q.status.equals('synced'))).go();
  }
}
