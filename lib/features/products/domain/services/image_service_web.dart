import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Web implementation of ImageService.
/// Uses image_picker (web-supported) and stores images as base64 data URLs.
class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> uploadFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image == null) return null;
    final bytes = await image.readAsBytes();
    return _bytesToDataUrl(bytes);
  }

  Future<String?> uploadFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image == null) return null;
    final bytes = await image.readAsBytes();
    return _bytesToDataUrl(bytes);
  }

  /// Web: no-op resize (already resized via pickImage), returns the data URL
  Future<String> resizeAndSaveImage(String dataUrl, String sku) async {
    return dataUrl;
  }

  Future<String> bytesToFile(Uint8List bytes, String sku) async {
    return _bytesToDataUrl(bytes);
  }

  Future<void> deleteImage(String sku) async {
    // No-op on web (stored in DB as data URL, deleted via DAO)
  }

  String _bytesToDataUrl(Uint8List bytes) {
    final base64 = base64Encode(bytes);
    return 'data:image/jpeg;base64,$base64';
  }
}
