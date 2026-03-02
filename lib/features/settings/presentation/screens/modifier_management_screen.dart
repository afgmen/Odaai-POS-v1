import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../pos/providers/modifier_provider.dart';
import 'product_modifier_link_screen.dart';
import '../../../products/providers/products_management_provider.dart';

class ModifierManagementScreen extends ConsumerWidget {
  const ModifierManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(allModifierGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier Management'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(child: Text('No modifier groups'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Card(
                child: ListTile(
                  title: Text(group.name),
                  subtitle: Text('${group.isRequired ? "Required" : "Optional"}'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLinkDialog(context, ref),
        icon: const Icon(Icons.link),
        label: const Text('Link Products'),
      ),
    );
  }

  void _showLinkDialog(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.read(allProductsStreamProvider);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Product'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: productsAsync.when(
            data: (products) => ListView.builder(
              itemCount: products.length,
              itemBuilder: (_, i) => ListTile(
                title: Text(products[i].name),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductModifierLinkScreen(product: products[i]),
                    ),
                  );
                },
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ),
      ),
    );
  }
}
