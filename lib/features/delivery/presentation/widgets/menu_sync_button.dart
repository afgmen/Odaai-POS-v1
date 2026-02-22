import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/app_database.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/services/menu_builder.dart';
import '../../domain/services/menu_sync_provider.dart';

/// A button (+ inline status) that syncs the POS menu to delivery platforms.
///
/// Drop this anywhere you have access to the current [List<Product>].
/// Typically placed in the product management screen AppBar actions.
///
/// ```dart
/// MenuSyncButton(products: productsSnapshot)
/// ```
class MenuSyncButton extends ConsumerWidget {
  final List<Product> products;

  const MenuSyncButton({super.key, required this.products});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final syncState = ref.watch(menuSyncNotifierProvider);

    final isLoading = syncState is AsyncLoading;

    return Tooltip(
      message: l10n.menuSyncTitle,
      child: TextButton.icon(
        onPressed: isLoading ? null : () => _onPressed(context, ref, l10n),
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : _buildIcon(syncState),
        label: Text(
          isLoading ? l10n.menuSyncInProgress : l10n.menuSyncButton,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildIcon(AsyncValue<dynamic> state) {
    if (state is AsyncData && state.value != null) {
      final result = state.value;
      if (result?.allSucceeded == true) {
        return const Icon(Icons.cloud_done_outlined,
            color: Colors.green, size: 18);
      } else if (result?.success == true) {
        return const Icon(Icons.cloud_outlined,
            color: Colors.orange, size: 18);
      } else if (state is AsyncError || result?.success == false) {
        return const Icon(Icons.cloud_off_outlined,
            color: Colors.red, size: 18);
      }
    }
    return const Icon(Icons.cloud_upload_outlined, size: 18);
  }

  Future<void> _onPressed(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final menuData = MenuBuilder.buildFromProducts(products);
    await ref.read(menuSyncNotifierProvider.notifier).sync(menuData);

    if (!context.mounted) return;

    final state = ref.read(menuSyncNotifierProvider);
    state.when(
      data: (result) {
        if (result == null) return;
        final message = result.allSucceeded
            ? l10n.menuSyncSuccess
            : result.success
                ? '${l10n.menuSyncSuccess} (partial)'
                : l10n.menuSyncFailed;
        final color = result.success ? Colors.green : Colors.red;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      },
      error: (err, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.menuSyncFailed}: $err'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      },
      loading: () {},
    );
  }
}
