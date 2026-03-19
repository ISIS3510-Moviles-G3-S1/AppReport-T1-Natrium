import '../models/listing.dart';
import '../core/recommendation_system.dart';

/// Example usage for dynamic decorator combination.
/// This can be moved to a service or view model as needed.
class RecommendationService {
  final List<Listing> allItems;
  final List<String> userFrequentCategories;
  final Map<int, DateTime> itemUploadDates;
  final DateTime newThreshold;

  RecommendationService({
    required this.allItems,
    required this.userFrequentCategories,
    required this.itemUploadDates,
    required this.newThreshold,
  });

  /// Get personalized recommendations.
  List<Listing> getRecommendations() {
    ItemRecommendation base = AllItemsRecommendation(allItems);
    base = CategoryFilterDecorator(base, userFrequentCategories);
    base = NewItemPriorityDecorator(base, newThreshold, itemUploadDates);
    return base.getItems();
  }

  /// Get count of new items per frequent category.
  Map<String, int> getNewItemCounts() {
    ItemRecommendation base = AllItemsRecommendation(allItems);
    base = CategoryFilterDecorator(base, userFrequentCategories);
    final newDecorator = NewItemPriorityDecorator(base, newThreshold, itemUploadDates);
    return newDecorator.countNewItemsPerCategory();
  }
}
