import 'package:drift/drift.dart';

/// Key-value settings stored in SQLite.
///
/// NOTE: Several features assume this table exists (e.g. RBAC enablement flag).
class SystemSettings extends Table {
  TextColumn get key => text()();

  /// Arbitrary string value (use JSON if you need structured data).
  TextColumn get value => text()();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}
