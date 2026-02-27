import 'package:drift/drift.dart';

/// Floor Elements — 플로어 플랜의 고정 요소 (입구, 카운터, 화장실 등)
/// elementType: entrance | counter | restroom | window | wall | bar_counter
class FloorElements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get elementType => text()(); // entrance, counter, restroom, window, wall, bar_counter
  TextColumn get label => text().nullable()();
  RealColumn get posX => real().withDefault(const Constant(0))();
  RealColumn get posY => real().withDefault(const Constant(0))();
  RealColumn get width => real().withDefault(const Constant(60))();
  RealColumn get height => real().withDefault(const Constant(60))();
  RealColumn get rotation => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
