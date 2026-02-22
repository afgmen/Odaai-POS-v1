/// Result of a menu sync operation against the delivery middleware.
class MenuSyncResult {
  /// True if at least one platform was synced successfully.
  final bool success;

  /// True if every requested platform succeeded.
  final bool allSucceeded;

  /// Per-platform results map  e.g. `{ 'grab': { 'success': true, ... } }`
  final Map<String, dynamic> platforms;

  /// Human-readable error message (only set on total failure).
  final String? errorMessage;

  const MenuSyncResult._({
    required this.success,
    required this.allSucceeded,
    required this.platforms,
    this.errorMessage,
  });

  factory MenuSyncResult.success(Map<String, dynamic> body) {
    return MenuSyncResult._(
      success: true,
      allSucceeded: true,
      platforms: _extractPlatforms(body),
    );
  }

  factory MenuSyncResult.partial(Map<String, dynamic> body) {
    return MenuSyncResult._(
      success: true,
      allSucceeded: false,
      platforms: _extractPlatforms(body),
    );
  }

  factory MenuSyncResult.failure(String message) {
    return MenuSyncResult._(
      success: false,
      allSucceeded: false,
      platforms: {},
      errorMessage: message,
    );
  }

  static Map<String, dynamic> _extractPlatforms(Map<String, dynamic> body) {
    final p = body['platforms'];
    if (p is Map) return Map<String, dynamic>.from(p);
    return {};
  }

  /// List of platform keys that failed.
  List<String> get failedPlatforms => platforms.entries
      .where((e) => (e.value as Map?)?['success'] != true)
      .map((e) => e.key)
      .toList();
}
