import 'package:flutter/foundation.dart';
import '../models/listing.dart';
import '../data/listing_service.dart';

import '../core/recommendation_service.dart';
import '../core/recommendation_system.dart';
import 'package:string_similarity/string_similarity.dart';

class HomeViewModel extends ChangeNotifier {
  List<Listing> _featured = [];
  late ListingService _listingService;
  final Map<String, bool> _savedItems = {};

  final Map<String, DateTime> _itemUploadDates = {
    '1': DateTime.now().subtract(Duration(days: 2)),
    '2': DateTime.now().subtract(Duration(days: 10)),
    '3': DateTime.now().subtract(Duration(days: 1)),
    '4': DateTime.now().subtract(Duration(days: 5)),
    '5': DateTime.now().subtract(Duration(days: 3)),
    '6': DateTime.now().subtract(Duration(days: 7)),
    '7': DateTime.now().subtract(Duration(days: 4)),
    '8': DateTime.now().subtract(Duration(days: 2)),
    '9': DateTime.now().subtract(Duration(days: 8)),
  };



  List<String> get _userFavoriteTags {
    final tagCount = <String, int>{};
    for (final l in _featured) {
      final isSaved = _savedItems[l.id] ?? l.saved;
      if (isSaved) {
        for (final tag in l.tags) {
          if (tag.trim().isEmpty) continue;
          tagCount[tag] = (tagCount[tag] ?? 0) + 1;
        }
      }
    }
    final sorted = tagCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).take(5).toList();
  }

  late RecommendationService _recommendationService;

  HomeViewModel() {
    _listingService = ListingService();
    _listingService.getListings().listen((listings) {
      _featured = listings;
      for (final l in _featured) {
        _savedItems[l.id] = l.saved;
      }
      _recommendationService = RecommendationService(
        allItems: listings,
        userFrequentCategories: _userFavoriteTags,
        itemUploadDates: _itemUploadDates,
        newThreshold: DateTime.now().subtract(Duration(days: 5)),
      );
      notifyListeners();
    });
  }

  List<Listing> get featured =>
      _featured.map((l) => l.copyWith(saved: _savedItems[l.id] ?? l.saved)).toList();


  List<Listing> get recommendations {
    final favoriteIds = _savedItems.entries.where((e) => e.value).map((e) => e.key).toSet();
    final favoriteListings = _featured.where((l) => favoriteIds.contains(l.id)).toList();

    final favoriteTags = <String>{};
    for (final fav in favoriteListings) {
      favoriteTags.addAll(fav.tags.where((t) => t.trim().isNotEmpty));
    }

    const double similarityThreshold = 0.6;
    final similarListings = _featured.where((l) {
      if (favoriteIds.contains(l.id)) return false; 
      for (final tag in l.tags) {
        for (final favTag in favoriteTags) {
          final similarity = StringSimilarity.compareTwoStrings(
            tag.toLowerCase(), favTag.toLowerCase());
          if (similarity >= similarityThreshold) {
            return true;
          }
        }
      }
      return false;
    }).toList();


    final allForYou = [...favoriteListings, ...similarListings];


    return allForYou;
  }

  // Get count of new items per frequent tag
  Map<String, int> get newItemCounts {
    _recommendationService = RecommendationService(
      allItems: _featured,
      userFrequentCategories: _userFavoriteTags,
      itemUploadDates: _itemUploadDates,
      newThreshold: DateTime.now().subtract(Duration(days: 5)),
    );
    return _recommendationService.getNewItemCounts();
  }

  bool isSaved(String id) => _savedItems[id] ?? false;

  void toggleSave(String id) {
    _savedItems[id] = !(_savedItems[id] ?? false);
    notifyListeners();
  }
}
