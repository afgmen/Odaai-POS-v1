/// Search image result model
/// Used to display image candidates from AI search
class SearchImageResult {
  final String id;
  final String thumbUrl;
  final String regularUrl;
  final String description;
  final String source; // 'Unsplash' or 'Pexels'
  final String photographer;

  const SearchImageResult({
    required this.id,
    required this.thumbUrl,
    required this.regularUrl,
    required this.description,
    required this.source,
    required this.photographer,
  });
}

/// Batch process result model
class BatchProcessResult {
  final int total;
  final int success;
  final int failed;
  final List<String> failedProducts;

  const BatchProcessResult({
    required this.total,
    required this.success,
    required this.failed,
    required this.failedProducts,
  });

  double get successRate => total > 0 ? (success / total) * 100 : 0;
}
