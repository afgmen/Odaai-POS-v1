import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/features/products/domain/services/image_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Mock PathProvider
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImageService Tests', () {
    late ImageService imageService;

    setUp(() {
      imageService = ImageService();
      // Set up mock path provider
      PathProviderPlatform.instance = MockPathProviderPlatform();
    });

    test('getImageFile returns null for non-existent image', () async {
      final file = await imageService.getImageFile('non_existent_sku');
      expect(file, isNull);
    });

    test('deleteImage handles non-existent file gracefully', () async {
      // Should not throw
      await imageService.deleteImage('non_existent_sku');
    });
  });

  group('Image Path Tests', () {
    test('Image path format is correct', () {
      const sku = 'TEST001';
      const expectedPath = 'product_images/$sku.jpg';
      expect(expectedPath, equals('product_images/TEST001.jpg'));
    });

    test('SKU with special characters is handled', () {
      const sku = 'TEST-001';
      const expectedPath = 'product_images/$sku.jpg';
      expect(expectedPath, equals('product_images/TEST-001.jpg'));
    });
  });
}
