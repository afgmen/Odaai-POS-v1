import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/delivery_service_provider.dart';

/// Status of a single delivery platform connector on the server.
class PlatformStatus {
  final String name;
  final bool active;
  final String? registeredAt;

  const PlatformStatus({
    required this.name,
    required this.active,
    this.registeredAt,
  });

  factory PlatformStatus.fromJson(Map<String, dynamic> json) {
    return PlatformStatus(
      name: json['name'] as String? ?? '',
      active: json['active'] as bool? ?? false,
      registeredAt: json['registeredAt'] as String?,
    );
  }

  String get displayName {
    switch (name.toLowerCase()) {
      case 'grab':
        return 'GrabFood';
      case 'shopeefood':
        return 'ShopeeFood';
      default:
        return name;
    }
  }
}

/// Connection test result.
class ConnectionTestResult {
  final bool ok;
  final int latencyMs;
  final String message;

  const ConnectionTestResult({
    required this.ok,
    required this.latencyMs,
    required this.message,
  });

  factory ConnectionTestResult.fromJson(Map<String, dynamic> json) {
    return ConnectionTestResult(
      ok: json['ok'] as bool? ?? false,
      latencyMs: json['latencyMs'] as int? ?? 0,
      message: json['message'] as String? ?? '',
    );
  }
}

// ──────────────────────────────────────────────
// Fetch platform statuses from server
// ──────────────────────────────────────────────

final platformStatusProvider = FutureProvider<List<PlatformStatus>>((ref) async {
  final wsUrl = ref.watch(middlewareUrlProvider);
  final httpUrl = _toHttpUrl(wsUrl);

  HttpClient? client;
  try {
    client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    final uri = Uri.parse('$httpUrl/api/platforms');
    final request = await client.getUrl(uri);
    final response = await request.close().timeout(const Duration(seconds: 10));
    final body = await response.transform(utf8.decoder).join();
    final parsed = jsonDecode(body) as Map<String, dynamic>;
    final platforms = (parsed['platforms'] as List<dynamic>? ?? [])
        .map((e) => PlatformStatus.fromJson(e as Map<String, dynamic>))
        .toList();
    return platforms;
  } catch (e) {
    debugPrint('[PlatformStatus] Failed to fetch: $e');
    rethrow;
  } finally {
    client?.close();
  }
});

// ──────────────────────────────────────────────
// Test connection for a specific platform
// ──────────────────────────────────────────────

/// Performs a POST /api/platforms/test/:name request.
/// Returns ConnectionTestResult.
Future<ConnectionTestResult> testPlatformConnection(String wsUrl, String platformName) async {
  final httpUrl = _toHttpUrl(wsUrl);
  HttpClient? client;
  try {
    client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    final uri = Uri.parse('$httpUrl/api/platforms/test/$platformName');
    final request = await client.postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.contentLength = 2;
    request.write('{}');
    final response = await request.close().timeout(const Duration(seconds: 15));
    final body = await response.transform(utf8.decoder).join();
    final parsed = jsonDecode(body) as Map<String, dynamic>;
    return ConnectionTestResult.fromJson(parsed);
  } catch (e) {
    return ConnectionTestResult(ok: false, latencyMs: 0, message: e.toString());
  } finally {
    client?.close();
  }
}

String _toHttpUrl(String wsUrl) {
  return wsUrl
      .replaceFirst(RegExp(r'^wss://'), 'https://')
      .replaceFirst(RegExp(r'^ws://'), 'http://');
}
