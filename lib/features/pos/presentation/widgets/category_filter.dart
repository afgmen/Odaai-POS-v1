import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/category_provider.dart';

/// 카테고리 필터 리스트 (세로 배치)
class CategoryFilter extends ConsumerWidget {
  const CategoryFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoryListProvider);
    final selectedCategoryId = ref.watch(selectedCategoryProvider);

    return categoriesAsync.when(
      data: (categories) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─── "All" button ─────────────────
                _CategoryButton(
                  label: l10n.categoryAll,
                  icon: Icons.apps_outlined,
                  isSelected: selectedCategoryId == null,
                  onTap: () {
                    ref.read(selectedCategoryProvider.notifier).state = null;
                    ref.read(searchQueryProvider.notifier).state = '';
                  },
                ),
                const Divider(height: 1, color: AppTheme.divider),
                // ─── Category list ─────────────
                ...categories.map((category) {
                  final isActive = selectedCategoryId == category.id;
                  return Column(
                    children: [
                      _CategoryButton(
                        label: _getLocalizedCategory(category.name, l10n),
                        icon: _getCategoryIcon(category.name),
                        isSelected: isActive,
                        onTap: () {
                          ref.read(selectedCategoryProvider.notifier).state = category.id;
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      ),
                      if (category != categories.last)
                        const Divider(height: 1, color: AppTheme.divider),
                    ],
                  );
                }),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(width: 120, child: Center(child: CircularProgressIndicator())),
      error: (err, _) => SizedBox(
        width: 120,
        child: Center(child: Text('Error: $err', style: TextStyle(fontSize: 12, color: AppTheme.error))),
      ),
    );
  }
}

/// 단일 카테고리 버튼
class _CategoryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F0FE) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppTheme.primary : AppTheme.iconColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _getLocalizedCategory(String category, AppLocalizations l10n) {
  // Return the category name as-is (user-defined categories are already in the correct language)
  return category;
}

IconData _getCategoryIcon(String category) {
  final lower = category.toLowerCase();
  if (lower.contains('food') || lower.contains('đồ ăn') || lower.contains('식품') || lower.contains('meal') || lower.contains('snack')) {
    return Icons.fastfood_outlined;
  }
  if (lower.contains('bev') || lower.contains('drink') || lower.contains('đồ uống') || lower.contains('음료') || lower.contains('coffee') || lower.contains('juice') || lower.contains('tea')) {
    return Icons.local_cafe_outlined;
  }
  if (lower.contains('alcohol') || lower.contains('beer') || lower.contains('wine') || lower.contains('bia') || lower.contains('rượu')) {
    return Icons.local_bar_outlined;
  }
  if (lower.contains('dessert') || lower.contains('cake') || lower.contains('sweet') || lower.contains('bánh')) {
    return Icons.cake_outlined;
  }
  if (lower.contains('electronic') || lower.contains('전자') || lower.contains('device')) {
    return Icons.devices_outlined;
  }
  if (lower.contains('daily') || lower.contains('일용') || lower.contains('household')) {
    return Icons.home_outlined;
  }
  return Icons.label_outlined;
}
