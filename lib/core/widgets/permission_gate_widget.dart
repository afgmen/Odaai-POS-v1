import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/rbac_providers.dart';

/// Widget that conditionally renders children based on permission
///
/// Usage:
/// ```dart
/// PermissionGateWidget(
///   permission: 'revenue.daily.view',
///   storeId: currentStoreId,
///   child: DailyRevenueCard(),
///   fallback: AccessDeniedCard(),
/// )
/// ```
class PermissionGateWidget extends ConsumerWidget {
  final String permission;
  final String? storeId;
  final Widget child;
  final Widget? fallback;

  const PermissionGateWidget({
    super.key,
    required this.permission,
    this.storeId,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermission = ref.watch(
      hasPermissionProvider((permission: permission, storeId: storeId)),
    );

    return hasPermission.when(
      data: (allowed) => allowed ? child : (fallback ?? const SizedBox.shrink()),
      loading: () => fallback ?? const SizedBox.shrink(),
      error: (_, __) => fallback ?? const SizedBox.shrink(),
    );
  }
}

/// Access Denied Card - shown when permission is denied
class AccessDeniedCard extends StatelessWidget {
  final String? message;

  const AccessDeniedCard({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message ?? '접근 권한이 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '이 기능을 사용하려면 관리자에게 문의하세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Permission Guard for hiding widgets
///
/// Usage:
/// ```dart
/// PermissionGuard(
///   permission: 'staff.manage',
///   child: ElevatedButton(
///     onPressed: () => ...,
///     child: Text('Manage Staff'),
///   ),
/// )
/// ```
class PermissionGuard extends ConsumerWidget {
  final String permission;
  final String? storeId;
  final Widget child;

  const PermissionGuard({
    super.key,
    required this.permission,
    this.storeId,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermission = ref.watch(
      hasPermissionProvider((permission: permission, storeId: storeId)),
    );

    return hasPermission.when(
      data: (allowed) => allowed ? child : const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Permission-based button disabler
///
/// Usage:
/// ```dart
/// PermissionButton(
///   permission: 'order.cancel',
///   onPressed: () => cancelOrder(),
///   child: Text('Cancel Order'),
/// )
/// ```
class PermissionButton extends ConsumerWidget {
  final String permission;
  final String? storeId;
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  const PermissionButton({
    super.key,
    required this.permission,
    this.storeId,
    required this.onPressed,
    required this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermission = ref.watch(
      hasPermissionProvider((permission: permission, storeId: storeId)),
    );

    return hasPermission.when(
      data: (allowed) => ElevatedButton(
        onPressed: allowed ? onPressed : null,
        style: style,
        child: child,
      ),
      loading: () => ElevatedButton(
        onPressed: null,
        style: style,
        child: child,
      ),
      error: (_, __) => ElevatedButton(
        onPressed: null,
        style: style,
        child: child,
      ),
    );
  }
}

/// Owner-only widget wrapper
///
/// Usage:
/// ```dart
/// OwnerOnly(
///   child: SettingsButton(),
///   fallback: Text('권한 없음'),
/// )
/// ```
class OwnerOnly extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const OwnerOnly({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = ref.watch(isOwnerProvider);

    return isOwner.when(
      data: (allowed) => allowed ? child : (fallback ?? const SizedBox.shrink()),
      loading: () => fallback ?? const SizedBox.shrink(),
      error: (_, __) => fallback ?? const SizedBox.shrink(),
    );
  }
}
