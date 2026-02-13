import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../domain/session.dart';

/// 현재 로그인한 직원 표시 배지
class SessionBadge extends ConsumerWidget {
  final VoidCallback? onLogout;

  const SessionBadge({
    super.key,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionProvider);

    if (session == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getRoleColor(session).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getRoleColor(session).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 역할 아이콘
          Icon(
            _getRoleIcon(session),
            size: 16,
            color: _getRoleColor(session),
          ),
          const SizedBox(width: 8),

          // 직원 이름 및 역할
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                session.employeeName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getRoleColor(session),
                ),
              ),
              Text(
                session.role.displayName,
                style: TextStyle(
                  fontSize: 10,
                  color: _getRoleColor(session).withOpacity(0.7),
                ),
              ),
            ],
          ),

          // 로그아웃 버튼
          if (onLogout != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.logout, size: 16),
              onPressed: onLogout,
              tooltip: '로그아웃',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  Color _getRoleColor(Session session) {
    switch (session.role) {
      case UserRole.MANAGER:
        return Colors.purple;
      case UserRole.CASHIER:
        return Colors.blue;
      case UserRole.KITCHEN:
        return Colors.green;
    }
  }

  IconData _getRoleIcon(Session session) {
    switch (session.role) {
      case UserRole.MANAGER:
        return Icons.admin_panel_settings;
      case UserRole.CASHIER:
        return Icons.person;
      case UserRole.KITCHEN:
        return Icons.restaurant;
    }
  }
}

/// 세션 상태 표시 (간단한 버전)
class SessionStatusIndicator extends ConsumerWidget {
  const SessionStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final session = ref.watch(currentSessionProvider);

    if (!isAuthenticated || session == null) {
      return Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red,
        ),
      );
    }

    // 세션 만료 임박 확인
    final isExpiringSoon = session.expiresAt
        .difference(DateTime.now())
        .inMinutes < 60;

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isExpiringSoon ? Colors.orange : Colors.green,
      ),
    );
  }
}
