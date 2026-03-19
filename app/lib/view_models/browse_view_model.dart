import 'package:flutter/foundation.dart';
import '../models/listing.dart';
import '../data/mock_data.dart';
import 'dart:collection';

import '../core/recommendation_service.dart';
import '../core/recommendation_system.dart';

class BrowseViewModel extends ChangeNotifier {
  List<Listing> _listings = List.from(MockData.browseListings);
  final Map<int, bool> _savedItems = {};
  String _search = '';
  String _category = 'All';
  String _size = 'All';
  String _condition = 'All';
  String _color = 'All';
  String _sort = 'newest';
  bool _aiSearch = false;
  bool _showFilters = false;

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

  // Track category interaction counts
  final Map<String, int> _categoryInteractionCounts = {};

  late RecommendationService _recommendationService;

  BrowseViewModel() {
    for (final l in _listings) {
      _savedItems[l.id] = l.saved;
    }
    // Initialize interaction counts
    for (final l in _listings) {
      _categoryInteractionCounts[l.category] = 0;
    }
    _updateRecommendationService();
  }

  void _updateRecommendationService() {
    // Sort categories by interaction count
    final sortedCategories = _categoryInteractionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final frequentCategories = sortedCategories.take(3).map((e) => e.key).toList();
    _recommendationService = RecommendationService(
      allItems: List.from(MockData.browseListings),
      userFrequentCategories: frequentCategories.isEmpty ? _categoryInteractionCounts.keys.toList() : frequentCategories,
      itemUploadDates: _itemUploadDates,
      newThreshold: DateTime.now().subtract(Duration(days: 5)), // Items uploaded in last 5 days
    );
    notifyListeners();
  }

  // User favorites an item
  void toggleSave(int itemId) {
    _savedItems[itemId] = !_savedItems[itemId]!;
    final item = _listings.firstWhere((l) => l.id == itemId);
    // Increment category interaction
    _categoryInteractionCounts[item.category] = (_categoryInteractionCounts[item.category] ?? 0) + 1;
    _updateRecommendationService();
    notifyListeners();
  }

  // User views an item
  void viewItem(int itemId) {
    final item = _listings.firstWhere((l) => l.id == itemId);
    _categoryInteractionCounts[item.category] = (_categoryInteractionCounts[item.category] ?? 0) + 1;
    _updateRecommendationService();
  }

  // 'For You' recommendations
  List<Listing> get forYouRecommendations => _recommendationService.getRecommendations();

  // New item counts per frequent category
  Map<String, int> get forYouNewItemCounts => _recommendationService.getNewItemCounts();

  String get search => _search;
  set search(String v) {
    _search = v;
    notifyListeners();
  }

  String get category => _category;
  set category(String v) {
    _category = v;
    notifyListeners();
  }

  String get size => _size;
  set size(String v) {
    _size = v;
    notifyListeners();
  }

  String get condition => _condition;
  set condition(String v) {
    _condition = v;
    notifyListeners();
  }

  String get color => _color;
  set color(String v) {
    _color = v;
    notifyListeners();
  }

  String get sort => _sort;
  set sort(String v) {
    _sort = v;
    notifyListeners();
  }
    Map<int, bool> get savedItems => _savedItems;

  bool get aiSearch => _aiSearch;
  set aiSearch(bool v) {
    _aiSearch = v;
    notifyListeners();
  }

  bool get showFilters => _showFilters;
  set showFilters(bool v) {
    _showFilters = v;
    notifyListeners();
  }

  bool isSaved(int id) => _savedItems[id] ?? false;

  void clearFilters() {
    _category = 'All';
    _size = 'All';
    _condition = 'All';
    _color = 'All';
    notifyListeners();
  }

  bool get hasFilters =>
      _category != 'All' ||
      _size != 'All' ||
      _condition != 'All' ||
      _color != 'All';

  List<Listing> get filteredAndSorted {
    var filtered =
        _listings
            .where((l) {
              final matchSearch = l.name.toLowerCase().contains(
                _search.toLowerCase(),
              );
              final matchCat = _category == 'All' || l.category == _category;
              final matchSize = _size == 'All' || l.size == _size;
              final matchCond =
                  _condition == 'All' || l.condition == _condition;
              final matchColor = _color == 'All' || l.color == _color;
              return matchSearch &&
                  matchCat &&
                  matchSize &&
                  matchCond &&
                  matchColor;
            })
            .map((l) => l.copyWith(saved: _savedItems[l.id] ?? l.saved))
            .toList();

    filtered.sort((a, b) {
      if (_sort == 'price-asc') return a.price.compareTo(b.price);
      if (_sort == 'price-desc') return b.price.compareTo(a.price);
      if (_sort == 'rating') return b.rating.compareTo(a.rating);
      return b.id.compareTo(a.id);
    });
    return filtered;
  }
}
