import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/daos/products_dao.dart';
import '../../../../providers/database_providers.dart';
import '../../data/api/unsplash_api_client.dart';
import '../../domain/models/search_image_result.dart';
import '../../domain/services/image_search_service.dart';
import '../../domain/services/image_service.dart';

/// Image Service Provider
final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService();
});

/// Unsplash API Client Provider
final unsplashApiClientProvider = Provider<UnsplashApiClient>((ref) {
  return UnsplashApiClient();
});

/// Image Search Service Provider
final imageSearchServiceProvider = Provider<ImageSearchService>((ref) {
  return ImageSearchService(
    unsplashClient: ref.watch(unsplashApiClientProvider),
    imageService: ref.watch(imageServiceProvider),
  );
});

/// Image Upload State Provider
final imageUploadStateProvider =
    StateNotifierProvider<ImageUploadStateNotifier, ImageUploadState>((ref) {
  return ImageUploadStateNotifier(
    imageService: ref.watch(imageServiceProvider),
    productsDao: ref.watch(productsDaoProvider),
  );
});

class ImageUploadStateNotifier extends StateNotifier<ImageUploadState> {
  final ImageService _imageService;
  final ProductsDao _productsDao;

  ImageUploadStateNotifier({
    required ImageService imageService,
    required ProductsDao productsDao,
  })  : _imageService = imageService,
        _productsDao = productsDao,
        super(const ImageUploadState.idle());

  /// Upload from camera
  Future<File?> uploadFromCamera(int productId, String sku) async {
    state = const ImageUploadState.loading();
    try {
      final file = await _imageService.uploadFromCamera();
      if (file == null) {
        state = const ImageUploadState.idle();
        return null;
      }

      final savedFile = await _imageService.resizeAndSaveImage(file, sku);
      await _productsDao.updateProductImageUrl(
        productId,
        'product_images/$sku.jpg',
      );

      state = ImageUploadState.success(savedFile.path);
      return savedFile;
    } catch (e) {
      state = ImageUploadState.error(e.toString());
      return null;
    }
  }

  /// Upload from gallery
  Future<File?> uploadFromGallery(int productId, String sku) async {
    state = const ImageUploadState.loading();
    try {
      final file = await _imageService.uploadFromGallery();
      if (file == null) {
        state = const ImageUploadState.idle();
        return null;
      }

      final savedFile = await _imageService.resizeAndSaveImage(file, sku);
      await _productsDao.updateProductImageUrl(
        productId,
        'product_images/$sku.jpg',
      );

      state = ImageUploadState.success(savedFile.path);
      return savedFile;
    } catch (e) {
      state = ImageUploadState.error(e.toString());
      return null;
    }
  }

  /// Delete image
  Future<void> deleteImage(int productId, String sku) async {
    try {
      await _imageService.deleteImage(sku);
      await _productsDao.updateProductImageUrl(productId, null);
      state = const ImageUploadState.idle();
    } catch (e) {
      state = ImageUploadState.error(e.toString());
    }
  }

  /// Reset state
  void reset() {
    state = const ImageUploadState.idle();
  }
}

/// Image Upload State
sealed class ImageUploadState {
  const ImageUploadState();

  const factory ImageUploadState.idle() = ImageUploadIdle;
  const factory ImageUploadState.loading() = ImageUploadLoading;
  const factory ImageUploadState.success(String imagePath) = ImageUploadSuccess;
  const factory ImageUploadState.error(String message) = ImageUploadError;
}

class ImageUploadIdle extends ImageUploadState {
  const ImageUploadIdle();
}

class ImageUploadLoading extends ImageUploadState {
  const ImageUploadLoading();
}

class ImageUploadSuccess extends ImageUploadState {
  final String imagePath;
  const ImageUploadSuccess(this.imagePath);
}

class ImageUploadError extends ImageUploadState {
  final String message;
  const ImageUploadError(this.message);
}

/// Batch Process Provider
final batchProcessProvider =
    StateNotifierProvider<BatchProcessNotifier, BatchProcessState>((ref) {
  return BatchProcessNotifier(
    imageSearchService: ref.watch(imageSearchServiceProvider),
    productsDao: ref.watch(productsDaoProvider),
  );
});

class BatchProcessNotifier extends StateNotifier<BatchProcessState> {
  final ImageSearchService _imageSearchService;
  final ProductsDao _productsDao;

  BatchProcessNotifier({
    required ImageSearchService imageSearchService,
    required ProductsDao productsDao,
  })  : _imageSearchService = imageSearchService,
        _productsDao = productsDao,
        super(const BatchProcessState.idle());

  Future<void> startBatchProcess() async {
    try {
      // Get products without images
      final products = await _productsDao.getProductsWithoutImage();

      if (products.isEmpty) {
        state = const BatchProcessState.error('이미지 없는 상품이 없습니다');
        return;
      }

      state = BatchProcessState.processing(0, products.length);

      // Start batch processing
      final result = await _imageSearchService.batchProcess(
        productsDao: _productsDao,
        products: products,
        onProgress: (current, total) {
          state = BatchProcessState.processing(current, total);
        },
      );

      state = BatchProcessState.completed(result);
    } catch (e) {
      state = BatchProcessState.error(e.toString());
    }
  }

  void reset() {
    state = const BatchProcessState.idle();
  }
}

/// Batch Process State
sealed class BatchProcessState {
  const BatchProcessState();

  const factory BatchProcessState.idle() = BatchProcessIdle;
  const factory BatchProcessState.processing(int current, int total) =
      BatchProcessProcessing;
  const factory BatchProcessState.completed(BatchProcessResult result) =
      BatchProcessCompleted;
  const factory BatchProcessState.error(String message) = BatchProcessError;
}

class BatchProcessIdle extends BatchProcessState {
  const BatchProcessIdle();
}

class BatchProcessProcessing extends BatchProcessState {
  final int current;
  final int total;

  const BatchProcessProcessing(this.current, this.total);

  double get progress => current / total;
}

class BatchProcessCompleted extends BatchProcessState {
  final BatchProcessResult result;

  const BatchProcessCompleted(this.result);
}

class BatchProcessError extends BatchProcessState {
  final String message;

  const BatchProcessError(this.message);
}
