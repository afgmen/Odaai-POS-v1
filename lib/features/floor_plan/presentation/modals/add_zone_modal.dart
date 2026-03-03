import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../database/app_database.dart';
import '../../data/floor_plan_providers.dart';
import 'package:drift/drift.dart' hide Column;

/// Add/Edit Zone Modal for Floor Plan Designer
class AddZoneModal extends ConsumerStatefulWidget {
  final FloorZone? existingZone; // null = create mode, non-null = edit mode

  const AddZoneModal({super.key, this.existingZone});

  @override
  ConsumerState<AddZoneModal> createState() => _AddZoneModalState();
}

/// Zone 크기 프리셋
enum ZoneSize {
  small('Small', 200, 150, '1~7 tables'),
  medium('Medium', 350, 260, '8~15 tables'),
  large('Large', 500, 370, '16~25 tables'),
  custom('Custom', 0, 0, 'Set manually');

  final String label;
  final double width;
  final double height;
  final String description;

  const ZoneSize(this.label, this.width, this.height, this.description);
}

class _AddZoneModalState extends ConsumerState<AddZoneModal> {
  late final TextEditingController _nameController;
  late final TextEditingController _customWidthController;
  late final TextEditingController _customHeightController;

  String _selectedColor = '#4CAF50'; // Default green
  ZoneSize _selectedSize = ZoneSize.medium; // Default medium

  final List<String> _colorPresets = [
    '#4CAF50', // Green
    '#2196F3', // Blue
    '#FF9800', // Orange
    '#9C27B0', // Purple
    '#F44336', // Red
    '#00BCD4', // Cyan
    '#FFEB3B', // Yellow
    '#795548', // Brown
  ];

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingZone?.name ?? '',
    );
    _selectedColor = widget.existingZone?.colorHex ?? '#4CAF50';

    // 편집 모드: 기존 크기에 가장 가까운 프리셋 선택
    double existingW = widget.existingZone?.width ?? 350;
    double existingH = widget.existingZone?.height ?? 260;

    if (widget.existingZone != null) {
      if (existingW <= 275) {
        _selectedSize = ZoneSize.small;
      } else if (existingW <= 425) {
        _selectedSize = ZoneSize.medium;
      } else if (existingW <= 550) {
        _selectedSize = ZoneSize.large;
      } else {
        _selectedSize = ZoneSize.custom;
      }
    }

    _customWidthController = TextEditingController(
      text: _selectedSize == ZoneSize.custom
          ? existingW.toInt().toString()
          : '700',
    );
    _customHeightController = TextEditingController(
      text: _selectedSize == ZoneSize.custom
          ? existingH.toInt().toString()
          : '500',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customWidthController.dispose();
    _customHeightController.dispose();
    super.dispose();
  }

  bool get _isEditMode => widget.existingZone != null;
  bool get _isCustom => _selectedSize == ZoneSize.custom;

  /// 현재 선택된 크기 반환 (Custom이면 입력값 사용)
  ({double width, double height}) get _effectiveSize {
    if (_isCustom) {
      final w = double.tryParse(_customWidthController.text) ?? 700;
      final h = double.tryParse(_customHeightController.text) ?? 500;
      return (width: w.clamp(100, 2000), height: h.clamp(100, 2000));
    }
    return (width: _selectedSize.width, height: _selectedSize.height);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditMode ? 'Edit Zone' : 'Add Zone',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Zone Name
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Zone Name *',
                  hintText: 'e.g. Main Dining, VIP Area',
                  prefixIcon: const Icon(Icons.label_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Size Picker
              const Text(
                'Zone Size',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // S / M / L / Custom 버튼 행
              Row(
                children: ZoneSize.values.map((size) {
                  final isSelected = _selectedSize == size;
                  final isLast = size == ZoneSize.custom;

                  // 미니 박스 크기 (시각화용)
                  final boxW = size == ZoneSize.small
                      ? 24.0
                      : size == ZoneSize.medium
                          ? 34.0
                          : size == ZoneSize.large
                              ? 44.0
                              : 0.0; // Custom은 아이콘 사용
                  final boxH = size == ZoneSize.small
                      ? 18.0
                      : size == ZoneSize.medium
                          ? 25.0
                          : size == ZoneSize.large
                              ? 32.0
                              : 0.0;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedSize = size),
                      child: Container(
                        margin: EdgeInsets.only(right: isLast ? 0 : 8),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withValues(alpha: 0.1)
                              : Colors.grey.shade50,
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primary
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            // 시각화: Custom은 아이콘, 나머지는 크기 박스
                            if (size == ZoneSize.custom)
                              Icon(
                                Icons.tune,
                                size: 28,
                                color: isSelected
                                    ? AppTheme.primary
                                    : Colors.grey.shade400,
                              )
                            else
                              Container(
                                width: boxW,
                                height: boxH,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primary
                                          .withValues(alpha: 0.3)
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              size.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              size.description,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Custom 크기 입력 필드 (Custom 선택 시에만 표시)
              if (_isCustom) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Custom Size (px)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customWidthController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              decoration: InputDecoration(
                                labelText: 'Width',
                                suffixText: 'px',
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text('×',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey)),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _customHeightController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              decoration: InputDecoration(
                                labelText: 'Height',
                                suffixText: 'px',
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Canvas is 1000×700 px — max recommended: 950×650',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Color Picker
              const Text(
                'Zone Color',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colorPresets.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(
                            int.parse(color.substring(1), radix: 16) +
                                0xFF000000),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  if (_isEditMode) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing ? null : _handleDelete,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(color: AppTheme.error),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(_isEditMode ? 'Update' : 'Create'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      SnackBarHelper.showError(context, 'Please enter zone name');
      return;
    }

    // Custom 크기 유효성 검사
    if (_isCustom) {
      final w = double.tryParse(_customWidthController.text) ?? 0;
      final h = double.tryParse(_customHeightController.text) ?? 0;
      if (w < 100 || h < 100) {
        SnackBarHelper.showError(
            context, 'Custom size must be at least 100×100 px');
        return;
      }
    }

    setState(() => _isProcessing = true);

    try {
      final zoneDao = ref.read(floorZoneDaoProvider);
      final size = _effectiveSize;

      if (_isEditMode) {
        await zoneDao.updateZone(FloorZonesCompanion(
          id: Value(widget.existingZone!.id),
          name: Value(name),
          colorHex: Value(_selectedColor),
          width: Value(size.width),
          height: Value(size.height),
        ));

        if (mounted) {
          SnackBarHelper.showSuccess(context, 'Zone updated successfully');
          Navigator.of(context).pop(true);
        }
      } else {
        await zoneDao.createZone(FloorZonesCompanion.insert(
          name: name,
          colorHex: Value(_selectedColor),
          width: Value(size.width),
          height: Value(size.height),
        ));

        if (mounted) {
          SnackBarHelper.showSuccess(context, 'Zone created successfully');
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        SnackBarHelper.showError(context, 'Error: ${e.toString()}');
      }
    }
  }

  Future<void> _handleDelete() async {
    if (!_isEditMode) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Zone?'),
        content: const Text('This will remove the zone and all its elements.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      final zoneDao = ref.read(floorZoneDaoProvider);
      await zoneDao.deleteZone(widget.existingZone!.id);

      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Zone deleted successfully');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        SnackBarHelper.showError(context, 'Error: ${e.toString()}');
      }
    }
  }
}
