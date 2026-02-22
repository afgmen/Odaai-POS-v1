import '../../../../database/app_database.dart';

/// Converts the POS product list into the delivery middleware menu format.
///
/// Groups products by their `category` field. Products with `isActive = false`
/// or `stock <= 0` are marked as `available: false`.
class MenuBuilder {
  /// Build a menu payload from a flat list of POS [Product] rows.
  static Map<String, dynamic> buildFromProducts(List<Product> products) {
    // Group products by category (null category → "Uncategorised")
    final Map<String, List<Product>> grouped = {};
    for (final p in products) {
      final cat = p.category ?? 'Uncategorised';
      grouped.putIfAbsent(cat, () => []).add(p);
    }

    final categories = grouped.entries.map((entry) {
      final catName = entry.key;
      final items = entry.value.map(_buildItem).toList();

      return <String, dynamic>{
        'id': catName.toLowerCase().replaceAll(RegExp(r'\s+'), '_'),
        'name': catName,
        'items': items,
      };
    }).toList();

    return {'categories': categories};
  }

  static Map<String, dynamic> _buildItem(Product p) {
    // A product is available when it's active and has stock (or is a service)
    final available = p.isActive && p.stock > 0;

    return <String, dynamic>{
      'id': p.id.toString(),
      'name': p.name,
      'description': '',       // Products table has no description field
      'price': p.price,        // VND
      'available': available,
      'imageUrl': p.imageUrl,
    };
  }
}
