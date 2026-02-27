import 'package:drift/drift.dart';

/// Floor Plan Config — 플로어 플랜 캔버스 설정
/// 단일 레코드 (항상 id=1)
class FloorPlanConfig extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get canvasWidth => real().withDefault(const Constant(1000))();
  RealColumn get canvasHeight => real().withDefault(const Constant(700))();
  TextColumn get backgroundColorHex => text().withDefault(const Constant('#F5F5F5'))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
