import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/sync_provider.dart';
import '../../services/sync_service.dart';

/// 동기화 상태 아이콘 + 뱃지 (AppBar 등에 표시)
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStatusProvider);
    final isOnline = ref.watch(connectivityProvider).value ?? false;

    return GestureDetector(
      onTap: () => _showSyncDetail(context, ref, syncState, isOnline),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 아이콘
            Icon(
              _statusIcon(syncState.status, isOnline),
              size: 22,
              color: _statusColor(syncState.status, isOnline),
            ),
            // 대기 뱃지
            if (syncState.pendingCount > 0)
              Positioned(
                right: -6,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 14),
                  child: Text(
                    '${syncState.pendingCount}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(SyncStatus status, bool isOnline) {
    if (!isOnline) return Icons.cloud_off;
    return switch (status) {
      SyncStatus.idle => Icons.cloud_done,
      SyncStatus.syncing => Icons.cloud_upload,
      SyncStatus.success => Icons.cloud_done,
      SyncStatus.error => Icons.cloud_off,
      SyncStatus.offline => Icons.cloud_off,
    };
  }

  Color _statusColor(SyncStatus status, bool isOnline) {
    if (!isOnline) return AppTheme.textDisabled;
    return switch (status) {
      SyncStatus.idle => AppTheme.success,
      SyncStatus.syncing => AppTheme.primary,
      SyncStatus.success => AppTheme.success,
      SyncStatus.error => AppTheme.error,
      SyncStatus.offline => AppTheme.textDisabled,
    };
  }

  void _showSyncDetail(BuildContext context, WidgetRef ref, SyncState syncState, bool isOnline) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SyncDetailSheet(
        syncState: syncState,
        isOnline: isOnline,
        l10n: l10n,
        onSync: () {
          Navigator.of(context).pop();
          ref.read(syncStatusProvider.notifier).syncNow();
        },
      ),
    );
  }
}

/// 동기화 상세 정보 시트
class _SyncDetailSheet extends StatelessWidget {
  final SyncState syncState;
  final bool isOnline;
  final AppLocalizations l10n;
  final VoidCallback onSync;

  const _SyncDetailSheet({
    required this.syncState,
    required this.isOnline,
    required this.l10n,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.syncStatus,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 22, color: AppTheme.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 연결 상태
            _InfoRow(
              icon: isOnline ? Icons.wifi : Icons.wifi_off,
              iconColor: isOnline ? AppTheme.success : AppTheme.error,
              label: l10n.network,
              value: isOnline ? l10n.connected : l10n.offline,
            ),
            const SizedBox(height: 12),

            // 대기 항목
            _InfoRow(
              icon: Icons.pending_actions,
              iconColor: syncState.pendingCount > 0 ? AppTheme.warning : AppTheme.success,
              label: l10n.pendingItems,
              value: l10n.pendingCount(syncState.pendingCount),
            ),
            const SizedBox(height: 12),

            // 마지막 동기화
            _InfoRow(
              icon: Icons.access_time,
              iconColor: AppTheme.textSecondary,
              label: l10n.lastSync,
              value: syncState.lastSyncedAt != null
                  ? _formatDateTime(syncState.lastSyncedAt!)
                  : l10n.notYet,
            ),

            // 에러 표시
            if (syncState.lastError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDEBEB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 18, color: AppTheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        syncState.lastError!,
                        style: const TextStyle(fontSize: 13, color: AppTheme.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 동기화 버튼
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: isOnline && syncState.status != SyncStatus.syncing ? onSync : null,
                icon: syncState.status == SyncStatus.syncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.sync, size: 20),
                label: Text(
                  syncState.status == SyncStatus.syncing ? l10n.syncing : l10n.syncNow,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor: AppTheme.textDisabled,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 안내 텍스트
            Text(
              isOnline
                  ? l10n.syncAutoMsg
                  : l10n.syncOfflineMsg,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);

    return '${dt.month}/${dt.day} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// 정보 행 위젯
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
