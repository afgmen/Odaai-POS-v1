import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../../database/app_database.dart';
import '../../../../database/daos/products_dao.dart';
import '../../data/api/unsplash_api_client.dart';
import '../models/search_image_result.dart';
import 'image_service.dart';

/// Image Search Service for AI-powered image search
/// Uses Unsplash API to find product images automatically
class ImageSearchService {
  final UnsplashApiClient _unsplashClient;
  final ImageService _imageService;

  ImageSearchService({
    required UnsplashApiClient unsplashClient,
    required ImageService imageService,
  })  : _unsplashClient = unsplashClient,
        _imageService = imageService;

  /// Search images by product name
  /// Returns up to 5 candidate images from Unsplash
  Future<List<SearchImageResult>> searchByProductName(
      String productName) async {
    try {
      final unsplashImages = await _unsplashClient.searchPhotos(
        query: productName,
        perPage: 5,
      );

      return unsplashImages
          .map((img) => SearchImageResult(
                id: img.id,
                thumbUrl: img.urls.thumb,
                regularUrl: img.urls.regular,
                description: img.description,
                source: 'Unsplash',
                photographer: img.user.name,
              ))
          .toList();
    } catch (e) {
      // If Unsplash fails, could implement Pexels fallback here
      throw Exception('Image search failed: $e');
    }
  }

  /// Download and save selected image
  /// Downloads image from URL and saves to local storage
  Future<String> downloadAndSaveImage({
    required String imageUrl,
    required String sku,
  }) async {
    try {
      // Download image bytes
      final bytes = await _unsplashClient.downloadImage(imageUrl);

      // Use dynamic to handle platform differences:
      // Web: bytesToFile -> String (data URL), resizeAndSaveImage is a no-op
      // IO:  bytesToFile -> File, resizeAndSaveImage -> File
      final dynamic tempData = await _imageService.bytesToFile(bytes, sku);

      if (kIsWeb) {
        // Web: tempData is already the final data URL
        return tempData as String;
      }

      // IO: resize, delete temp, return path
      final dynamic savedFile = await _imageService.resizeAndSaveImage(tempData, sku);
      (tempData as dynamic).delete().catchError((_) {});
      return (savedFile as dynamic).path as String;
    } catch (e) {
      throw Exception('Download and save failed: $e');
    }
  }

  /// Batch process products without images
  /// Automatically searches and downloads images for multiple products
  Future<BatchProcessResult> batchProcess({
    required ProductsDao productsDao,
    required List<Product> products,
    required Function(int current, int total) onProgress,
  }) async {
    int successCount = 0;
    int failCount = 0;
    final List<String> failedProducts = [];

    for (int i = 0; i < products.length; i++) {
      final product = products[i];
      onProgress(i + 1, products.length);

      try {
        // Search images
        final results = await searchByProductName(product.name);
        if (results.isEmpty) {
          failCount++;
          failedProducts.add(product.name);
          continue;
        }

        // Download first result
        final savedPath = await downloadAndSaveImage(
          imageUrl: results.first.regularUrl,
          sku: product.sku,
        );

        // Update DB with actual saved path (data URL on web, file path on IO)
        await productsDao.updateProductImageUrl(
          product.id,
          savedPath,
        );

        successCount++;

        // Rate limiting: wait 1 second between requests
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        failCount++;
        failedProducts.add(product.name);
      }
    }

    return BatchProcessResult(
      total: products.length,
      success: successCount,
      failed: failCount,
      failedProducts: failedProducts,
    );
  }
}
