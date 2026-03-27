import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../../../core/theme/app_theme.dart';

/// Exception types for better error handling
class CameraPermissionDeniedException implements Exception {
  final String message = 'Camera permission denied. Please enable camera access in Settings.';
  @override
  String toString() => message;
}

class GalleryPermissionDeniedException implements Exception {
  final String message = 'Photo library permission denied. Please enable photo access in Settings.';
  @override
  String toString() => message;
}

class ImageProcessingException implements Exception {
  final String message;
  ImageProcessingException(this.message);
  @override
  String toString() => message;
}

/// Image Service for product image management
/// Handles upload (camera/gallery), crop, resize, and delete
class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// Upload image from camera
  Future<File?> uploadFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (image == null) return null; // User cancelled
      return await _cropImage(File(image.path));
    } on Exception catch (e) {
      // Check for permission-related errors
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission') || 
          errorStr.contains('denied') || 
          errorStr.contains('access')) {
        throw CameraPermissionDeniedException();
      }
      throw ImageProcessingException('Camera upload failed. Please try again.');
    } catch (e) {
      throw ImageProcessingException('Camera upload failed: ${e.toString()}');
    }
  }

  /// Upload image from gallery
  Future<File?> uploadFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (image == null) return null; // User cancelled
      return await _cropImage(File(image.path));
    } on Exception catch (e) {
      // Check for permission-related errors
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission') || 
          errorStr.contains('denied') || 
          errorStr.contains('access')) {
        throw GalleryPermissionDeniedException();
      }
      throw ImageProcessingException('Gallery upload failed. Please try again.');
    } catch (e) {
      throw ImageProcessingException('Gallery upload failed: ${e.toString()}');
    }
  }

  /// Crop image to square (1:1 aspect ratio)
  Future<File?> _cropImage(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: AppTheme.primary,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      // If crop was cancelled (null result), use original image
      return croppedFile != null ? File(croppedFile.path) : imageFile;
    } catch (e) {
      // Cropper error - return original image
      return imageFile;
    }
  }

  /// Resize image to max 800x800 and save to product_images directory
  Future<File> resizeAndSaveImage(File imageFile, String sku) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw ImageProcessingException('Failed to decode image. The file may be corrupted.');
      }

      // Resize if larger than 800x800
      img.Image resized = image;
      if (image.width > 800 || image.height > 800) {
        resized = img.copyResize(
          image,
          width: image.width > image.height ? 800 : null,
          height: image.height > image.width ? 800 : null,
        );
      }

      // Create product_images directory if not exists
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/product_images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Save as JPEG with 85% quality
      final savePath = '${imagesDir.path}/$sku.jpg';
      final savedFile = File(savePath);
      await savedFile.writeAsBytes(img.encodeJpg(resized, quality: 85));

      return savedFile;
    } catch (e) {
      if (e is ImageProcessingException) rethrow;
      throw ImageProcessingException('Image processing failed: ${e.toString()}');
    }
  }

  /// Delete product image
  Future<void> deleteImage(String sku) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/product_images/$sku.jpg';
      final file = File(imagePath);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw ImageProcessingException('Image delete failed: ${e.toString()}');
    }
  }

  /// Get local image file if exists
  Future<File?> getImageFile(String sku) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/product_images/$sku.jpg';
      final file = File(imagePath);

      return await file.exists() ? file : null;
    } catch (e) {
      return null;
    }
  }

  /// Get image path for display
  Future<String?> getImagePath(String sku) async {
    final file = await getImageFile(sku);
    return file?.path;
  }

  /// Convert Uint8List to File (for downloaded images)
  Future<File> bytesToFile(Uint8List bytes, String sku) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final tempPath = '${directory.path}/temp_$sku.jpg';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes);
      return tempFile;
    } catch (e) {
      throw ImageProcessingException('Bytes to file conversion failed: ${e.toString()}');
    }
  }
}
