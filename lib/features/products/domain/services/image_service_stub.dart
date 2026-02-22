/// Web/unsupported stub for ImageService.
///
/// The current ImageService implementation relies on `dart:io` and native
/// plugins (cropper, path_provider) that are not available on web.
class ImageService {
  Future<dynamic> uploadFromCamera() async {
    throw UnsupportedError('Image upload from camera is not supported on web');
  }

  Future<dynamic> uploadFromGallery() async {
    throw UnsupportedError('Image upload from gallery is not supported on web');
  }

  Future<dynamic> resizeAndSaveImage(dynamic imageFile, String sku) async {
    throw UnsupportedError('Image processing is not supported on web');
  }

  Future<dynamic> bytesToFile(dynamic bytes, String sku) async {
    throw UnsupportedError('Image processing is not supported on web');
  }

  Future<void> deleteImage(String sku) async {
    // No-op on web.
  }
}
