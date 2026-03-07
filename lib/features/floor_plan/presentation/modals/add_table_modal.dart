import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../database/app_database.dart';
import '../../../tables/data/tables_providers.dart';
import '../../data/floor_plan_providers.dart';
import 'package:drift/drift.dart' hide Column;

/// Add/Edit Table Modal for Floor Plan Designer
class AddTableModal extends ConsumerStatefulWidget {
  final RestaurantTable? existingTable;

  const AddTableModal({super.key, this.existingTable});

  @override
  ConsumerState<AddTableModal> createState() => _AddTableModalState();
}

class _AddTableModalState extends ConsumerState<AddTableModal> {
  late final TextEditingController _tableNumberController;
  late final TextEditingController _seatsController;
  String _selectedShape = 'square';
  int? _selectedZoneId;
  String? _tableNumberError;

  final List<Map<String, dynamic>> _shapes = [
    {'value': 'square', 'label': 'Square', 'icon': Icons.crop_square},
    {'value': 'circle', 'label': 'Circle', 'icon': Icons.circle_outlined},
    {'value': 'rectangle', 'label': 'Rectangle', 'icon': Icons.rectangle_outlined},
  ];

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tableNumberController = TextEditingController(
      text: widget.existingTable?.tableNumber ?? '',
    );
    _seatsController = TextEditingController(
      text: widget.existingTable?.seats.toString() ?? '4',
    );
    _selectedShape = widget.existingTable?.shape ?? 'square';
    _selectedZoneId = widget.existingTable?.zoneId;
  }

  @override
  void dispose() {
    _tableNumberController.dispose();
    _seatsController.dispose();
    super.dispose();
  }

  bool get _isEditMode => widget.existingTable != null;

  @override
  Widget build(BuildContext context) {
    final zonesAsync = ref.watch(allZonesStreamProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditMode ? 'Edit Table' : 'Add Table',
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

              // Table Number
              TextField(
                controller: _tableNumberController,
                decoration: InputDecoration(
                  labelText: 'Table Number *',
                  hintText: 'e.g. T-01, A1, 12',
                  prefixIcon: const Icon(Icons.table_restaurant),
                  errorText: _tableNumberError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (_) {
                  // Clear error on change
                  if (_tableNumberError != null) {
                    setState(() => _tableNumberError = null);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Seats
              TextField(
                controller: _seatsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Seats *',
                  hintText: 'Number of seats',
                  prefixIcon: const Icon(Icons.event_seat),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Shape Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedShape,
                decoration: InputDecoration(
                  labelText: 'Shape',
                  prefixIcon: Icon(_shapes
                      .firstWhere((s) => s['value'] == _selectedShape)['icon']),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _shapes.map<DropdownMenuItem<String>>((shape) {
                  return DropdownMenuItem(
                    value: shape['value'],
                    child: Row(
                      children: [
                        Icon(shape['icon'], size: 20),
                        const SizedBox(width: 8),
                        Text(shape['label']),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedShape = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Zone Selection (Optional)
              zonesAsync.when(
                data: (zones) {
                  return DropdownButtonFormField<int?>(
                    initialValue: _selectedZoneId,
                    decoration: InputDecoration(
                      labelText: 'Zone (Optional)',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('No Zone'),
                      ),
                      ...zones.map((zone) {
                        return DropdownMenuItem(
                          value: zone.id,
                          child: Text(zone.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedZoneId = value);
                    },
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, _) => const Text('Error loading zones'),
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
    final tableNumber = _tableNumberController.text.trim();
    final seatsStr = _seatsController.text.trim();

    if (tableNumber.isEmpty) {
      SnackBarHelper.showError(context, 'Please enter table number');
      return;
    }

    final seats = int.tryParse(seatsStr);
    if (seats == null || seats < 1) {
      SnackBarHelper.showError(context, 'Please enter valid number of seats');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final tablesDao = ref.read(tablesDaoProvider);

      if (_isEditMode) {
        // Update existing table
        await tablesDao.updateTable(RestaurantTablesCompanion(
          id: Value(widget.existingTable!.id),
          tableNumber: Value(tableNumber),
          seats: Value(seats),
          shape: Value(_selectedShape),
          zoneId: Value(_selectedZoneId),
        ));

        if (mounted) {
          SnackBarHelper.showSuccess(context, 'Table updated successfully');
          Navigator.of(context).pop(true);
        }
      } else {
        // Create new table
        await tablesDao.createTable(RestaurantTablesCompanion.insert(
          tableNumber: tableNumber,
          seats: Value(seats),
          shape: Value(_selectedShape),
          zoneId: Value(_selectedZoneId),
        ));

        if (mounted) {
          SnackBarHelper.showSuccess(context, 'Table created successfully');
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        final msg = _friendlyError(e);
        setState(() {
          _isProcessing = false;
          // Set error text for table number duplicate
          if (msg.contains('already exists')) {
            _tableNumberError = msg;
          }
        });
        SnackBarHelper.showError(context, msg);
      }
    }
  }

  /// SQLite 에러를 사용자 친화적인 메시지로 변환
  String _friendlyError(Object e) {
    final raw = e.toString();
    if (raw.contains('UNIQUE') && raw.contains('table_number')) {
      return 'Table number "${_tableNumberController.text.trim()}" already exists. Please use a different number.';
    }
    if (raw.contains('UNIQUE')) {
      return 'A duplicate value was detected. Please check your input.';
    }
    return 'An error occurred. Please try again.';
  }

  Future<void> _handleDelete() async {
    if (!_isEditMode) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Table?'),
        content: const Text('This will permanently remove this table.'),
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
      final tablesDao = ref.read(tablesDaoProvider);
      await tablesDao.softDeleteTable(widget.existingTable!.id);

      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Table deleted successfully');
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
