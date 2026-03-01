import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/database/app_database.dart';
import 'package:oda_pos/database/tables/floor_zones.dart';
import 'package:oda_pos/database/tables/floor_elements.dart';
import 'package:oda_pos/features/floor_plan/data/floor_zone_dao.dart';
import 'package:oda_pos/features/floor_plan/data/floor_element_dao.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:matcher/matcher.dart' as matcher;

AppDatabase _openDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  late AppDatabase database;
  late FloorZoneDao zoneDao;
  late FloorElementDao elementDao;

  setUp(() {
    database = _openDb();
    zoneDao = FloorZoneDao(database);
    elementDao = FloorElementDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('FloorZone CRUD Operations', () {
    test('create zone with valid name', () async {
      final zone = FloorZonesCompanion.insert(
        name: 'Main Dining',
        colorHex: const Value('#4CAF50'),
      );
      
      final id = await zoneDao.createZone(zone);
      expect(id, greaterThan(0));

      final zones = await zoneDao.getAllZones();
      expect(zones.length, 1);
      expect(zones.first.name, 'Main Dining');
      expect(zones.first.colorHex, '#4CAF50');
    });

    test('create zone with default color', () async {
      final zone = FloorZonesCompanion.insert(
        name: 'Zone A',
      );
      
      final id = await zoneDao.createZone(zone);
      final zones = await zoneDao.getAllZones();

      expect(zones.first.colorHex, '#E3F2FD'); // default color
    });

    test('create zone with custom position and size', () async {
      final zone = FloorZonesCompanion.insert(
        name: 'VIP Area',
        posX: const Value(100.0),
        posY: const Value(150.0),
        width: const Value(300.0),
        height: const Value(250.0),
      );
      
      final id = await zoneDao.createZone(zone);
      final zones = await zoneDao.getAllZones();

      expect(zones.first.posX, 100.0);
      expect(zones.first.posY, 150.0);
      expect(zones.first.width, 300.0);
      expect(zones.first.height, 250.0);
    });

    test('update zone position and size', () async {
      final zone = FloorZonesCompanion.insert(
        name: 'Movable Zone',
      );
      final id = await zoneDao.createZone(zone);

      final updated = await zoneDao.updateZonePositionAndSize(
        zoneId: id,
        posX: 200.0,
        posY: 300.0,
        width: 400.0,
        height: 350.0,
      );

      expect(updated, isTrue);

      final zones = await zoneDao.getAllZones();
      expect(zones.first.posX, 200.0);
      expect(zones.first.posY, 300.0);
      expect(zones.first.width, 400.0);
      expect(zones.first.height, 350.0);
    });

    test('delete zone', () async {
      final zone = FloorZonesCompanion.insert(
        name: 'Temp Zone',
      );
      final id = await zoneDao.createZone(zone);

      final deleteCount = await zoneDao.deleteZone(id);
      expect(deleteCount, 1);

      final zones = await zoneDao.getAllZones();
      expect(zones.length, 0);
    });

    test('get zone by id', () async {
      final zone = FloorZonesCompanion.insert(
        name: 'VIP Room',
      );
      final id = await zoneDao.createZone(zone);

      final retrieved = await zoneDao.getZoneById(id);
      expect(retrieved, matcher.isNotNull);
      expect(retrieved!.name, 'VIP Room');
    });

    test('get zone by invalid id returns null', () async {
      final retrieved = await zoneDao.getZoneById(9999);
      expect(retrieved, matcher.isNull);
    });

    test('getAllZones returns zones sorted by name', () async {
      await zoneDao.createZone(FloorZonesCompanion.insert(name: 'Zone C'));
      await zoneDao.createZone(FloorZonesCompanion.insert(name: 'Zone A'));
      await zoneDao.createZone(FloorZonesCompanion.insert(name: 'Zone B'));

      final zones = await zoneDao.getAllZones();
      expect(zones.length, 3);
      expect(zones[0].name, 'Zone A');
      expect(zones[1].name, 'Zone B');
      expect(zones[2].name, 'Zone C');
    });
  });

  group('FloorElement CRUD Operations', () {
    test('create element with type and label', () async {
      final element = FloorElementsCompanion.insert(
        elementType: 'entrance',
        label: const Value('Main Entrance'),
      );

      final id = await elementDao.createElement(element);
      expect(id, greaterThan(0));

      final elements = await elementDao.getAllElements();
      expect(elements.length, 1);
      expect(elements.first.elementType, 'entrance');
      expect(elements.first.label, 'Main Entrance');
    });

    test('create element with custom position', () async {
      final element = FloorElementsCompanion.insert(
        elementType: 'counter',
        posX: const Value(100.0),
        posY: const Value(150.0),
      );

      await elementDao.createElement(element);

      final elements = await elementDao.getAllElements();
      expect(elements.first.posX, 100.0);
      expect(elements.first.posY, 150.0);
    });

    test('create element with custom size', () async {
      final element = FloorElementsCompanion.insert(
        elementType: 'restroom',
        width: const Value(80.0),
        height: const Value(120.0),
      );

      await elementDao.createElement(element);

      final elements = await elementDao.getAllElements();
      expect(elements.first.width, 80.0);
      expect(elements.first.height, 120.0);
    });

    test('create element with rotation', () async {
      final element = FloorElementsCompanion.insert(
        elementType: 'window',
        rotation: const Value(90.0),
      );

      await elementDao.createElement(element);

      final elements = await elementDao.getAllElements();
      expect(elements.first.rotation, 90.0);
    });

    test('update element position', () async {
      final element = FloorElementsCompanion.insert(
        elementType: 'bar_counter',
      );
      final id = await elementDao.createElement(element);

      final updated = await elementDao.updateElementPosition(
        elementId: id,
        posX: 200.0,
        posY: 300.0,
      );

      expect(updated, isTrue);

      final elements = await elementDao.getAllElements();
      expect(elements.first.posX, 200.0);
      expect(elements.first.posY, 300.0);
    });

    test('delete element', () async {
      final element = FloorElementsCompanion.insert(
        elementType: 'wall',
      );
      final id = await elementDao.createElement(element);

      final deleteCount = await elementDao.deleteElement(id);
      expect(deleteCount, 1);

      final elements = await elementDao.getAllElements();
      expect(elements.length, 0);
    });

    test('get element by id', () async {
      final element = FloorElementsCompanion.insert(
        elementType: 'entrance',
        label: const Value('Side Door'),
      );
      final id = await elementDao.createElement(element);

      final retrieved = await elementDao.getElementById(id);
      expect(retrieved, matcher.isNotNull);
      expect(retrieved!.elementType, 'entrance');
      expect(retrieved.label, 'Side Door');
    });
  });

  group('FloorElement Types', () {
    test('create entrance element', () async {
      final element = FloorElementsCompanion.insert(
        elementType: 'entrance',
      );

      await elementDao.createElement(element);

      final elements = await elementDao.getAllElements();
      expect(elements.first.elementType, 'entrance');
    });

    test('create counter element', () async {
      final element = FloorElementsCompanion.insert(
        elementType: 'counter',
      );

      await elementDao.createElement(element);

      final elements = await elementDao.getAllElements();
      expect(elements.first.elementType, 'counter');
    });

    test('create restroom element', () async {
      final element = FloorElementsCompanion.insert(
        elementType: 'restroom',
      );

      await elementDao.createElement(element);

      final elements = await elementDao.getAllElements();
      expect(elements.first.elementType, 'restroom');
    });

    test('create window element', () async {
      final element = FloorElementsCompanion.insert(
        elementType: 'window',
      );

      await elementDao.createElement(element);

      final elements = await elementDao.getAllElements();
      expect(elements.first.elementType, 'window');
    });

    test('create wall element', () async {
      final element = FloorElementsCompanion.insert(
        elementType: 'wall',
      );

      await elementDao.createElement(element);

      final elements = await elementDao.getAllElements();
      expect(elements.first.elementType, 'wall');
    });

    test('create bar_counter element', () async {
      final element = FloorElementsCompanion.insert(
        elementType: 'bar_counter',
      );

      await elementDao.createElement(element);

      final elements = await elementDao.getAllElements();
      expect(elements.first.elementType, 'bar_counter');
    });
  });

  group('FloorElement Defaults', () {
    test('element defaults to position (0, 0)', () async {
      final element = FloorElementsCompanion.insert(
        elementType: 'entrance',
      );

      await elementDao.createElement(element);

      final elements = await elementDao.getAllElements();
      expect(elements.first.posX, 0.0);
      expect(elements.first.posY, 0.0);
    });

    test('element defaults to size 60x60', () async {
      final element = FloorElementsCompanion.insert(
        elementType: 'entrance',
      );

      await elementDao.createElement(element);

      final elements = await elementDao.getAllElements();
      expect(elements.first.width, 60.0);
      expect(elements.first.height, 60.0);
    });

    test('element defaults to rotation 0', () async {
      final element = FloorElementsCompanion.insert(
        elementType: 'entrance',
      );

      await elementDao.createElement(element);

      final elements = await elementDao.getAllElements();
      expect(elements.first.rotation, 0.0);
    });
  });
}
