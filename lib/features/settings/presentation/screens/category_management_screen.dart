import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/database_providers.dart';
import '../../../products/providers/category_provider.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(activeCategoriesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Category Management'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.label_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No categories found',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryCard(category: category);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context, ref),
        icon: const Icon(Icons.add),
        label: Text('Add Category'),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(
        onSave: (name, description) async {
          final db = ref.read(databaseProvider);
          await db.categoriesDao.createCategory(
            name: name,
            description: description,
          );
          ref.invalidate(activeCategoriesListProvider);
        },
      ),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  final Category category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
          child: Icon(Icons.label, color: AppTheme.primary),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: category.description != null
            ? Text(category.description!, maxLines: 2, overflow: TextOverflow.ellipsis)
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primary),
              onPressed: () => _showEditDialog(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.error),
              onPressed: () => _showDeleteConfirmation(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(
        initialName: category.name,
        initialDescription: category.description,
        onSave: (name, description) async {
          final db = ref.read(databaseProvider);
          await db.categoriesDao.updateCategory(
            id: category.id,
            name: name,
            description: description,
          );
          ref.invalidate(activeCategoriesListProvider);
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete this category?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await db.categoriesDao.deleteCategory(category.id);
              ref.invalidate(activeCategoriesListProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(l10n.delete, style: const TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final String? initialName;
  final String? initialDescription;
  final Future<void> Function(String name, String? description) onSave;

  const _CategoryDialog({
    this.initialName,
    this.initialDescription,
    required this.onSave,
  });

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.initialName != null;

    return AlertDialog(
      title: Text(isEdit ? ('Edit Category') : ('Add Category')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Category Name',
              border: const OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a category name'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onSave(name, _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
