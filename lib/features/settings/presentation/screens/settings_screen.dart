import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/currency.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/permission_gate_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/currency_provider.dart';
import '../../../../providers/locale_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/providers/rbac_providers.dart';
import 'security_settings_screen.dart';
import '../widgets/enable_rbac_button.dart';
import '../widgets/delivery_server_settings.dart';
import '../../../delivery/presentation/screens/delivery_platform_settings_screen.dart';
import '../../providers/store_settings_provider.dart';
import '../../../backup/domain/services/backup_service.dart';
import 'category_management_screen.dart';
import 'modifier_management_screen.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/utils/snackbar_helper.dart';

/// 설정 화면 — 언어, 통화, 매장 정보, 앱 정보 등
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLang = ref.watch(currentLanguageProvider);
    final currentCurrency = ref.watch(currencyProvider);
    final rbacEnabled = ref.watch(rbacSettingProvider);
    final storeSettings = ref.watch(storeSettingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(l10n.settings),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── RBAC Enable Button (Show if RBAC is not enabled) ──
          rbacEnabled.when(
            data: (enabled) => !enabled
                ? Column(
                    children: [
                      const EnableRbacButton(),
                      const SizedBox(height: 24),
                    ],
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // ─── Original sections below ──
          // ─── 언어 & 통화 섹션 ─────────────────────────
          _SectionHeader(title: l10n.localeSettings, icon: Icons.language),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _LanguageTile(
                label: l10n.settingsLanguage,
                currentLang: currentLang,
                onChanged: (lang) {
                  ref.read(localeProvider.notifier).setLocale(lang);
                },
              ),
              const Divider(height: 1),
              _CurrencyTile(
                label: l10n.settingsCurrency,
                currentCurrency: currentCurrency,
                onChanged: (currency) {
                  ref.read(currencyProvider.notifier).setCurrency(currency);
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ─── 매장 정보 섹션 ───────────────────────────
          _SectionHeader(
            title: l10n.storeInfo,
            icon: Icons.store,
          ),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _InfoTile(
                icon: Icons.storefront,
                label: l10n.storeName,
                value: storeSettings[StoreSettingsKeys.storeName] as String,
                onTap: () => _showEditDialog(
                  context,
                  ref,
                  title: l10n.storeName,
                  currentValue: storeSettings[StoreSettingsKeys.storeName] as String,
                  settingsKey: StoreSettingsKeys.storeName,
                ),
              ),
              const Divider(height: 1),
              _InfoTile(
                icon: Icons.phone,
                label: l10n.storePhone,
                value: (storeSettings[StoreSettingsKeys.storePhone] as String).isNotEmpty
                    ? storeSettings[StoreSettingsKeys.storePhone] as String
                    : '-',
                onTap: () => _showEditDialog(
                  context,
                  ref,
                  title: l10n.storePhone,
                  currentValue: storeSettings[StoreSettingsKeys.storePhone] as String,
                  settingsKey: StoreSettingsKeys.storePhone,
                ),
              ),
              const Divider(height: 1),
              _InfoTile(
                icon: Icons.location_on,
                label: l10n.storeAddress,
                value: (storeSettings[StoreSettingsKeys.storeAddress] as String).isNotEmpty
                    ? storeSettings[StoreSettingsKeys.storeAddress] as String
                    : '-',
                onTap: () => _showEditDialog(
                  context,
                  ref,
                  title: l10n.storeAddress,
                  currentValue: storeSettings[StoreSettingsKeys.storeAddress] as String,
                  settingsKey: StoreSettingsKeys.storeAddress,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ─── 상품 & 카테고리 섹션 ─────────────────────
          _SectionHeader(
            title: 'Product & Category',
            icon: Icons.inventory_2_outlined,
          ),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _InfoTile(
                icon: Icons.label_outlined,
                label: 'Category Management',
                value: 'Manage product categories',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoryManagementScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              _InfoTile(
                icon: Icons.tune,
                label: 'Modifier Management',
                value: 'Manage modifiers (toppings, options)',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ModifierManagementScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),


          // ─── Tax (VAT) 설정 섹션 ──────────────────────
          _SectionHeader(
            title: 'Tax (VAT) Settings',
            icon: Icons.receipt_long_outlined,
          ),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SwitchTile(
                icon: Icons.percent,
                label: 'Enable VAT',
                value: storeSettings[StoreSettingsKeys.taxEnabled] as bool? ?? true,
                onChanged: (val) {
                  ref.read(storeSettingsProvider.notifier).setBool(
                    StoreSettingsKeys.taxEnabled,
                    val,
                  );
                },
              ),
              const Divider(height: 1),
              _InfoTile(
                icon: Icons.calculate,
                label: 'VAT Rate (%)',
                value: '${(storeSettings[StoreSettingsKeys.taxRate] as double? ?? 10.0).toStringAsFixed(1)}%',
                onTap: () => _showTaxRateDialogHelper(context, ref, storeSettings[StoreSettingsKeys.taxRate] as double? ?? 10.0),
              ),
              const Divider(height: 1),
              _SwitchTile(
                icon: Icons.price_check,
                label: 'Tax Inclusive Pricing',
                value: storeSettings[StoreSettingsKeys.taxInclusive] as bool? ?? true,
                onChanged: (val) {
                  ref.read(storeSettingsProvider.notifier).setBool(
                    StoreSettingsKeys.taxInclusive,
                    val,
                  );
                },
              ),
            ],
          ),
          // ─── 영수증 설정 섹션 ─────────────────────────
          _SectionHeader(
            title: l10n.receiptSettings,
            icon: Icons.receipt_long,
          ),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _InfoTile(
                icon: Icons.message,
                label: l10n.footerMessage,
                value: (storeSettings[StoreSettingsKeys.receiptFooter] as String).isNotEmpty
                    ? storeSettings[StoreSettingsKeys.receiptFooter] as String
                    : l10n.footerDefault,
                onTap: () => _showEditDialog(
                  context,
                  ref,
                  title: l10n.footerMessage,
                  currentValue: (storeSettings[StoreSettingsKeys.receiptFooter] as String).isNotEmpty
                      ? storeSettings[StoreSettingsKeys.receiptFooter] as String
                      : l10n.footerDefault,
                  settingsKey: StoreSettingsKeys.receiptFooter,
                ),
              ),
              const Divider(height: 1),
              _SwitchTile(
                icon: Icons.qr_code,
                label: l10n.showQrCode,
                value: storeSettings[StoreSettingsKeys.showQrCode] as bool,
                onChanged: (val) {
                  ref.read(storeSettingsProvider.notifier).setBool(
                    StoreSettingsKeys.showQrCode,
                    val,
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ─── 보안 섹션 (Owner Only) ────────────────────
          OwnerOnly(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: 'Security',
                  icon: Icons.security,
                ),
                const SizedBox(height: 8),
                _SettingsCard(
                  children: [
                    _InfoTile(
                      icon: Icons.shield_outlined,
                      label: 'RBAC Settings',
                      value: 'Manage Permissions',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SecuritySettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // ─── Delivery Server 섹션 ─────────────────────
          _SectionHeader(
            title: l10n.deliveryConnectionStatus,
            icon: Icons.delivery_dining_outlined,
          ),
          const SizedBox(height: 8),
          _SettingsCard(
            children: const [
              DeliveryServerSettings(),
            ],
          ),

          const SizedBox(height: 24),

          // ─── Delivery Platforms 섹션 ──────────────────
          _SectionHeader(
            title: l10n.deliveryPlatformSettings,
            icon: Icons.storefront_outlined,
          ),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _InfoTile(
                icon: Icons.storefront_outlined,
                label: l10n.deliveryPlatformSettings,
                value: 'GrabFood, ShopeeFood',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DeliveryPlatformSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          const SizedBox(height: 24),

          // ─── 백업 & 복원 섹션 ─────────────────────────────
          _SectionHeader(
            title: 'Backup & Restore',
            icon: Icons.backup,
          ),
          const SizedBox(height: 8),
          _BackupRestoreCard(ref: ref),



          const SizedBox(height: 24),

          // ─── 환율 설정 섹션 ─────────────────────────────
          _SectionHeader(
            title: 'Exchange Rate Settings',
            icon: Icons.currency_exchange,
          ),
          const SizedBox(height: 8),
          _ExchangeRateCard(ref: ref),

          // ─── 앱 정보 섹션 ─────────────────────────────
          _SectionHeader(
            title: l10n.appInfo,
            icon: Icons.info_outline,
          ),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _InfoTile(
                icon: Icons.apps,
                label: l10n.version,
                value: 'v2.0.0',
              ),
              const Divider(height: 1),
              _InfoTile(
                icon: Icons.storage,
                label: l10n.database,
                value: 'SQLite v3',
              ),
              const Divider(height: 1),
              _InfoTile(
                icon: Icons.cloud_outlined,
                label: l10n.syncMode,
                value: l10n.offlineFirst,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ─── 로그아웃 버튼 ────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutConfirm(context, ref),
              icon: const Icon(Icons.logout, color: AppTheme.error),
              label: Text(
                l10n.logout,
                style: const TextStyle(color: AppTheme.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String currentValue,
    required String settingsKey,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: title,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(storeSettingsProvider.notifier).setString(
                settingsKey,
                controller.text,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$title saved'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // 세션 무효화 후 로그인 화면으로 돌아가기
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}

// ─── 공통 위젯 ───────────────────────────────────────────────

/// 섹션 헤더
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// 설정 카드 래퍼
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(children: children),
    );
  }
}

/// 언어 선택 타일
class _LanguageTile extends StatelessWidget {
  final String label;
  final AppLanguage currentLang;
  final ValueChanged<AppLanguage> onChanged;

  const _LanguageTile({
    required this.label,
    required this.currentLang,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.translate, color: AppTheme.primary),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(currentLang.nativeName),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: () => _showLanguagePicker(context),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            RadioGroup<AppLanguage>(
              groupValue: currentLang,
              onChanged: (val) {
                if (val != null) {
                  onChanged(val);
                  Navigator.pop(ctx);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: AppLanguage.values.map((lang) => RadioListTile<AppLanguage>(
                  title: Text(lang.nativeName),
                  subtitle: Text(_flagEmoji(lang, l10n)),
                  value: lang,
                  activeColor: AppTheme.primary,
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _flagEmoji(AppLanguage lang, AppLocalizations l10n) {
    switch (lang) {
      case AppLanguage.en:
        return '\u{1F1FA}\u{1F1F8} ${l10n.langEnglish}';
      case AppLanguage.vi:
        return '\u{1F1FB}\u{1F1F3} ${l10n.langVietnamese}';
    }
  }
}

/// 통화 선택 타일
class _CurrencyTile extends StatelessWidget {
  final String label;
  final AppCurrency currentCurrency;
  final ValueChanged<AppCurrency> onChanged;

  const _CurrencyTile({
    required this.label,
    required this.currentCurrency,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.monetization_on_outlined, color: AppTheme.primary),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text('${currentCurrency.symbol} ${currentCurrency.code}'),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: () => _showCurrencyPicker(context),
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            RadioGroup<AppCurrency>(
              groupValue: currentCurrency,
              onChanged: (val) {
                if (val != null) {
                  onChanged(val);
                  Navigator.pop(ctx);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: AppCurrency.values.map((currency) => RadioListTile<AppCurrency>(
                  title: Text('${currency.symbol} ${currency.code}'),
                  subtitle: Text(currency.name),
                  value: currency,
                  activeColor: AppTheme.primary,
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// 정보 표시 타일
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary, size: 22),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}

/// 스위치 타일
class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppTheme.textSecondary, size: 22),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      value: value,
      activeThumbColor: AppTheme.primary,
      onChanged: onChanged,
    );
  }
}

/// 백업 & 복원 카드
class _BackupRestoreCard extends StatelessWidget {
  final WidgetRef ref;

  const _BackupRestoreCard({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create Backup Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleCreateBackup(context, ref),
              icon: const Icon(Icons.backup),
              label: const Text('Create Backup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Restore Backup Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _handleRestoreBackup(context, ref),
              icon: const Icon(Icons.restore),
              label: const Text('Restore from Backup'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCreateBackup(BuildContext context, WidgetRef ref) async {
    try {
      final backupService = ref.read(backupServiceProvider);
      final currentEmployee = ref.read(currentEmployeeProvider);

      final result = await backupService.createBackup(
        type: BackupType.manual,
        employeeId: currentEmployee?.id,
      );

      if (context.mounted) {
        if (result.success && result.backupFile != null) {
          SnackBarHelper.showSuccess(
            context,
            'Backup created successfully!\nPath: ${result.backupFile!.path}',
          );
        } else {
          SnackBarHelper.showError(
            context,
            result.errorMessage ?? 'Backup failed',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showSanitizedError(context, e);
      }
    }
  }

  Future<void> _handleRestoreBackup(BuildContext context, WidgetRef ref) async {
    // 1. FilePicker로 백업 파일 선택
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db'],
      dialogTitle: 'Select Backup File',
    );

    if (result == null || result.files.single.path == null) {
      return; // User canceled
    }

    final filePath = result.files.single.path!;

    if (!context.mounted) return;

    // 2. 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: AppTheme.error),
            SizedBox(width: 8),
            Text('Warning'),
          ],
        ),
        content: const Text(
          'All current data will be overwritten with the backup data.\n\n'
          'This action cannot be undone.\n\n'
          'The app will need to restart after restoration.\n\n'
          'Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // 3. 복원 실행
    try {
      final backupService = ref.read(backupServiceProvider);
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Restoring backup...'),
                ],
              ),
            ),
          ),
        ),
      );

      final restoreResult = await backupService.restoreFromBackup(filePath);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (restoreResult.success) {
          SnackBarHelper.showSuccess(
            context,
            'Backup restored successfully!\nPlease restart the app.',
          );
        } else {
          SnackBarHelper.showError(
            context,
            restoreResult.errorMessage ?? 'Restore failed',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        SnackBarHelper.showSanitizedError(context, e);
      }
    }
  }
}

/// 환율 설정 카드
class _ExchangeRateCard extends StatefulWidget {
  final WidgetRef ref;

  const _ExchangeRateCard({required this.ref});

  @override
  State<_ExchangeRateCard> createState() => _ExchangeRateCardState();
}

class _ExchangeRateCardState extends State<_ExchangeRateCard> {
  final TextEditingController _usdToVndController = TextEditingController();
  double? _currentRate;

  @override
  void initState() {
    super.initState();
    _loadCurrentRate();
  }

  @override
  void dispose() {
    _usdToVndController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentRate() async {
    final service = widget.ref.read(exchangeRateServiceProvider);
    final rate = await service.getExchangeRate('VND', 'USD');
    
    setState(() {
      _currentRate = rate;
      if (rate != null) {
        // Display as "1 USD = X VND"
        final vndPerUsd = 1.0 / rate;
        _usdToVndController.text = vndPerUsd.toStringAsFixed(0);
      } else {
        // Default: 1 USD = 25,000 VND
        _usdToVndController.text = '25000';
      }
    });
  }

  Future<void> _saveExchangeRate() async {
    final input = _usdToVndController.text.trim();
    if (input.isEmpty) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Please enter exchange rate');
      }
      return;
    }

    final vndPerUsd = double.tryParse(input.replaceAll(',', ''));
    if (vndPerUsd == null || vndPerUsd <= 0) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Invalid exchange rate');
      }
      return;
    }

    // Convert to rate: VND → USD (e.g., 1 VND = 0.00004 USD)
    final rate = 1.0 / vndPerUsd;

    final service = widget.ref.read(exchangeRateServiceProvider);
    await service.saveExchangeRate('VND', 'USD', rate);

    setState(() {
      _currentRate = rate;
    });

    if (mounted) {
      SnackBarHelper.showSuccess(
        context,
        'Exchange rate saved: 1 USD = ${vndPerUsd.toStringAsFixed(0)} VND',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current rate display
          if (_currentRate != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Current: 1 USD = ${(1.0 / _currentRate!).toStringAsFixed(0)} VND',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          
          if (_currentRate != null) const SizedBox(height: 16),

          // Input field
          TextField(
            controller: _usdToVndController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '1 USD = ? VND',
              hintText: 'e.g., 25000',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          
          const SizedBox(height: 12),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveExchangeRate,
              icon: const Icon(Icons.save),
              label: const Text('Save Exchange Rate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Info text
          const Text(
            'Enter the exchange rate as VND per 1 USD.\nExample: 25000 means 1 USD = 25,000 VND',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

}

// Tax Rate Dialog Helper
void _showTaxRateDialogHelper(BuildContext context, WidgetRef ref, double currentRate) {
  final controller = TextEditingController(text: currentRate.toStringAsFixed(1));
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('VAT Rate (%)'),
      content: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Tax Rate (%)',
          hintText: 'e.g., 10.0',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final rate = double.tryParse(controller.text) ?? 10.0;
            await ref.read(storeSettingsProvider.notifier).setDouble(
              StoreSettingsKeys.taxRate,
              rate.clamp(0.0, 100.0),
            );
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
