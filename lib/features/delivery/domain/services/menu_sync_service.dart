import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../data/models/menu_sync_result.dart';

/// Service that pushes the POS menu to the delivery middleware server.
///
/// Called manually from the product management screen, and automatically
/// when products are added, removed, or their price/availability changes.
class MenuSyncService {
  MenuSyncService({required String middlewareUrl})
      : _baseUrl = _toHttpUrl(middlewareUrl);

  String _baseUrl;

  /// Update the middleware URL (called when settings change).
  void updateUrl(String wsUrl) {
    _baseUrl = _toHttpUrl(wsUrl);
  }

  /// Sync [menuData] to all configured delivery platforms.
  ///
  /// [menuData] shape:
  /// ```json
  /// {
  ///   "categories": [{
  ///     "id": "...",
  ///     "name": "...",
  ///     "items": [{ "id", "name", "description", "price", "available", "imageUrl" }]
  ///   }]
  /// }
  /// ```
  Future<MenuSyncResult> syncMenu(Map<String, dynamic> menuData) async {
    final uri = Uri.parse('$_baseUrl/api/menu/sync');
    debugPrint('[MenuSync] POST $uri');

    HttpClient? client;
    try {
      client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15);

      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;

      final body = jsonEncode({'platform': 'all', 'menuData': menuData});
      request.contentLength = utf8.encode(body).length;
      request.write(body);

      final response = await request.close().timeout(const Duration(seconds: 30));
      final responseBody = await response.transform(utf8.decoder).join();
      final parsed = jsonDecode(responseBody) as Map<String, dynamic>;

      final status = response.statusCode;
      if (status == 200) {
        debugPrint('[MenuSync] All platforms synced successfully');
        return MenuSyncResult.success(parsed);
      } else if (status == 207) {
        debugPrint('[MenuSync] Partial sync: $parsed');
        return MenuSyncResult.partial(parsed);
      } else {
        debugPrint('[MenuSync] Sync failed ($status): $parsed');
        return MenuSyncResult.failure(
          parsed['error']?.toString() ?? 'Server error $status',
        );
      }
    } catch (e) {
      debugPrint('[MenuSync] Error: $e');
      return MenuSyncResult.failure(e.toString());
    } finally {
      client?.close();
    }
  }

  static String _toHttpUrl(String wsUrl) {
    // ws:// → http://, wss:// → https://
    return wsUrl
        .replaceFirst(RegExp(r'^wss://'), 'https://')
        .replaceFirst(RegExp(r'^ws://'), 'http://');
  }
}
