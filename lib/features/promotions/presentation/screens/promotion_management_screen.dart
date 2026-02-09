import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/promotions_provider.dart';
import '../widgets/promotion_form_modal.dart';

class PromotionManagementScreen extends ConsumerWidget {
  const PromotionManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final promotionsAsync = ref.watch(allPromotionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_offer, size: 28, color: AppTheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        l10n.promotionManagement,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showPromotionForm(context, ref, null),
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(l10n.addPromotion),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 프로모션 목록
              Expanded(
                child: promotionsAsync.when(
                  data: (promotions) {
                    if (promotions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_offer_outlined, size: 64, color: AppTheme.textDisabled),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noPromotions,
                              style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 400,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: promotions.length,
                      itemBuilder: (context, index) {
                        final promotion = promotions[index];
                        return _PromotionCard(
                          promotion: promotion,
                          onEdit: () => _showPromotionForm(context, ref, promotion),
                          onToggle: () => _togglePromotion(ref, promotion),
                          onDelete: () => _deletePromotion(context, ref, promotion),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text(l10n.msgError(error.toString()), style: TextStyle(color: AppTheme.error)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPromotionForm(BuildContext context, WidgetRef ref, Promotion? promotion) {
    showDialog(
      context: context,
      builder: (_) => PromotionFormModal(promotion: promotion),
    );
  }

  Future<void> _togglePromotion(WidgetRef ref, Promotion promotion) async {
    final service = ref.read(promotionServiceProvider);
    await service.toggleActive(promotion.id, !promotion.isActive);
  }

  Future<void> _deletePromotion(BuildContext context, WidgetRef ref, Promotion promotion) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePromotion),
        content: Text(l10n.deletePromotionConfirm(promotion.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = ref.read(promotionServiceProvider);
      await service.deletePromotion(promotion.id);
    }
  }
}

/// 프로모션 카드
class _PromotionCard extends StatelessWidget {
  final Promotion promotion;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _PromotionCard({
    required this.promotion,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final typeLabel = _getTypeLabel(l10n, promotion.type);
    final valueText = _getValueText(l10n, promotion.type, promotion.value);
    final dateText = _getDateRangeText(promotion.startDate, promotion.endDate);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: promotion.isActive ? AppTheme.primary.withOpacity(0.3) : AppTheme.divider,
          width: promotion.isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 아이콘
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: promotion.isActive
                    ? AppTheme.primary.withOpacity(0.1)
                    : AppTheme.textDisabled.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.local_offer,
                size: 24,
                color: promotion.isActive ? AppTheme.primary : AppTheme.textDisabled,
              ),
            ),
            const SizedBox(width: 12),

            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          promotion.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: promotion.isActive ? AppTheme.success : AppTheme.textDisabled,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          promotion.isActive ? l10n.active : l10n.inactive,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.style, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        typeLabel,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.discount, size: 14, color: AppTheme.error),
                      const SizedBox(width: 2),
                      Text(
                        valueText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.error,
                        ),
                      ),
                    ],
                  ),
                  if (dateText != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: AppTheme.textDisabled),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            dateText,
                            style: TextStyle(fontSize: 11, color: AppTheme.textDisabled),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // 액션 버튼
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20, color: AppTheme.textSecondary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                    break;
                  case 'toggle':
                    onToggle();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return [
                  PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(promotion.isActive ? l10n.deactivate : l10n.activate),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(l10n.delete, style: const TextStyle(color: AppTheme.error)),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(AppLocalizations l10n, String type) {
    switch (type) {
      case 'buy1get1':
        return l10n.bogoLabel;
      case 'buy2get1':
        return l10n.buy2Get1Label;
      case 'percentOff':
        return l10n.percentOffLabel;
      case 'amountOff':
        return l10n.amountOffLabel;
      default:
        return type;
    }
  }

  String _getValueText(AppLocalizations l10n, String type, double value) {
    switch (type) {
      case 'buy1get1':
        return l10n.freeOne;
      case 'buy2get1':
        return l10n.freeOne;
      case 'percentOff':
        return '${value.toInt()}% OFF';
      case 'amountOff':
        return '₩${value.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} OFF';
      default:
        return value.toString();
    }
  }

  String? _getDateRangeText(DateTime? start, DateTime? end) {
    final fmt = DateFormat('yyyy-MM-dd');
    if (start != null && end != null) {
      return '${fmt.format(start)} ~ ${fmt.format(end)}';
    } else if (start != null) {
      return '${fmt.format(start)} ~';
    } else if (end != null) {
      return '~ ${fmt.format(end)}';
    }
    return null;
  }
}
