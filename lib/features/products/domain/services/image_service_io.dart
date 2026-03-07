import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
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
      debugPrint('[ImageService] Starting camera upload...');
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (image == null) {
        debugPrint('[ImageService] Camera cancelled by user');
        return null; // User cancelled
      }

      debugPrint('[ImageService] Image captured: ${image.path}');

      // Verify image file exists
      final imageFile = File(image.path);
      if (!await imageFile.exists()) {
        throw ImageProcessingException('Captured image file not found. Please try again.');
      }

      // Verify image file size
      final fileSize = await imageFile.length();
      debugPrint('[ImageService] Image size: ${fileSize} bytes');
      
      if (fileSize == 0) {
        throw ImageProcessingException('Captured image is empty. Please try again.');
      }

      // Crop image
      final croppedFile = await _cropImage(imageFile);
      
      if (croppedFile == null) {
        debugPrint('[ImageService] Cropping cancelled');
        return null;
      }

      debugPrint('[ImageService] Camera upload completed successfully');
      return croppedFile;

    } on CameraPermissionDeniedException {
      rethrow;
    } on ImageProcessingException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('[ImageService] Camera exception: $e');
      // Check for permission-related errors
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission') || 
          errorStr.contains('denied') || 
          errorStr.contains('access') ||
          errorStr.contains('camera')) {
        throw CameraPermissionDeniedException();
      }
      throw ImageProcessingException('Camera upload failed. Please try again.');
    } catch (e) {
      debugPrint('[ImageService] Camera error: $e');
      throw ImageProcessingException('Camera upload failed: ${e.toString()}');
    }
  }

  /// Upload image from gallery
  Future<File?> uploadFromGallery() async {
    try {
      debugPrint('[ImageService] Starting gallery upload...');
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (image == null) {
        debugPrint('[ImageService] Gallery cancelled by user');
        return null; // User cancelled
      }

      debugPrint('[ImageService] Image selected: ${image.path}');

      // Verify image file exists
      final imageFile = File(image.path);
      if (!await imageFile.exists()) {
        throw ImageProcessingException('Selected image file not found. Please try again.');
      }

      // Verify image file size
      final fileSize = await imageFile.length();
      debugPrint('[ImageService] Image size: ${fileSize} bytes');
      
      if (fileSize == 0) {
        throw ImageProcessingException('Selected image is empty. Please choose another.');
      }

      // Crop image
      final croppedFile = await _cropImage(imageFile);
      
      if (croppedFile == null) {
        debugPrint('[ImageService] Cropping cancelled');
        return null;
      }

      debugPrint('[ImageService] Gallery upload completed successfully');
      return croppedFile;

    } on GalleryPermissionDeniedException {
      rethrow;
    } on ImageProcessingException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('[ImageService] Gallery exception: $e');
      // Check for permission-related errors
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission') || 
          errorStr.contains('denied') || 
          errorStr.contains('access') ||
          errorStr.contains('photo') ||
          errorStr.contains('gallery')) {
        throw GalleryPermissionDeniedException();
      }
      throw ImageProcessingException('Gallery upload failed. Please try again.');
    } catch (e) {
      debugPrint('[ImageService] Gallery error: $e');
      throw ImageProcessingException('Gallery upload failed: ${e.toString()}');
    }
  }

  /// Crop image to square (1:1 aspect ratio)
  Future<File?> _cropImage(File imageFile) async {
    try {
      // Verify source file exists
      if (!await imageFile.exists()) {
        throw ImageProcessingException('Source image file not found');
      }

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

      // Null check and path verification
      if (croppedFile == null) {
        // User cancelled cropping - return original
        return imageFile;
      }

      final croppedPath = croppedFile.path;
      if (croppedPath.isEmpty) {
        throw ImageProcessingException('Cropped image path is invalid');
      }

      final resultFile = File(croppedPath);
      if (!await resultFile.exists()) {
        throw ImageProcessingException('Cropped image file not found');
      }

      return resultFile;
    } catch (e) {
      if (e is ImageProcessingException) rethrow;
      // Cropper error - return original image as fallback
      debugPrint('[ImageService] Crop error: $e');
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
