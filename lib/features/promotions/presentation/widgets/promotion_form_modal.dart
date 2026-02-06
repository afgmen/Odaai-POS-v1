import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
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
  Product? _selectedProduct;
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
                    _isEdit ? '프로모션 수정' : '프로모션 추가',
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
                decoration: const InputDecoration(
                  labelText: '프로모션 이름',
                  hintText: '예: 오렌지주스 1+1',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '프로모션 이름을 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 프로모션 타입
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: '프로모션 타입'),
                items: const [
                  DropdownMenuItem(value: 'buy1get1', child: Text('1+1 이벤트 (1개 사면 1개 무료)')),
                  DropdownMenuItem(value: 'buy2get1', child: Text('2+1 이벤트 (2개 사면 1개 무료)')),
                  DropdownMenuItem(value: 'percentOff', child: Text('퍼센트 할인 (%)')),
                  DropdownMenuItem(value: 'amountOff', child: Text('금액 할인 (원)')),
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
                    labelText: _selectedType == 'percentOff' ? '할인율 (%)' : '할인 금액 (원)',
                    hintText: _selectedType == 'percentOff' ? '예: 10' : '예: 1000',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '할인 값을 입력하세요';
                    }
                    final num = double.tryParse(value);
                    if (num == null || num <= 0) {
                      return '올바른 숫자를 입력하세요';
                    }
                    if (_selectedType == 'percentOff' && num > 100) {
                      return '할인율은 100% 이하여야 합니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
              ],

              // 적용 상품 선택
              _ProductSelector(
                selectedProduct: _selectedProduct,
                onChanged: (product) => setState(() => _selectedProduct = product),
              ),
              const SizedBox(height: 20),

              // 시작일/종료일
              Row(
                children: [
                  Expanded(
                    child: _DatePickerField(
                      label: '시작일',
                      date: _startDate,
                      onChanged: (date) => setState(() => _startDate = date),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DatePickerField(
                      label: '종료일',
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
                child: Text(_isEdit ? '수정' : '추가', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePromotion() async {
    if (!_formKey.currentState!.validate()) return;

    final service = ref.read(promotionServiceProvider);
    final name = _nameController.text.trim();
    final value = double.tryParse(_valueController.text.trim()) ?? 0.0;

    try {
      if (_isEdit) {
        // 수정
        final updated = widget.promotion!.copyWith(
          name: name,
          type: _selectedType,
          value: value,
          productId: Value(_selectedProduct?.id),
          startDate: Value(_startDate),
          endDate: Value(_endDate),
        );
        await service.updatePromotion(updated);
      } else {
        // 신규 추가
        await service.createPromotion(
          name: name,
          type: _selectedType,
          value: value,
          productId: _selectedProduct?.id,
          startDate: _startDate,
          endDate: _endDate,
        );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }
}

/// 상품 선택 위젯
class _ProductSelector extends ConsumerWidget {
  final Product? selectedProduct;
  final ValueChanged<Product?> onChanged;

  const _ProductSelector({
    required this.selectedProduct,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(activeProductsProvider);

    return productsAsync.when(
      data: (products) {
        return DropdownButtonFormField<Product?>(
          value: selectedProduct,
          decoration: const InputDecoration(
            labelText: '적용 상품 (선택사항)',
            hintText: '전체 상품',
          ),
          items: [
            const DropdownMenuItem<Product?>(value: null, child: Text('전체 상품')),
            ...products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))),
          ],
          onChanged: onChanged,
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const Text('상품 로드 실패'),
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
          date != null ? fmt.format(date!) : '선택 안 함',
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
