import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/currency.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/permission_gate_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/currency_provider.dart';
import '../../../../providers/locale_provider.dart';
import '../../../auth/domain/permission_modules.dart';
import '../../../auth/providers/rbac_providers.dart';
import 'security_settings_screen.dart';
import '../widgets/enable_rbac_button.dart';

/// 설정 화면 — 언어, 통화, 매장 정보, 앱 정보 등
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLang = ref.watch(currentLanguageProvider);
    final currentCurrency = ref.watch(currencyProvider);
    final rbacEnabled = ref.watch(rbacSettingProvider);
    final isOwner = ref.watch(isOwnerProvider);

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
            error: (_, __) => const SizedBox.shrink(),
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
                value: 'Oda POS',
                onTap: () => _showEditDialog(
                  context,
                  title: l10n.storeName,
                  currentValue: 'Oda POS',
                ),
              ),
              const Divider(height: 1),
              _InfoTile(
                icon: Icons.phone,
                label: l10n.storePhone,
                value: '-',
                onTap: () => _showEditDialog(
                  context,
                  title: l10n.storePhone,
                  currentValue: '',
                ),
              ),
              const Divider(height: 1),
              _InfoTile(
                icon: Icons.location_on,
                label: l10n.storeAddress,
                value: '-',
                onTap: () => _showEditDialog(
                  context,
                  title: l10n.storeAddress,
                  currentValue: '',
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

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
                value: l10n.footerDefault,
                onTap: () => _showEditDialog(
                  context,
                  title: l10n.footerMessage,
                  currentValue: l10n.footerDefault,
                ),
              ),
              const Divider(height: 1),
              _SwitchTile(
                icon: Icons.qr_code,
                label: l10n.showQrCode,
                value: false,
                onChanged: (val) {
                  // TODO: SharedPreferences에 저장
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
              onPressed: () => _showLogoutConfirm(context),
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

  void _showEditDialog(BuildContext context, {required String title, required String currentValue}) {
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
              // TODO: SharedPreferences에 저장
              Navigator.pop(ctx);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context) {
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
            onPressed: () {
              Navigator.pop(ctx);
              // 로그인 화면으로 돌아가기
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
            ...AppLanguage.values.map((lang) => RadioListTile<AppLanguage>(
              title: Text(lang.nativeName),
              subtitle: Text(_flagEmoji(lang, l10n)),
              value: lang,
              groupValue: currentLang,
              activeColor: AppTheme.primary,
              onChanged: (val) {
                if (val != null) {
                  onChanged(val);
                  Navigator.pop(ctx);
                }
              },
            )),
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
            ...AppCurrency.values.map((currency) => RadioListTile<AppCurrency>(
              title: Text('${currency.symbol} ${currency.code}'),
              subtitle: Text(currency.name),
              value: currency,
              groupValue: currentCurrency,
              activeColor: AppTheme.primary,
              onChanged: (val) {
                if (val != null) {
                  onChanged(val);
                  Navigator.pop(ctx);
                }
              },
            )),
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
      activeColor: AppTheme.primary,
      onChanged: onChanged,
    );
  }
}
