import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/database/app_database.dart';
import 'package:oda_pos/features/floor_plan/data/floor_element_dao.dart';

/// B-064: Drag & Drop Integration Tests
void main() {
  late AppDatabase db;
  late FloorElementDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.floorElementDao;
  });

  tearDown() async {
    await db.close();
  }

  group('Element Position Update', () {
    test('should update element position successfully', () async {
      // Create element
      final elementId = await dao.createElement(
        FloorElementsCompanion.insert(
          elementType: 'entrance',
          posX: const Value(100.0),
          posY: const Value(100.0),
          width: const Value(80.0),
          height: const Value(60.0),
        ),
      );

      // Update position (drag)
      final success = await dao.updateElementPosition(
        elementId: elementId,
        posX: 200.0,
        posY: 150.0,
      );

      expect(success, true);

      // Verify updated position
      final element = await dao.getElementById(elementId);
      expect(element!.posX, 200.0);
      expect(element.posY, 150.0);
    });

    test('should preserve other properties when updating position', () async {
      final elementId = await dao.createElement(
        FloorElementsCompanion.insert(
          elementType: 'counter',
          posX: const Value(50.0),
          posY: const Value(50.0),
          width: const Value(120.0),
          height: const Value(80.0),
          rotation: const Value(45.0),
          label: const Value('Main Counter'),
        ),
      );

      // Update only position
      await dao.updateElementPosition(
        elementId: elementId,
        posX: 300.0,
        posY: 250.0,
      );

      final element = await dao.getElementById(elementId);
      expect(element!.elementType, 'counter');
      expect(element.width, 120.0);
      expect(element.height, 80.0);
      expect(element.rotation, 45.0);
      expect(element.label, 'Main Counter');
    });

    test('should return false for non-existent element', () async {
      final success = await dao.updateElementPosition(
        elementId: 99999,
        posX: 100.0,
        posY: 100.0,
      );

      expect(success, false);
    });
  });

  group('Boundary Constraints', () {
    double clampPosition(double pos, double min, double max) {
      return pos.clamp(min, max);
    }

    test('should clamp to minimum boundary', () {
      expect(clampPosition(-50, 0, 2000), 0);
    });

    test('should clamp to maximum boundary', () {
      expect(clampPosition(2500, 0, 2000), 2000);
    });

    test('should keep valid position unchanged', () {
      expect(clampPosition(500, 0, 2000), 500);
    });

    test('should account for element dimensions', () {
      const posX = 1950.0;
      const width = 100.0;
      const maxX = 2000.0 - width;

      expect(clampPosition(posX, 0, maxX), 1900.0);
    });
  });

  group('Delta Calculation', () {
    double applyDelta(double current, double delta, double min, double max) {
      return (current + delta).clamp(min, max);
    }

    test('should add positive delta', () {
      expect(applyDelta(100, 50, 0, 2000), 150);
    });

    test('should subtract negative delta', () {
      expect(applyDelta(100, -30, 0, 2000), 70);
    });

    test('should clamp result at boundaries', () {
      expect(applyDelta(1980, 100, 0, 2000), 2000);
      expect(applyDelta(20, -100, 0, 2000), 0);
    });
  });

  group('Collision Detection', () {
    bool overlaps(
      double x1, double y1, double w1, double h1,
      double x2, double y2, double w2, double h2,
    ) {
      return !(x1 + w1 <= x2 || x2 + w2 <= x1 || y1 + h1 <= y2 || y2 + h2 <= y1);
    }

    test('should detect overlapping elements', () {
      expect(overlaps(0, 0, 100, 100, 50, 50, 100, 100), true);
    });

    test('should detect non-overlapping elements', () {
      expect(overlaps(0, 0, 100, 100, 200, 200, 100, 100), false);
    });

    test('should not overlap when touching edges', () {
      expect(overlaps(0, 0, 100, 100, 100, 0, 100, 100), false);
    });
  });
}
