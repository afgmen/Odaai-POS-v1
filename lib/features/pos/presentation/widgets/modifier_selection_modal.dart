import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../providers/cart_provider.dart';
import '../../providers/modifier_provider.dart';

/// Modal for selecting modifiers when adding a product to cart
class ModifierSelectionModal extends ConsumerStatefulWidget {
  final Product product;
  final List<ModifierGroup> groups;

  const ModifierSelectionModal({
    super.key,
    required this.product,
    required this.groups,
  });

  @override
  ConsumerState<ModifierSelectionModal> createState() => _ModifierSelectionModalState();
}

class _ModifierSelectionModalState extends ConsumerState<ModifierSelectionModal> {
  // Map<groupId, Set<optionId>>
  final Map<int, Set<int>> _selections = {};
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select your options',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Modifier groups
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: widget.groups.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final group = widget.groups[index];
                return _buildModifierGroup(group);
              },
            ),
          ),
          
          // Error message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.error.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppTheme.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          
          // Add to cart button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Add to Cart - ${_calculateTotal().toStringAsFixed(0)}đ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModifierGroup(ModifierGroup group) {
    final optionsAsync = ref.watch(modifierOptionsProvider(group.id));

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    group.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (group.isRequired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Required',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Options
          optionsAsync.when(
            data: (options) {
              if (options.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No options available'),
                );
              }
              
              return Column(
                children: options.map((option) {
                  final isSelected = _selections[group.id]?.contains(option.id) ?? false;
                  
                  return InkWell(
                    onTap: () => _toggleOption(group, option),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: option == options.last ? Colors.transparent : Colors.grey.shade200,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Checkbox or Radio
                          if (group.allowMultiple)
                            Icon(
                              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                              color: isSelected ? AppTheme.primary : Colors.grey,
                            )
                          else
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: isSelected ? AppTheme.primary : Colors.grey,
                            ),
                          const SizedBox(width: 12),
                          
                          // Option name
                          Expanded(
                            child: Text(
                              option.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          
                          // Price adjustment
                          if (option.priceAdjustment != 0)
                            Text(
                              '${option.priceAdjustment > 0 ? '+' : ''}${option.priceAdjustment.toStringAsFixed(0)}đ',
                              style: TextStyle(
                                fontSize: 13,
                                color: option.priceAdjustment > 0 ? AppTheme.success : AppTheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Error: $error'),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleOption(ModifierGroup group, ModifierOption option) {
    setState(() {
      _errorMessage = null;
      
      if (group.allowMultiple) {
        // Multi-select
        final selected = _selections[group.id] ?? {};
        if (selected.contains(option.id)) {
          selected.remove(option.id);
        } else {
          if (selected.length < group.maxSelections) {
            selected.add(option.id);
          } else {
            _errorMessage = 'Maximum ${group.maxSelections} selections allowed for ${group.name}';
            return;
          }
        }
        _selections[group.id] = selected;
      } else {
        // Single-select
        _selections[group.id] = {option.id};
      }
    });
  }

  double _calculateTotal() {
    double total = widget.product.price;
    
    for (final groupId in _selections.keys) {
      for (final optionId in _selections[groupId]!) {
        // Find option price
        final optionsAsync = ref.read(modifierOptionsProvider(groupId));
        optionsAsync.whenData((options) {
          final option = options.firstWhere((o) => o.id == optionId, orElse: () => options.first);
          total += option.priceAdjustment;
        });
      }
    }
    
    return total;
  }

  Future<void> _addToCart() async {
    // Validate required groups
    for (final group in widget.groups) {
      if (group.isRequired) {
        final selected = _selections[group.id];
        if (selected == null || selected.isEmpty) {
          setState(() {
            _errorMessage = 'Please select an option for ${group.name}';
          });
          return;
        }
      }
    }

    // Build selected modifiers list
    final List<SelectedModifier> selectedModifiers = [];
    
    for (final groupId in _selections.keys) {
      final group = widget.groups.firstWhere((g) => g.id == groupId);
      final optionsAsync = ref.read(modifierOptionsProvider(groupId));
      
      await optionsAsync.when(
        data: (options) async {
          for (final optionId in _selections[groupId]!) {
            final option = options.firstWhere((o) => o.id == optionId);
            selectedModifiers.add(SelectedModifier(
              optionId: option.id,
              groupId: group.id,
              groupName: group.name,
              optionName: option.name,
              priceAdjustment: option.priceAdjustment,
            ));
          }
        },
        loading: () async {},
        error: (context, index) async {},
      );
    }

    // Add to cart
    ref.read(cartProvider.notifier).addItem(widget.product, modifiers: selectedModifiers);
    
    if (mounted) Navigator.pop(context);
  }
}
