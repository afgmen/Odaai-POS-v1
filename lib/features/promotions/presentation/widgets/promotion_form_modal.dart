import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/database_providers.dart';
import '../../providers/promotions_provider.dart';

class PromotionFormModal extends ConsumerStatefulWidget {
  final Promotion? promotion;

  const PromotionFormModal({super.key, this.promotion});

  @override
  ConsumerState<PromotionFormModal> createState() => _PromotionFormModalState();
}

class _PromotionFormModalState extends ConsumerState<PromotionFormModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _valueController;

  String _selectedType = 'buy1get1';
  bool _applyToAllProducts = true; // B-082
  Set<int> _selectedProductIds = {}; // B-082
  DateTime? _startDate;
  DateTime? _endDate;

  bool get _isEdit => widget.promotion != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.promotion?.name ?? '');
    _valueController = TextEditingController(
      text: widget.promotion?.value.toString() ?? '',
    );
    _selectedType = widget.promotion?.type ?? 'buy1get1';
    _startDate = widget.promotion?.startDate;
    _endDate = widget.promotion?.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEdit ? l10n.editPromotion : l10n.addPromotion,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 프로모션 이름
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.promotionNameLabel,
                  hintText: l10n.promotionNameHint,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.promotionNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 프로모션 타입
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: InputDecoration(labelText: l10n.promotionTypeLabel),
                items: [
                  DropdownMenuItem(value: 'buy1get1', child: Text(l10n.typeBogo)),
                  DropdownMenuItem(value: 'buy2get1', child: Text(l10n.typeBuy2Get1)),
                  DropdownMenuItem(value: 'percentOff', child: Text(l10n.typePercentOff)),
                  DropdownMenuItem(value: 'amountOff', child: Text(l10n.typeAmountOff)),
                ],
                onChanged: (value) {
                  setState(() => _selectedType = value!);
                },
              ),
              const SizedBox(height: 20),

              // 할인 값 (percentOff, amountOff인 경우만 표시)
              if (_selectedType == 'percentOff' || _selectedType == 'amountOff') ...[
                TextFormField(
                  controller: _valueController,
                  decoration: InputDecoration(
                    labelText: _selectedType == 'percentOff' ? l10n.discountRateLabel : l10n.discountAmountLabel,
                    hintText: _selectedType == 'percentOff' ? l10n.discountValueHint : l10n.discountAmountHint,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.discountValueRequired;
                    }
                    final num = double.tryParse(value);
                    if (num == null || num <= 0) {
                      return l10n.invalidNumber;
                    }
                    if (_selectedType == 'percentOff' && num > 100) {
                      return l10n.maxDiscountRate;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
              ],

              // 적용 상품 선택 (B-082: 다중 선택)
              _ProductMultiSelector(
                applyToAllProducts: _applyToAllProducts,
                selectedProductIds: _selectedProductIds,
                onApplyToAllChanged: (value) => setState(() {
                  _applyToAllProducts = value;
                  if (value) _selectedProductIds.clear();
                }),
                onSelectedProductsChanged: (ids) => setState(() => _selectedProductIds = ids),
              ),
              const SizedBox(height: 20),

              // 시작일/종료일
              Row(
                children: [
                  Expanded(
                    child: _DatePickerField(
                      label: l10n.startDate,
                      date: _startDate,
                      onChanged: (date) => setState(() => _startDate = date),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DatePickerField(
                      label: l10n.endDate,
                      date: _endDate,
                      onChanged: (date) => setState(() => _endDate = date),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 저장 버튼
              ElevatedButton(
                onPressed: _savePromotion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(_isEdit ? l10n.edit : l10n.add, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePromotion() async {
    if (!_formKey.currentState!.validate()) return;

    // B-082: Validation - 특정 제품 선택 시 최소 1개 필요
    if (!_applyToAllProducts && _selectedProductIds.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one product'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final db = ref.read(databaseProvider);
    final name = _nameController.text.trim();
    final value = double.tryParse(_valueController.text.trim()) ?? 0.0;

    try {
      if (_isEdit) {
        // B-082: 수정 (제품 연결 포함)
        await db.promotionsDao.updatePromotionWithProducts(
          promotionId: widget.promotion!.id,
          promotion: PromotionsCompanion(
            name: Value(name),
            type: Value(_selectedType),
            value: Value(value),
            applyToAllProducts: Value(_applyToAllProducts),
            startDate: Value(_startDate),
            endDate: Value(_endDate),
            updatedAt: Value(DateTime.now()),
          ),
          applyToAll: _applyToAllProducts,
          productIds: _selectedProductIds.toList(),
        );
      } else {
        // B-082: 신규 추가 (제품 연결 포함)
        await db.promotionsDao.createPromotionWithProducts(
          promotion: PromotionsCompanion.insert(
            name: name,
            type: _selectedType,
            value: Value(value),
            applyToAllProducts: Value(_applyToAllProducts),
            startDate: Value(_startDate),
            endDate: Value(_endDate),
          ),
          applyToAll: _applyToAllProducts,
          productIds: _selectedProductIds.toList(),
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.msgError(e.toString())), backgroundColor: AppTheme.error),
        );
      }
    }
  }
}

/// B-082: 다중 상품 선택 위젯
class _ProductMultiSelector extends ConsumerWidget {
  final bool applyToAllProducts;
  final Set<int> selectedProductIds;
  final ValueChanged<bool> onApplyToAllChanged;
  final ValueChanged<Set<int>> onSelectedProductsChanged;

  const _ProductMultiSelector({
    required this.applyToAllProducts,
    required this.selectedProductIds,
    required this.onApplyToAllChanged,
    required this.onSelectedProductsChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final productsAsync = ref.watch(activeProductsProvider);

    return productsAsync.when(
      data: (products) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "모든 제품에 적용" 체크박스
            CheckboxListTile(
              title: Text(
                l10n.allProducts,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Automatically applied to all products'),
              value: applyToAllProducts,
              onChanged: (value) => onApplyToAllChanged(value ?? true),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            
            // 특정 제품 선택 (applyToAllProducts == false일 때만)
            if (!applyToAllProducts) ...[
              const SizedBox(height: 8),
              Text(
                'Select products to apply:',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              
              // 제품 목록 (체크박스)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: products.map((product) {
                    final isSelected = selectedProductIds.contains(product.id);
                    return CheckboxListTile(
                      title: Text(product.name),
                      value: isSelected,
                      onChanged: (checked) {
                        final newSet = Set<int>.from(selectedProductIds);
                        if (checked == true) {
                          newSet.add(product.id);
                        } else {
                          newSet.remove(product.id);
                        }
                        onSelectedProductsChanged(newSet);
                      },
                      dense: true,
                    );
                  }).toList(),
                ),
              ),
              
              // 선택된 제품 개수 표시
              if (selectedProductIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${selectedProductIds.length}개 제품 선택됨',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Text(l10n.productLoadFailed),
    );
  }
}

/// 날짜 선택 필드
class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fmt = DateFormat('yyyy-MM-dd');

    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: date != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                )
              : const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          date != null ? fmt.format(date!) : l10n.noSelection,
          style: TextStyle(
            fontSize: 14,
            color: date != null ? AppTheme.textPrimary : AppTheme.textDisabled,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      onChanged(picked);
    }
  }
}
