import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/permission.dart';
import '../../providers/permission_provider.dart';
import '../dialogs/manager_override_dialog.dart';

/// 권한 게이트 위젯
///
/// 자식 위젯에 권한 체크를 적용합니다.
/// 권한이 없으면 관리자 승인 다이얼로그를 표시합니다.
class PermissionGateWidget extends ConsumerWidget {
  final Permission permission;
  final Widget child;
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;
  final String? actionDescription;

  const PermissionGateWidget({
    super.key,
    required this.permission,
    required this.child,
    this.onPermissionGranted,
    this.onPermissionDenied,
    this.actionDescription,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermission = ref.watch(hasPermissionProvider(permission));

    // 권한이 있으면 원본 child 반환
    if (hasPermission) {
      return child;
    }

    // 권한이 없으면 터치 시 관리자 승인 요청
    return GestureDetector(
      onTap: () => _requestManagerOverride(context, ref),
      child: Opacity(
        opacity: 0.5,
        child: AbsorbPointer(
          child: child,
        ),
      ),
    );
  }

  Future<void> _requestManagerOverride(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // 관리자 승인 다이얼로그 표시
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => ManagerOverrideDialog(
        permission: permission,
        actionDescription:
            actionDescription ?? permission.description,
      ),
    );

    if (approved == true) {
      // 승인 성공
      if (onPermissionGranted != null) {
        onPermissionGranted!();
      }
    } else {
      // 승인 실패 또는 취소
      if (onPermissionDenied != null) {
        onPermissionDenied!();
      }
    }
  }
}

/// 권한 게이트 버튼
///
/// 권한이 없으면 비활성화되고, 탭 시 관리자 승인 다이얼로그를 표시합니다.
class PermissionGateButton extends ConsumerWidget {
  final Permission permission;
  final VoidCallback onPressed;
  final Widget child;
  final String? actionDescription;
  final ButtonStyle? style;

  const PermissionGateButton({
    super.key,
    required this.permission,
    required this.onPressed,
    required this.child,
    this.actionDescription,
    this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermission = ref.watch(hasPermissionProvider(permission));

    return ElevatedButton(
      onPressed: hasPermission
          ? onPressed
          : () => _requestManagerOverride(context, ref),
      style: style,
      child: child,
    );
  }

  Future<void> _requestManagerOverride(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => ManagerOverrideDialog(
        permission: permission,
        actionDescription:
            actionDescription ?? permission.description,
      ),
    );

    if (approved == true) {
      onPressed();
    }
  }
}

/// 권한에 따라 표시/숨김 처리
class PermissionVisibility extends ConsumerWidget {
  final Permission permission;
  final Widget child;
  final Widget? replacement;

  const PermissionVisibility({
    super.key,
    required this.permission,
    required this.child,
    this.replacement,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermission = ref.watch(hasPermissionProvider(permission));

    if (hasPermission) {
      return child;
    }

    return replacement ?? const SizedBox.shrink();
  }
}
