import '../models/listing.dart';

/// Base component for item recommendations.
abstract class ItemRecommendation {
  List<Listing> getItems();
}

/// Returns all items (base).
class AllItemsRecommendation implements ItemRecommendation {
  final List<Listing> items;
  AllItemsRecommendation(this.items);

  @override
  List<Listing> getItems() => items;
}

/// Decorator for filtering by user's most frequent categories.
class CategoryFilterDecorator implements ItemRecommendation {
  final ItemRecommendation base;
  final List<String> frequentCategories;

  CategoryFilterDecorator(this.base, this.frequentCategories);

  @override
  List<Listing> getItems() {
    return base.getItems().where((item) => frequentCategories.contains(item.category)).toList();
  }
}

/// Decorator for prioritizing newly uploaded items.
class NewItemPriorityDecorator implements ItemRecommendation {
  final ItemRecommendation base;
  final DateTime newThreshold;
  final Map<int, DateTime> itemUploadDates;

  NewItemPriorityDecorator(this.base, this.newThreshold, this.itemUploadDates);

  @override
  List<Listing> getItems() {
    final items = base.getItems();
    items.sort((a, b) {
      final aIsNew = itemUploadDates[a.id]?.isAfter(newThreshold) ?? false;
      final bIsNew = itemUploadDates[b.id]?.isAfter(newThreshold) ?? false;
      if (aIsNew && !bIsNew) return -1;
      if (!aIsNew && bIsNew) return 1;
      return 0;
    });
    return items;
  }

  /// Returns a map of category to count of new items.
  Map<String, int> countNewItemsPerCategory() {
    final items = base.getItems();
    final Map<String, int> counts = {};
    for (final item in items) {
      final isNew = itemUploadDates[item.id]?.isAfter(newThreshold) ?? false;
      if (isNew) {
        counts[item.category] = (counts[item.category] ?? 0) + 1;
      }
    }
    return counts;
  }
}
