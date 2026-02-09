# 상품 이미지 관리 (Product Image Management) - Design Document

**Feature**: Product Image Management with AI Auto-Search
**Version**: 1.0.0
**Created**: 2026-02-09
**Author**: AI Development Team
**Status**: Design Phase
**Plan Reference**: `docs/01-plan/features/product-image-management.plan.md`

---

## 1. Architecture Overview

### 1.1 Layer Structure (Clean Architecture)

```
┌───────────────────────────────────────────────────────────────────┐
│                     Presentation Layer                            │
│  ┌──────────────────────┐  ┌──────────────────────────────────┐  │
│  │ ProductFormModal     │  │ ProductManagementScreen          │  │
│  │ + Image Upload       │  │ + Thumbnail Grid View            │  │
│  │ + AI Search Button   │  │ + Batch Process Button           │  │
│  │ + Crop Widget        │  │                                  │  │
│  └──────────────────────┘  └──────────────────────────────────┘  │
│  ┌──────────────────────┐  ┌──────────────────────────────────┐  │
│  │ ImageSearchDialog    │  │ PosMainScreen                    │  │
│  │ - 5 Image Candidates │  │ + Product Image Display          │  │
│  │ - User Selection     │  │                                  │  │
│  └──────────────────────┘  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │              Providers (Riverpod)                            │ │
│  │  - imageUploadProvider                                       │ │
│  │  - imageSearchProvider                                       │ │
│  │  - imageCacheProvider                                        │ │
│  │  - batchProcessProvider                                      │ │
│  └──────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────────────┐
│                       Domain Layer                                │
│  ┌──────────────────────┐  ┌──────────────────────────────────┐  │
│  │ ImageService         │  │ ImageSearchService               │  │
│  │ - uploadFromCamera() │  │ - searchByProductName()          │  │
│  │ - uploadFromGallery()│  │ - downloadImage()                │  │
│  │ - cropImage()        │  │ - batchProcess()                 │  │
│  │ - deleteImage()      │  │ - fallbackToManual()             │  │
│  │ - resizeImage()      │  │                                  │  │
│  └──────────────────────┘  └──────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────────────┐
│                        Data Layer                                 │
│  ┌──────────────────────┐  ┌──────────────────────────────────┐  │
│  │ ProductsDao          │  │ API Clients                      │  │
│  │ - updateImageUrl()   │  │ - UnsplashApiClient              │  │
│  │ - getProductsWithout │  │ - PexelsApiClient (fallback)     │  │
│  │   Image()            │  │                                  │  │
│  └──────────────────────┘  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ Local File Storage                                           │ │
│  │ - Path: {app_documents}/product_images/                     │ │
│  │ - Naming: {sku}.jpg                                          │ │
│  │ - Cache: CachedNetworkImage                                  │ │
│  └──────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌───────────────────────────────────────────────────────────────────┐
│                    Database (Drift SQLite)                        │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │ products                                                  │   │
│  │ - id (PK)                                                 │   │
│  │ - sku (UNIQUE)                                            │   │
│  │ - name                                                    │   │
│  │ - imageUrl (TEXT NULLABLE) ✅ Already exists             │   │
│  │   Stores: file:///.../product_images/{sku}.jpg           │   │
│  │ - ... other fields                                        │   │
│  └───────────────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────────────────┘
```

### 1.2 Data Flow

#### 1.2.1 Manual Upload Flow
```
User → [Camera/Gallery Button]
  ↓
Image Picker → Raw Image
  ↓
Image Cropper → Cropped Image (Square)
  ↓
Image Service → Resize to 800x800
  ↓
Save to File → {app_documents}/product_images/{sku}.jpg
  ↓
ProductsDao → Update imageUrl in DB
  ↓
UI → Display Thumbnail
```

#### 1.2.2 AI Auto-Search Flow
```
User → [AI Search Button] + Product Name: "코카콜라 500ml"
  ↓
ImageSearchService → searchByProductName("코카콜라 500ml")
  ↓
Unsplash API → GET /search/photos?query=코카콜라
  ↓
5 Candidate Images → Display in Dialog
  ↓
User Selects Image → Download URL
  ↓
Download → Save to {app_documents}/product_images/{sku}.jpg
  ↓
ProductsDao → Update imageUrl
  ↓
UI → Display Thumbnail
```

#### 1.2.3 Batch Process Flow
```
User → [Batch Process Button]
  ↓
ProductsDao → getProductsWithoutImage() → 100 products
  ↓
For Each Product (Background Isolate):
  ↓
  Search API → Download → Save → Update DB
  ↓
  Update Progress: 15/100
  ↓
Complete → Show Success/Fail Report
```

---

## 2. Database Design

### 2.1 No Schema Changes Required

**Good News**: `imageUrl` 필드는 이미 존재합니다!

```dart
// lib/database/tables/products.dart (Line 13)
TextColumn get imageUrl => text().nullable()(); // ✅ Already exists
```

**No migration needed**. 기존 v9 그대로 사용.

### 2.2 ImageUrl Format

```dart
// Local file path
imageUrl = "file:///Users/.../product_images/DEMO001.jpg"

// Or relative path (preferred)
imageUrl = "product_images/DEMO001.jpg"
```

### 2.3 New DAO Methods

```dart
// lib/database/daos/products_dao.dart

extension ProductImageDaoExtension on ProductsDao {
  /// Update product image URL
  Future<void> updateProductImageUrl(int productId, String? imageUrl) async {
    await (update(products)..where((p) => p.id.equals(productId)))
        .write(ProductsCompanion(
      imageUrl: Value(imageUrl),
      updatedAt: Value(DateTime.now()),
      needsSync: const Value(true),
    ));
  }

  /// Get products without images
  Future<List<Product>> getProductsWithoutImage() {
    return (select(products)
          ..where((p) =>
              p.imageUrl.isNull() & p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  /// Get products with images
  Future<List<Product>> getProductsWithImage() {
    return (select(products)
          ..where((p) =>
              p.imageUrl.isNotNull() & p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  /// Get image coverage rate (%)
  Future<double> getImageCoverageRate() async {
    final total = await (select(products)
          ..where((p) => p.isActive.equals(true)))
        .get();
    final withImage = await (select(products)
          ..where((p) =>
              p.imageUrl.isNotNull() & p.isActive.equals(true)))
        .get();
    if (total.isEmpty) return 0;
    return (withImage.length / total.length) * 100;
  }
}
```

---

## 3. API Integration

### 3.1 Unsplash API (Primary)

#### 3.1.1 API Configuration

```dart
// lib/features/products/data/api/unsplash_api_client.dart

class UnsplashApiClient {
  static const String _baseUrl = 'https://api.unsplash.com';
  static const String _accessKey = 'YOUR_UNSPLASH_ACCESS_KEY';

  final Dio _dio;

  UnsplashApiClient({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: _baseUrl));

  /// Search photos by query
  Future<List<UnsplashImage>> searchPhotos({
    required String query,
    int perPage = 5,
    String orientation = 'squarish',
  }) async {
    try {
      final response = await _dio.get(
        '/search/photos',
        queryParameters: {
          'query': query,
          'per_page': perPage,
          'orientation': orientation,
        },
        options: Options(
          headers: {'Authorization': 'Client-ID $_accessKey'},
        ),
      );

      if (response.statusCode == 200) {
        final results = response.data['results'] as List;
        return results
            .map((json) => UnsplashImage.fromJson(json))
            .toList();
      }
      throw Exception('Search failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Unsplash API Error: $e');
    }
  }

  /// Download image from URL
  Future<Uint8List> downloadImage(String url) async {
    final response = await _dio.get(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data);
  }
}
```

#### 3.1.2 Data Models

```dart
// lib/features/products/domain/models/unsplash_image.dart

class UnsplashImage {
  final String id;
  final String description;
  final UnsplashUrls urls;
  final UnsplashUser user;

  const UnsplashImage({
    required this.id,
    required this.description,
    required this.urls,
    required this.user,
  });

  factory UnsplashImage.fromJson(Map<String, dynamic> json) {
    return UnsplashImage(
      id: json['id'] as String,
      description: json['description'] as String? ?? json['alt_description'] as String? ?? '',
      urls: UnsplashUrls.fromJson(json['urls'] as Map<String, dynamic>),
      user: UnsplashUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class UnsplashUrls {
  final String raw;
  final String full;
  final String regular;
  final String small;
  final String thumb;

  const UnsplashUrls({
    required this.raw,
    required this.full,
    required this.regular,
    required this.small,
    required this.thumb,
  });

  factory UnsplashUrls.fromJson(Map<String, dynamic> json) {
    return UnsplashUrls(
      raw: json['raw'] as String,
      full: json['full'] as String,
      regular: json['regular'] as String,
      small: json['small'] as String,
      thumb: json['thumb'] as String,
    );
  }
}

class UnsplashUser {
  final String name;
  final String username;

  const UnsplashUser({
    required this.name,
    required this.username,
  });

  factory UnsplashUser.fromJson(Map<String, dynamic> json) {
    return UnsplashUser(
      name: json['name'] as String,
      username: json['username'] as String,
    );
  }
}
```

#### 3.1.3 API Limits

| Tier | Requests/Hour | Cost |
|------|---------------|------|
| Demo (Development) | 50 | Free |
| Production | 5,000 | Free |

**Rate Limiting Strategy**:
```dart
class RateLimiter {
  final int maxRequests;
  final Duration window;
  final List<DateTime> _timestamps = [];

  RateLimiter({required this.maxRequests, required this.window});

  Future<void> checkLimit() async {
    final now = DateTime.now();
    _timestamps.removeWhere((t) => now.difference(t) > window);

    if (_timestamps.length >= maxRequests) {
      final oldestRequest = _timestamps.first;
      final waitTime = window - now.difference(oldestRequest);
      throw RateLimitException('Rate limit exceeded. Wait ${waitTime.inSeconds}s');
    }

    _timestamps.add(now);
  }
}
```

### 3.2 Pexels API (Fallback)

```dart
// lib/features/products/data/api/pexels_api_client.dart

class PexelsApiClient {
  static const String _baseUrl = 'https://api.pexels.com/v1';
  static const String _apiKey = 'YOUR_PEXELS_API_KEY';

  final Dio _dio;

  PexelsApiClient({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: _baseUrl));

  Future<List<PexelsImage>> searchPhotos({
    required String query,
    int perPage = 5,
  }) async {
    final response = await _dio.get(
      '/search',
      queryParameters: {
        'query': query,
        'per_page': perPage,
        'orientation': 'square',
      },
      options: Options(
        headers: {'Authorization': _apiKey},
      ),
    );

    final photos = response.data['photos'] as List;
    return photos.map((json) => PexelsImage.fromJson(json)).toList();
  }
}
```

**API Limits**: 200 requests/hour (Free)

---

## 4. Domain Layer Services

### 4.1 ImageService

```dart
// lib/features/products/domain/services/image_service.dart

class ImageService {
  final ImagePicker _picker = ImagePicker();
  final ImageCropper _cropper = ImageCropper();

  /// Upload image from camera
  Future<File?> uploadFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 90,
    );

    if (image == null) return null;
    return await _cropImage(File(image.path));
  }

  /// Upload image from gallery
  Future<File?> uploadFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 90,
    );

    if (image == null) return null;
    return await _cropImage(File(image.path));
  }

  /// Crop image to square
  Future<File?> _cropImage(File imageFile) async {
    final croppedFile = await _cropper.cropImage(
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
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    return croppedFile != null ? File(croppedFile.path) : null;
  }

  /// Resize image to max 800x800
  Future<File> resizeImage(File imageFile, String sku) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) throw Exception('Failed to decode image');

    // Resize if larger than 800x800
    img.Image resized = image;
    if (image.width > 800 || image.height > 800) {
      resized = img.copyResize(
        image,
        width: image.width > image.height ? 800 : null,
        height: image.height > image.width ? 800 : null,
      );
    }

    // Save to app documents directory
    final directory = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${directory.path}/product_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final savePath = '${imagesDir.path}/$sku.jpg';
    final savedFile = File(savePath);
    await savedFile.writeAsBytes(img.encodeJpg(resized, quality: 85));

    return savedFile;
  }

  /// Delete product image
  Future<void> deleteImage(String sku) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/product_images/$sku.jpg';
    final file = File(imagePath);

    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Get local image path
  Future<String?> getImagePath(String sku) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/product_images/$sku.jpg';
    final file = File(imagePath);

    return await file.exists() ? imagePath : null;
  }
}
```

### 4.2 ImageSearchService

```dart
// lib/features/products/domain/services/image_search_service.dart

class ImageSearchService {
  final UnsplashApiClient _unsplashClient;
  final PexelsApiClient _pexelsClient;
  final ImageService _imageService;

  ImageSearchService({
    required UnsplashApiClient unsplashClient,
    required PexelsApiClient pexelsClient,
    required ImageService imageService,
  })  : _unsplashClient = unsplashClient,
        _pexelsClient = pexelsClient,
        _imageService = imageService;

  /// Search images by product name
  Future<List<SearchImageResult>> searchByProductName(String productName) async {
    try {
      // Try Unsplash first
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
    } catch (unsplashError) {
      // Fallback to Pexels
      try {
        final pexelsImages = await _pexelsClient.searchPhotos(
          query: productName,
          perPage: 5,
        );

        return pexelsImages
            .map((img) => SearchImageResult(
                  id: img.id.toString(),
                  thumbUrl: img.src.small,
                  regularUrl: img.src.large,
                  description: productName,
                  source: 'Pexels',
                  photographer: img.photographer,
                ))
            .toList();
      } catch (pexelsError) {
        throw Exception('Both APIs failed: $unsplashError, $pexelsError');
      }
    }
  }

  /// Download and save selected image
  Future<String> downloadAndSaveImage({
    required String imageUrl,
    required String sku,
  }) async {
    // Download image bytes
    final bytes = await _unsplashClient.downloadImage(imageUrl);

    // Save to temporary file
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/temp_$sku.jpg');
    await tempFile.writeAsBytes(bytes);

    // Resize and save to product_images
    final savedFile = await _imageService.resizeImage(tempFile, sku);

    // Delete temp file
    await tempFile.delete();

    return savedFile.path;
  }

  /// Batch process products without images
  Future<BatchProcessResult> batchProcess({
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
        await downloadAndSaveImage(
          imageUrl: results.first.regularUrl,
          sku: product.sku,
        );

        // Update DB
        final dao = GetIt.instance<ProductsDao>();
        await dao.updateProductImageUrl(
          product.id,
          'product_images/${product.sku}.jpg',
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

class SearchImageResult {
  final String id;
  final String thumbUrl;
  final String regularUrl;
  final String description;
  final String source;
  final String photographer;

  SearchImageResult({
    required this.id,
    required this.thumbUrl,
    required this.regularUrl,
    required this.description,
    required this.source,
    required this.photographer,
  });
}

class BatchProcessResult {
  final int total;
  final int success;
  final int failed;
  final List<String> failedProducts;

  BatchProcessResult({
    required this.total,
    required this.success,
    required this.failed,
    required this.failedProducts,
  });
}
```

---

## 5. Presentation Layer

### 5.1 ProductFormModal Modifications

```dart
// lib/features/products/presentation/widgets/product_form_modal.dart

// Add new state variables
String? _imageUrl;
File? _selectedImageFile;
bool _isSearchingImage = false;

// Add new UI section after category field (after line 174)

// ─── 이미지 섹션 ──────────────
_sectionLabel('상품 이미지'),
_buildImageSection(),
const SizedBox(height: 12),
```

```dart
Widget _buildImageSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Image preview or placeholder
      Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: _selectedImageFile != null || _imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _selectedImageFile != null
                    ? Image.file(_selectedImageFile!, fit: BoxFit.cover)
                    : CachedNetworkImage(
                        imageUrl: _imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.broken_image,
                          size: 48,
                          color: AppTheme.textDisabled,
                        ),
                      ),
              )
            : const Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 48,
                  color: AppTheme.textDisabled,
                ),
              ),
      ),
      const SizedBox(height: 12),

      // Action buttons
      Row(
        children: [
          // Manual upload buttons
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _handleCameraUpload,
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text('카메라'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _handleGalleryUpload,
              icon: const Icon(Icons.photo_library, size: 18),
              label: const Text('갤러리'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // AI Search button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isSearchingImage ? null : _handleAISearch,
              icon: _isSearchingImage
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome, size: 18),
              label: const Text('AI 검색'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),

      // Delete button (if image exists)
      if (_selectedImageFile != null || _imageUrl != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextButton.icon(
            onPressed: _handleDeleteImage,
            icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
            label: const Text('이미지 삭제', style: TextStyle(color: AppTheme.error)),
          ),
        ),
    ],
  );
}
```

### 5.2 ImageSearchDialog (New Widget)

```dart
// lib/features/products/presentation/widgets/image_search_dialog.dart

class ImageSearchDialog extends StatefulWidget {
  final String productName;

  const ImageSearchDialog({
    super.key,
    required this.productName,
  });

  @override
  State<ImageSearchDialog> createState() => _ImageSearchDialogState();
}

class _ImageSearchDialogState extends State<ImageSearchDialog> {
  late Future<List<SearchImageResult>> _searchFuture;

  @override
  void initState() {
    super.initState();
    final searchService = GetIt.instance<ImageSearchService>();
    _searchFuture = searchService.searchByProductName(widget.productName);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI 이미지 검색',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '검색어: ${widget.productName}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Image grid
            FutureBuilder<List<SearchImageResult>>(
              future: _searchFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppTheme.error,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '검색 실패: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final results = snapshot.data!;
                if (results.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: AppTheme.textDisabled,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '검색 결과가 없습니다',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final result = results[index];
                    return _ImageCard(
                      result: result,
                      onSelect: () => Navigator.of(context).pop(result),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  final SearchImageResult result;
  final VoidCallback onSelect;

  const _ImageCard({
    required this.result,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: result.thumbUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppTheme.background,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.background,
                  child: const Icon(Icons.broken_image),
                ),
              ),
              // Attribution overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    '${result.source} - ${result.photographer}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 5.3 ProductManagementScreen Modifications

```dart
// Modify existing ListView.builder to display thumbnails

// Replace current ListTile with:
Widget _buildProductCard(Product product) {
  return Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      // Add leading image
      leading: product.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: product.imageUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppTheme.background,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.background,
                  child: const Icon(Icons.broken_image, size: 24),
                ),
              ),
            )
          : Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.image_not_supported,
                size: 24,
                color: AppTheme.textDisabled,
              ),
            ),
      title: Text(product.name),
      subtitle: Text('SKU: ${product.sku}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Existing actions...
        ],
      ),
    ),
  );
}

// Add batch process button in AppBar actions
IconButton(
  icon: const Icon(Icons.auto_awesome),
  tooltip: '일괄 이미지 검색',
  onPressed: _handleBatchImageSearch,
),
```

### 5.4 PosMainScreen Modifications

```dart
// lib/features/pos/presentation/screens/pos_main_screen.dart

// Modify product grid item to show image
Widget _buildProductCard(Product product) {
  return Card(
    child: InkWell(
      onTap: () => _addToCart(product),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Product image (new)
          Expanded(
            flex: 3,
            child: product.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: product.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppTheme.background,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.background,
                      child: const Icon(Icons.broken_image),
                    ),
                  )
                : Container(
                    color: AppTheme.background,
                    child: const Icon(
                      Icons.fastfood,
                      size: 48,
                      color: AppTheme.textDisabled,
                    ),
                  ),
          ),
          // Product name & price (existing)
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₩${NumberFormat('#,###').format(product.price)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
```

---

## 6. Providers (Riverpod)

```dart
// lib/features/products/presentation/providers/image_providers.dart

/// Image Service Provider
final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService();
});

/// Image Search Service Provider
final imageSearchServiceProvider = Provider<ImageSearchService>((ref) {
  return ImageSearchService(
    unsplashClient: ref.watch(unsplashApiClientProvider),
    pexelsClient: ref.watch(pexelsApiClientProvider),
    imageService: ref.watch(imageServiceProvider),
  );
});

/// Unsplash API Client Provider
final unsplashApiClientProvider = Provider<UnsplashApiClient>((ref) {
  return UnsplashApiClient();
});

/// Pexels API Client Provider
final pexelsApiClientProvider = Provider<PexelsApiClient>((ref) {
  return PexelsApiClient();
});

/// Image Upload State Provider
final imageUploadStateProvider = StateNotifierProvider<ImageUploadStateNotifier, ImageUploadState>((ref) {
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

  Future<void> uploadFromCamera(int productId, String sku) async {
    state = const ImageUploadState.loading();
    try {
      final file = await _imageService.uploadFromCamera();
      if (file == null) {
        state = const ImageUploadState.idle();
        return;
      }

      final savedFile = await _imageService.resizeImage(file, sku);
      await _productsDao.updateProductImageUrl(
        productId,
        'product_images/$sku.jpg',
      );

      state = ImageUploadState.success(savedFile.path);
    } catch (e) {
      state = ImageUploadState.error(e.toString());
    }
  }

  Future<void> uploadFromGallery(int productId, String sku) async {
    state = const ImageUploadState.loading();
    try {
      final file = await _imageService.uploadFromGallery();
      if (file == null) {
        state = const ImageUploadState.idle();
        return;
      }

      final savedFile = await _imageService.resizeImage(file, sku);
      await _productsDao.updateProductImageUrl(
        productId,
        'product_images/$sku.jpg',
      );

      state = ImageUploadState.success(savedFile.path);
    } catch (e) {
      state = ImageUploadState.error(e.toString());
    }
  }

  Future<void> deleteImage(int productId, String sku) async {
    try {
      await _imageService.deleteImage(sku);
      await _productsDao.updateProductImageUrl(productId, null);
      state = const ImageUploadState.idle();
    } catch (e) {
      state = ImageUploadState.error(e.toString());
    }
  }
}

@freezed
class ImageUploadState with _$ImageUploadState {
  const factory ImageUploadState.idle() = _Idle;
  const factory ImageUploadState.loading() = _Loading;
  const factory ImageUploadState.success(String imagePath) = _Success;
  const factory ImageUploadState.error(String message) = _Error;
}

/// Batch Process Provider
final batchProcessProvider = StateNotifierProvider<BatchProcessNotifier, BatchProcessState>((ref) {
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
}

@freezed
class BatchProcessState with _$BatchProcessState {
  const factory BatchProcessState.idle() = _BatchIdle;
  const factory BatchProcessState.processing(int current, int total) = _Processing;
  const factory BatchProcessState.completed(BatchProcessResult result) = _Completed;
  const factory BatchProcessState.error(String message) = _BatchError;
}
```

---

## 7. File Structure

```
lib/
├── features/
│   └── products/
│       ├── data/
│       │   └── api/
│       │       ├── unsplash_api_client.dart        # Unsplash API
│       │       └── pexels_api_client.dart          # Pexels API (fallback)
│       ├── domain/
│       │   ├── models/
│       │   │   ├── unsplash_image.dart             # Unsplash data models
│       │   │   └── pexels_image.dart               # Pexels data models
│       │   └── services/
│       │       ├── image_service.dart              # Upload, crop, resize
│       │       └── image_search_service.dart       # AI search, batch
│       └── presentation/
│           ├── providers/
│           │   └── image_providers.dart            # Riverpod providers
│           └── widgets/
│               ├── product_form_modal.dart         # Modified (image section)
│               └── image_search_dialog.dart        # New (AI search results)

docs/
├── 01-plan/
│   └── features/
│       └── product-image-management.plan.md        # ✅ Completed
└── 02-design/
    └── features/
        └── product-image-management.design.md      # ✅ This document

assets/
└── (No changes - images stored in app_documents)

app_documents/
└── product_images/
    ├── DEMO001.jpg
    ├── DEMO002.jpg
    └── ...
```

---

## 8. Error Handling

### 8.1 Error Scenarios

| Error | Cause | Mitigation |
|-------|-------|------------|
| **API Rate Limit** | Exceeded 50 req/hour | Wait + Show retry timer |
| **API Failure** | Network issue | Fallback to Pexels |
| **No Results** | Product name too specific | Suggest manual upload |
| **Download Failure** | Image URL expired | Retry + Manual upload |
| **Storage Full** | Disk space insufficient | Show storage warning |
| **Permission Denied** | Camera/storage permission | Request permission |

### 8.2 Error Messages (i18n)

```dart
// lib/l10n/app_localizations_en.dart

'imageUploadCameraPermission': 'Camera permission required',
'imageUploadStoragePermission': 'Storage permission required',
'imageUploadFailed': 'Image upload failed',
'imageSearchNoResults': 'No images found for "{productName}"',
'imageSearchApiFailed': 'Image search failed. Please try manual upload',
'imageSearchRateLimitExceeded': 'Rate limit exceeded. Please wait {seconds} seconds',
'imageBatchProcessSuccess': 'Batch process completed: {success}/{total} succeeded',
'imageBatchProcessFailed': 'Batch process failed: {error}',
```

---

## 9. Testing Strategy

### 9.1 Unit Tests

```dart
// test/features/products/domain/services/image_service_test.dart

group('ImageService', () {
  late ImageService imageService;

  setUp(() {
    imageService = ImageService();
  });

  test('resizeImage should resize to max 800x800', () async {
    // Test implementation
  });

  test('deleteImage should remove file from disk', () async {
    // Test implementation
  });
});

// test/features/products/domain/services/image_search_service_test.dart

group('ImageSearchService', () {
  late ImageSearchService searchService;
  late MockUnsplashApiClient mockUnsplashClient;
  late MockPexelsApiClient mockPexelsClient;

  setUp(() {
    mockUnsplashClient = MockUnsplashApiClient();
    mockPexelsClient = MockPexelsApiClient();
    searchService = ImageSearchService(
      unsplashClient: mockUnsplashClient,
      pexelsClient: mockPexelsClient,
      imageService: ImageService(),
    );
  });

  test('searchByProductName should return results from Unsplash', () async {
    // Mock Unsplash response
    when(mockUnsplashClient.searchPhotos(query: any))
        .thenAnswer((_) async => mockUnsplashImages);

    final results = await searchService.searchByProductName('코카콜라');

    expect(results.length, 5);
    expect(results.first.source, 'Unsplash');
  });

  test('searchByProductName should fallback to Pexels on Unsplash failure', () async {
    // Mock Unsplash failure
    when(mockUnsplashClient.searchPhotos(query: any))
        .thenThrow(Exception('API Error'));

    // Mock Pexels success
    when(mockPexelsClient.searchPhotos(query: any))
        .thenAnswer((_) async => mockPexelsImages);

    final results = await searchService.searchByProductName('코카콜라');

    expect(results.first.source, 'Pexels');
  });
});
```

### 9.2 Widget Tests

```dart
// test/features/products/presentation/widgets/image_search_dialog_test.dart

testWidgets('ImageSearchDialog should display 5 image results', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ImageSearchDialog(productName: '코카콜라'),
    ),
  );

  await tester.pump(); // Wait for FutureBuilder

  expect(find.byType(GridView), findsOneWidget);
  expect(find.byType(_ImageCard), findsNWidgets(5));
});

testWidgets('ImageSearchDialog should return selected image on tap', (tester) async {
  SearchImageResult? selectedImage;

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            selectedImage = await showDialog<SearchImageResult>(
              context: context,
              builder: (_) => ImageSearchDialog(productName: '코카콜라'),
            );
          },
          child: const Text('Open'),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();

  // Tap first image
  await tester.tap(find.byType(_ImageCard).first);
  await tester.pumpAndSettle();

  expect(selectedImage, isNotNull);
});
```

### 9.3 Integration Tests

```dart
// integration_test/product_image_flow_test.dart

testWidgets('Complete product image upload flow', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  // Navigate to Product Management
  await tester.tap(find.text('Products'));
  await tester.pumpAndSettle();

  // Open product form
  await tester.tap(find.text('Add Product'));
  await tester.pumpAndSettle();

  // Fill product details
  await tester.enterText(find.byKey(const Key('sku_field')), 'TEST001');
  await tester.enterText(find.byKey(const Key('name_field')), '테스트 상품');
  await tester.enterText(find.byKey(const Key('price_field')), '10000');

  // Tap AI Search
  await tester.tap(find.text('AI 검색'));
  await tester.pumpAndSettle();

  // Wait for search results
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Select first image
  await tester.tap(find.byType(_ImageCard).first);
  await tester.pumpAndSettle();

  // Verify image preview
  expect(find.byType(CachedNetworkImage), findsOneWidget);

  // Save product
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();

  // Verify product card shows image
  expect(find.byType(CachedNetworkImage), findsWidgets);
});
```

---

## 10. Performance Optimizations

### 10.1 Image Caching Strategy

```dart
// Use cached_network_image for all image displays

CachedNetworkImage(
  imageUrl: product.imageUrl!,
  cacheKey: 'product_${product.sku}',
  memCacheWidth: 400, // Downscale for memory
  memCacheHeight: 400,
  fadeInDuration: const Duration(milliseconds: 200),
  placeholderFadeInDuration: const Duration(milliseconds: 100),
  // ... other options
)
```

### 10.2 Lazy Loading

```dart
// In ProductManagementScreen - use ListView.builder for lazy loading

ListView.builder(
  itemCount: products.length,
  itemBuilder: (context, index) {
    final product = products[index];
    return _buildProductCard(product);
  },
)
```

### 10.3 Background Processing

```dart
// Batch process in isolate to avoid UI blocking

Future<BatchProcessResult> batchProcess(...) async {
  return await compute(_batchProcessIsolate, products);
}

static Future<BatchProcessResult> _batchProcessIsolate(
  List<Product> products,
) async {
  // Heavy processing here
  // ...
}
```

---

## 11. Security & Privacy

### 11.1 API Key Management

```dart
// DO NOT hardcode API keys in source code
// Use environment variables or secure storage

class ApiConfig {
  static String get unsplashApiKey {
    const key = String.fromEnvironment('UNSPLASH_API_KEY');
    if (key.isEmpty) {
      throw Exception('UNSPLASH_API_KEY not set');
    }
    return key;
  }
}

// Build command:
// flutter run --dart-define=UNSPLASH_API_KEY=your_key_here
```

### 11.2 Image Attribution

```dart
// Always show photographer credit (Unsplash/Pexels ToS)

Text('Photo by ${result.photographer} on ${result.source}')
```

### 11.3 Local Storage Security

```dart
// Images stored in app documents directory (sandboxed)
// Not accessible by other apps
// Automatically deleted on app uninstall
```

---

## 12. Accessibility

### 12.1 Semantic Labels

```dart
Semantics(
  label: 'Product image: ${product.name}',
  child: CachedNetworkImage(...),
)

Semantics(
  button: true,
  label: 'Upload image from camera',
  child: IconButton(...),
)
```

### 12.2 Screen Reader Support

```dart
// Provide meaningful descriptions for images

imageSemanticLabel: product.imageUrl != null
    ? 'Image of ${product.name}'
    : 'No image available for ${product.name}',
```

---

## 13. Internationalization (i18n)

```dart
// lib/l10n/app_localizations_en.dart

'imageUpload': 'Upload Image',
'imageCamera': 'Camera',
'imageGallery': 'Gallery',
'imageAiSearch': 'AI Search',
'imageDelete': 'Delete Image',
'imageBatchProcess': 'Batch Image Search',
'imageSearching': 'Searching images...',
'imageNoImage': 'No Image',
'imageSelectSource': 'Select image source',

// lib/l10n/app_localizations_ko.dart

'imageUpload': '이미지 업로드',
'imageCamera': '카메라',
'imageGallery': '갤러리',
'imageAiSearch': 'AI 검색',
'imageDelete': '이미지 삭제',
'imageBatchProcess': '일괄 이미지 검색',
'imageSearching': '이미지 검색 중...',
'imageNoImage': '이미지 없음',
'imageSelectSource': '이미지 소스 선택',
```

---

## 14. Rollback Plan

### 14.1 Feature Flag

```dart
// lib/core/config/feature_flags.dart

class FeatureFlags {
  static const bool enableProductImages = true;

  static bool get isProductImageEnabled {
    return enableProductImages &&
           /* check other conditions */;
  }
}

// Usage in UI:
if (FeatureFlags.isProductImageEnabled) {
  // Show image section
}
```

### 14.2 Data Rollback

```dart
// If rollback needed:
// 1. Disable feature flag
// 2. imageUrl remains in DB (nullable) - no data loss
// 3. Images remain on disk - can be re-enabled later
// 4. No migration needed for rollback
```

---

## 15. Success Metrics & Monitoring

### 15.1 Analytics Events

```dart
analytics.logEvent('product_image_upload', {
  'method': 'camera | gallery | ai_search',
  'product_sku': product.sku,
  'success': true,
  'duration_ms': stopwatch.elapsedMilliseconds,
});

analytics.logEvent('ai_image_search', {
  'query': productName,
  'results_count': results.length,
  'selected': selectedImage != null,
  'api_used': 'unsplash | pexels',
});

analytics.logEvent('batch_image_process', {
  'total_products': products.length,
  'success_count': result.success,
  'failed_count': result.failed,
  'duration_seconds': duration.inSeconds,
});
```

### 15.2 Performance Metrics

```dart
// Track image loading performance
final stopwatch = Stopwatch()..start();

CachedNetworkImage(
  imageUrl: url,
  imageBuilder: (context, imageProvider) {
    stopwatch.stop();
    analytics.logEvent('image_load_time', {
      'duration_ms': stopwatch.elapsedMilliseconds,
      'cache_hit': stopwatch.elapsedMilliseconds < 100,
    });
    return Image(image: imageProvider);
  },
)
```

### 15.3 Dashboard KPIs

```dart
// Track in analytics dashboard:
// - Image coverage rate: 85% → 95%
// - Average upload time: 45s → 30s
// - AI search success rate: 80% → 90%
// - Batch process efficiency: 10 products/minute
```

---

## 16. Future Enhancements (v2.0)

### 16.1 Cloud Storage Integration

```dart
// Firebase Storage or AWS S3
Future<String> uploadToCloud(File imageFile, String sku) async {
  final ref = FirebaseStorage.instance.ref('products/$sku.jpg');
  await ref.putFile(imageFile);
  return await ref.getDownloadURL();
}
```

### 16.2 AI Image Quality Analysis

```dart
// Google Vision API
Future<ImageQualityScore> analyzeImageQuality(File image) async {
  final visionClient = GoogleVisionClient();
  final analysis = await visionClient.analyzeImage(image);

  return ImageQualityScore(
    clarity: analysis.clarity, // 0-1
    lighting: analysis.lighting,
    recommendation: analysis.clarity < 0.7
        ? 'Image quality is low. Consider retaking'
        : 'Good quality',
  );
}
```

### 16.3 Multi-Image Gallery

```dart
// Allow multiple images per product
class Products extends Table {
  TextColumn get imageUrls => text().nullable()(); // JSON array of URLs
}

// UI: Swipeable gallery
PageView.builder(
  itemCount: product.imageUrls.length,
  itemBuilder: (context, index) {
    return Image.network(product.imageUrls[index]);
  },
)
```

---

## 17. Approval

### 17.1 Design Review Checklist

- [x] Architecture diagram complete
- [x] Database schema defined (no changes needed)
- [x] API integration specified (Unsplash + Pexels)
- [x] UI wireframes included
- [x] Error handling defined
- [x] Performance optimizations planned
- [x] Testing strategy outlined
- [x] i18n support included

### 17.2 Sign-off Required

- [ ] Product Owner: ________________
- [ ] Tech Lead: ________________
- [ ] UX Designer: ________________
- [ ] Security Review: ________________

### 17.3 Next Steps

1. ✅ Design 승인 → Implementation 시작
2. Phase 1: 기본 이미지 업로드 (Day 1-2)
3. Phase 2: AI 자동 검색 (Day 3-4)
4. Phase 3: UI 통합 (Day 5)
5. Phase 4: 테스트 & 최적화 (Day 6)
6. Gap Analysis → `/pdca analyze product-image-management`

---

**Document Version**: 1.0.0
**Last Updated**: 2026-02-09
**Status**: ✅ Ready for Implementation
