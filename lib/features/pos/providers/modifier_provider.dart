import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import '../../../providers/database_providers.dart';

/// Provider for all active modifier groups
final allModifierGroupsProvider = FutureProvider<List<ModifierGroup>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.modifierDao.getAllModifierGroups();
});

/// Provider for modifier groups linked to a specific product
final productModifierGroupsProvider = FutureProvider.family<List<ModifierGroup>, int>((ref, productId) {
  final db = ref.watch(databaseProvider);
  return db.modifierDao.getModifierGroupsForProduct(productId);
});

/// Provider for modifier options in a group
final modifierOptionsProvider = FutureProvider.family<List<ModifierOption>, int>((ref, groupId) {
  final db = ref.watch(databaseProvider);
  return db.modifierDao.getModifierOptionsForGroup(groupId);
});
