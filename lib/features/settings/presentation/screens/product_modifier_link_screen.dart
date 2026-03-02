import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/database_providers.dart';
import '../../../pos/providers/modifier_provider.dart';
import '../../../products/providers/products_management_provider.dart';

class ProductModifierLinkScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductModifierLinkScreen({super.key, required this.product});

  @override
  ConsumerState<ProductModifierLinkScreen> createState() => _ProductModifierLinkScreenState();
}

class _ProductModifierLinkScreenState extends ConsumerState<ProductModifierLinkScreen> {
  Set<int> _linkedGroupIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLinkedGroups();
  }

  Future<void> _loadLinkedGroups() async {
    final db = ref.read(databaseProvider);
    final links = await db.modifierDao.getProductModifierLinks(widget.product.id);
    setState(() {
      _linkedGroupIds = links.map((l) => l.modifierGroupId).toSet();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allGroupsAsync = ref.watch(allModifierGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Modifiers for ${widget.product.name}'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : allGroupsAsync.when(
              data: (groups) {
                if (groups.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.tune, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No modifier groups available',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Go back and create groups first'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final isLinked = _linkedGroupIds.contains(group.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: CheckboxListTile(
                        title: Text(
                          group.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${group.isRequired ? 'Required' : 'Optional'} • ${group.allowMultiple ? 'Multi-select' : 'Single-select'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        value: isLinked,
                        onChanged: (value) => _toggleLink(group.id, value ?? false),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
              ),
            ),
    );
  }

  Future<void> _toggleLink(int groupId, bool shouldLink) async {
    final db = ref.read(databaseProvider);

    if (shouldLink) {
      await db.modifierDao.linkProductToModifierGroup(widget.product.id, groupId);
    } else {
      await db.modifierDao.unlinkProductFromModifierGroup(widget.product.id, groupId);
    }

    setState(() {
      if (shouldLink) {
        _linkedGroupIds.add(groupId);
      } else {
        _linkedGroupIds.remove(groupId);
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(shouldLink ? 'Modifier group linked' : 'Modifier group unlinked'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }
}
