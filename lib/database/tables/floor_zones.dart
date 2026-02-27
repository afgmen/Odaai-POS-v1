import 'package:drift/drift.dart';

/// Floor Zones — 플로어 플랜의 구역 (주방, 테라스, VIP 등)
/// 반투명 색상 사각형으로 렌더링됨
class FloorZones extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get colorHex => text().withDefault(const Constant('#E3F2FD'))();
  RealColumn get posX => real().withDefault(const Constant(0))();
  RealColumn get posY => real().withDefault(const Constant(0))();
  RealColumn get width => real().withDefault(const Constant(200))();
  RealColumn get height => real().withDefault(const Constant(150))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
