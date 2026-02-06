import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../providers/category_provider.dart';

/// 카테고리 필터 리스트 (세로 배치)
class CategoryFilter extends ConsumerWidget {
  const CategoryFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final selected = ref.watch(selectedCategoryProvider);

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
                // ─── "전체" 버튼 ─────────────────
                _CategoryButton(
                  label: '전체',
                  icon: Icons.apps_outlined,
                  isSelected: selected == null,
                  onTap: () => ref.read(selectedCategoryProvider.notifier).state = null,
                ),
                const Divider(height: 1, color: AppTheme.divider),
                // ─── 카테고리 목록 ─────────────
                ...categories.map((category) {
                  final isActive = selected == category;
                  return Column(
                    children: [
                      _CategoryButton(
                        label: category,
                        icon: _getCategoryIcon(category),
                        isSelected: isActive,
                        onTap: () => ref.read(selectedCategoryProvider.notifier).state = category,
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

IconData _getCategoryIcon(String category) {
  switch (category) {
    case '식품':
      return Icons.fastfood_outlined;
    case '전자제품':
      return Icons.devices_outlined;
    case '일용품':
      return Icons.home_outlined;
    case '음료':
      return Icons.local_cafe_outlined;
    default:
      return Icons.label_outlined;
  }
}
