import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Unsplash API Client for image search
/// Free tier: 50 requests/hour
class UnsplashApiClient {
  static const String _baseUrl = 'https://api.unsplash.com';

  // DEMO ACCESS KEY - Replace with your own from https://unsplash.com/developers
  // This is a demo key with limited quota
  static const String _accessKey = 'YOUR_UNSPLASH_ACCESS_KEY_HERE';

  final Dio _dio;

  UnsplashApiClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  /// Search photos by query
  /// Returns up to [perPage] images matching the search query
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
            .map((json) => UnsplashImage.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Search failed: HTTP ${response.statusCode}');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout. Please check your internet.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Server response timeout.');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Invalid API key. Please configure Unsplash API key.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Rate limit exceeded. Please try again later.');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Unsplash API error: $e');
    }
  }

  /// Download image from URL
  Future<Uint8List> downloadImage(String url) async {
    try {
      final response = await _dio.get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data as List<int>);
    } catch (e) {
      throw Exception('Image download failed: $e');
    }
  }
}

/// Unsplash Image data model
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
      description: json['description'] as String? ??
          json['alt_description'] as String? ??
          '',
      urls: UnsplashUrls.fromJson(json['urls'] as Map<String, dynamic>),
      user: UnsplashUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// Unsplash image URLs (different sizes)
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

/// Unsplash photographer info
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
