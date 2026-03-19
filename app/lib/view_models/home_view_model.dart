import 'package:flutter/foundation.dart';
import '../models/listing.dart';
import '../data/mock_data.dart';

import '../core/recommendation_service.dart';
import '../core/recommendation_system.dart';

class HomeViewModel extends ChangeNotifier {
  List<Listing> _featured = List.from(MockData.featuredListings);
  final Map<int, bool> _savedItems = {};

  // Sample upload dates for demonstration
  final Map<int, DateTime> _itemUploadDates = {
    1: DateTime.now().subtract(Duration(days: 2)),
    2: DateTime.now().subtract(Duration(days: 10)),
    3: DateTime.now().subtract(Duration(days: 1)),
    4: DateTime.now().subtract(Duration(days: 5)),
    5: DateTime.now().subtract(Duration(days: 3)),
    6: DateTime.now().subtract(Duration(days: 7)),
    7: DateTime.now().subtract(Duration(days: 4)),
    8: DateTime.now().subtract(Duration(days: 2)),
    9: DateTime.now().subtract(Duration(days: 8)),
  };

  // Example: User's most frequent categories
  final List<String> _userFrequentCategories = ["Jackets", "Tops", "Bottoms"];

  late RecommendationService _recommendationService;

  HomeViewModel() {
    for (final l in _featured) {
      _savedItems[l.id] = l.saved;
    }
    _recommendationService = RecommendationService(
      allItems: List.from(MockData.browseListings),
      userFrequentCategories: _userFrequentCategories,
      itemUploadDates: _itemUploadDates,
      newThreshold: DateTime.now().subtract(Duration(days: 5)), // Items uploaded in last 5 days
    );
  }

  List<Listing> get featured =>
      _featured
          .map((l) => l.copyWith(saved: _savedItems[l.id] ?? l.saved))
          .toList();

  // Get personalized recommendations
  List<Listing> get recommendations => _recommendationService.getRecommendations();

  // Get count of new items per frequent category
  Map<String, int> get newItemCounts => _recommendationService.getNewItemCounts();

  bool isSaved(int id) => _savedItems[id] ?? false;

  void toggleSave(int id) {
    _savedItems[id] = !(_savedItems[id] ?? false);
    notifyListeners();
  }
}
