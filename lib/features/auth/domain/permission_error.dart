/// Custom exception for permission-related errors
class PermissionError implements Exception {
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  PermissionError({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'PermissionError($code): $message';

  /// Factory constructors for common errors
  factory PermissionError.denied({
    required String permission,
    String? role,
  }) {
    return PermissionError(
      code: 'PERMISSION_DENIED',
      message: 'You do not have permission to perform this action',
      details: {
        'permission': permission,
        if (role != null) 'role': role,
      },
    );
  }

  factory PermissionError.invalidScope({
    required String storeId,
    required String scope,
  }) {
    return PermissionError(
      code: 'INVALID_SCOPE',
      message: 'You do not have access to this store',
      details: {
        'storeId': storeId,
        'scope': scope,
      },
    );
  }

  factory PermissionError.ownerModificationForbidden() {
    return PermissionError(
      code: 'OWNER_MODIFICATION_FORBIDDEN',
      message: 'Cannot modify Owner permissions',
    );
  }

  factory PermissionError.invalidRole(String role) {
    return PermissionError(
      code: 'INVALID_ROLE',
      message: 'Invalid role specified: $role',
      details: {'role': role},
    );
  }

  factory PermissionError.rbacDisabled() {
    return PermissionError(
      code: 'RBAC_DISABLED',
      message: 'RBAC system is disabled',
    );
  }

  factory PermissionError.notOwner() {
    return PermissionError(
      code: 'NOT_OWNER',
      message: 'Only Owner can perform this action',
    );
  }
}
