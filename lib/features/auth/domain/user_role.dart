// ignore_for_file: constant_identifier_names

/// Legacy user role enum (pre-RBAC)
enum UserRole {
  /// Manager (full access)
  MANAGER,

  /// Cashier (limited access)
  CASHIER,

  /// Kitchen display only
  KITCHEN,
}

/// UserRole extension - string conversion and utilities
extension UserRoleExtension on UserRole {
  /// Role as database string
  String get value {
    switch (this) {
      case UserRole.MANAGER:
        return 'MANAGER';
      case UserRole.CASHIER:
        return 'CASHIER';
      case UserRole.KITCHEN:
        return 'KITCHEN';
    }
  }

  /// Display name
  String get displayName {
    switch (this) {
      case UserRole.MANAGER:
        return 'Manager';
      case UserRole.CASHIER:
        return 'Cashier';
      case UserRole.KITCHEN:
        return 'Kitchen';
    }
  }

  /// Create UserRole from string
  static UserRole fromString(String value) {
    switch (value.toUpperCase()) {
      case 'MANAGER':
        return UserRole.MANAGER;
      case 'CASHIER':
        return UserRole.CASHIER;
      case 'KITCHEN':
        return UserRole.KITCHEN;
      default:
        return UserRole.CASHIER;
    }
  }
}
