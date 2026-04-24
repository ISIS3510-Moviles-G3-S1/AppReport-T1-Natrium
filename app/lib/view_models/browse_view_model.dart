import 'package:string_similarity/string_similarity.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/analytics_event.dart';
import '../core/analytics_service.dart';
import '../models/listing.dart';
import '../data/listing_service.dart';
import '../data/meetup_transaction_service.dart';
import '../data/fyp_fav_relation_storage.dart';
import 'package:hive/hive.dart';
import '../core/lru_cache_service.dart';

import '../core/recommendation_service.dart';
import '../core/recommendation_system.dart';

class BrowseViewModel extends ChangeNotifier {
  final FypFavRelationStorage _favStorage = FypFavRelationStorage();
  List<Listing> _listings = [];
  List<Listing> _allListings = [];
  late ListingService _listingService;
  final MeetupTransactionService _meetupService = MeetupTransactionService();
  StreamSubscription<List<Listing>>? _listingsSub;
  StreamSubscription<Set<String>>? _confirmedSalesSub;
  Set<String> _confirmedListingIds = {};
  final Map<String, bool> _savedItems = {};
  String _search = '';
  String _category = 'All';
  String _size = 'All';
  String _condition = 'All';
  String _color = 'All';
  String _sort = 'newest';
  bool _aiSearch = false;
  bool _showFilters = false;
  List<String> _registeredStylePreferences = const ['Casual', 'Streetwear'];
  String _registeredSize = 'M';

  // Sample upload dates for demonstration
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

  // Track category interaction counts
  final Map<String, int> _categoryInteractionCounts = {};

  // NUEVO: Track de items vistos y comprados
  final Set<String> _viewedItemIds = {};
  final Set<String> _purchasedItemIds = {};

  late RecommendationService _recommendationService;

  final LruCacheService<String, dynamic> _memoryCache;
  final Box<dynamic> _localStorage;

  BrowseViewModel(this._memoryCache, this._localStorage);

  Future<void> cacheCatalogSnapshot(Map<String, dynamic> catalog) async {
    _memoryCache.save('catalog', catalog);
    await _localStorage.put('catalog_snapshot', catalog);
  }

  Map<String, dynamic>? getCachedCatalog() {
    return _memoryCache.retrieve('catalog') ??
        _localStorage.get('catalog_snapshot') as Map<String, dynamic>?;
  }

  Future<void> cacheRecommendationsSnapshot(Map<String, dynamic> recommendations) async {
    _memoryCache.save('recommendations', recommendations);
    await _localStorage.put('recommendations_snapshot', recommendations);
  }

  Map<String, dynamic>? getCachedRecommendations() {
    return _memoryCache.retrieve('recommendations') ??
        _localStorage.get('recommendations_snapshot') as Map<String, dynamic>?;
  }

  Future<void> persistCatalogAndRecommendations(Map<String, dynamic> catalog, Map<String, dynamic> recommendations) async {
    await cacheCatalogSnapshot(catalog);
    await cacheRecommendationsSnapshot(recommendations);
  }

  BrowseViewModel.init(this._memoryCache, this._localStorage) {
    _listingService = ListingService();
    _listenListings();
    _listenConfirmedSales();
    reloadFavoritesForCurrentUser();
  }

  Future<void> reloadFavoritesForCurrentUser() async {
    _savedItems.clear();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      notifyListeners();
      return;
    }
    final relations = await _favStorage.getRelationsByFavId(userId);
    for (final fypItemId in relations) {
      _savedItems[fypItemId] = true;
    }
    notifyListeners();
  }

  void _listenListings() {
    _listingsSub = _listingService.getListings().listen((listings) {
      _allListings = listings;
      _recomputeVisibleListings();
    });
  }

  void _listenConfirmedSales() {
    _confirmedSalesSub = _meetupService.watchConfirmedListingIds().listen((ids) {
      _confirmedListingIds = ids;
      _recomputeVisibleListings();
    });
  }

  void _recomputeVisibleListings() {
    _listings =
        _allListings
            .where((listing) => !listing.isSold)
            .where((listing) => !_confirmedListingIds.contains(listing.id))
            .toList();

    for (final l in _listings) {
      _savedItems[l.id] = l.saved;
      final cat = l.tags.isNotEmpty ? l.tags[0] : 'Other';
      _categoryInteractionCounts[cat] = (_categoryInteractionCounts[cat] ?? 0);
    }
    _updateRecommendationService();
    notifyListeners();
  }

  void _updateRecommendationService() {
    // Sort categories by interaction count
    final sortedCategories = _categoryInteractionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final frequentCategories = sortedCategories.take(3).map((e) => e.key).toList();
    _recommendationService = RecommendationService(
      allItems: List.from(_listings),
      userFrequentCategories: frequentCategories.isEmpty ? _categoryInteractionCounts.keys.toList() : frequentCategories,
      itemUploadDates: _itemUploadDates,
      newThreshold: DateTime.now().subtract(Duration(days: 5)), // Items uploaded in last 5 days
    );
    notifyListeners();
  }


  // User favorites an item
  Future<void> toggleSave(String itemId) async {
    _savedItems[itemId] = !_savedItems[itemId]!;
    final isNowSaved = _savedItems[itemId]!;
    final item = _listings.firstWhere((l) => l.id == itemId);
    final cat = item.tags.isNotEmpty ? item.tags[0] : 'Other';
    _categoryInteractionCounts[cat] = (_categoryInteractionCounts[cat] ?? 0) + 1;

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isNotEmpty) {
      if (isNowSaved) {
        // Guardar relación en Hive
        await _favStorage.addRelation(favId: userId, fypItemId: itemId);
        AnalyticsService.instance.track(
          AnalyticsEvent.userMeaningfulInteraction(
            userId: userId,
            interactionType: 'like',
            timestamp: DateTime.now().toUtc().toIso8601String(),
            category: cat,
          ),
        );
      } else {
        // Eliminar relación de Hive
        await _favStorage.removeRelation(favId: userId, fypItemId: itemId);
      }
    }

    _updateRecommendationService();
    notifyListeners();
  }

  // NUEVO: User views an item (para recomendaciones)
  void trackView(String itemId) {
    _viewedItemIds.add(itemId);
    final item = _listings.firstWhere((l) => l.id == itemId);
    final cat = item.tags.isNotEmpty ? item.tags[0] : 'Other';
    _categoryInteractionCounts[cat] = (_categoryInteractionCounts[cat] ?? 0) + 1;

    // Analytics: track view interaction
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isNotEmpty) {
      AnalyticsService.instance.track(
        AnalyticsEvent.userMeaningfulInteraction(
          userId: userId,
          interactionType: 'view',
          timestamp: DateTime.now().toUtc().toIso8601String(),
          category: cat,
        ),
      );
    }
    notifyListeners();
  }

  // NUEVO: User purchases an item (para recomendaciones)
  void trackPurchase(String itemId) {
    _purchasedItemIds.add(itemId);
    final item = _listings.firstWhere((l) => l.id == itemId);
    final cat = item.tags.isNotEmpty ? item.tags[0] : 'Other';
    _categoryInteractionCounts[cat] = (_categoryInteractionCounts[cat] ?? 0) + 1;

    // Analytics: track purchase interaction
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isNotEmpty) {
      AnalyticsService.instance.track(
        AnalyticsEvent.userMeaningfulInteraction(
          userId: userId,
          interactionType: 'buy',
          timestamp: DateTime.now().toUtc().toIso8601String(),
          category: cat,
        ),
      );
    }
    notifyListeners();
  }

  // User views an item
  void viewItem(String itemId) {
    final item = _listings.firstWhere((l) => l.id == itemId);
    final cat = item.tags.isNotEmpty ? item.tags[0] : 'Other';
    _categoryInteractionCounts[cat] = (_categoryInteractionCounts[cat] ?? 0) + 1;
    _updateRecommendationService();
  }


  // 'For You' recommendations (favorites + tag similarity)
  List<Listing> get forYouRecommendations {
    // 1. Get favorites, viewed, and purchased items
    final favoriteIds = _savedItems.entries.where((e) => e.value).map((e) => e.key).toSet();
    final allInteractedIds = <String>{}
      ..addAll(favoriteIds)
      ..addAll(_viewedItemIds)
      ..addAll(_purchasedItemIds);
    final interactedListings = _listings.where((l) => allInteractedIds.contains(l.id)).toList();

    // 2. Get all tags from items the user interacted with
    final interactedTags = <String>{};
    for (final item in interactedListings) {
      interactedTags.addAll(item.tags.where((t) => t.trim().isNotEmpty));
    }

    // LOG: Show interacted tags
    debugPrint('[ForYou] Interacted tags: ${interactedTags.join(", ")}');

    // 3. Include all items with at least one tag similar to the interacted tags (using string similarity)
    const double similarityThreshold = 0.6; // You can adjust this value
    final similarListings = _listings.where((l) {
      if (allInteractedIds.contains(l.id)) return false; // Do not include duplicates
      for (final tag in l.tags) {
        for (final interactedTag in interactedTags) {
          final similarity = StringSimilarity.compareTwoStrings(
            tag.toLowerCase(), interactedTag.toLowerCase());
          if (similarity >= similarityThreshold) {
            debugPrint('[ForYou] Similar: ${l.title} (tag: $tag) ~ $interactedTag (sim: $similarity)');
            return true;
          }
        }
      }
      return false;
    }).toList();

    // 4. Combine interacted and similar items, without duplicates
    final allForYou = [...interactedListings, ...similarListings];

    // LOG: Show how many items are recommended
    debugPrint('[ForYou] Total recommendations: ${allForYou.length}');

    return allForYou;
  }



  // New item counts per frequent category
  Map<String, int> get forYouNewItemCounts => _recommendationService.getNewItemCounts();

  List<String> get registeredStylePreferences => List.unmodifiable(_registeredStylePreferences);
  String get registeredSize => _registeredSize;

  void setRegisteredPreferences({
    required List<String> stylePreferences,
    required String size,
  }) {
    _registeredStylePreferences =
        stylePreferences.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);
    _registeredSize = _normalizeSize(size);
    notifyListeners();
  }

  String _normalizeSize(String input) {
    final normalized = input.trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'all') return '';
    if (normalized == 'one size' || normalized == 'onesize') return 'one size';
    return normalized;
  }

  String _extractListingSize(Listing listing) {
    final explicit = _normalizeSize(listing.size);
    if (explicit.isNotEmpty) return explicit;

    for (final rawTag in listing.tags) {
      final tag = _normalizeSize(rawTag);
      if (tag.isEmpty) continue;
      if (const {'xxs', 'xs', 's', 'm', 'l', 'xl', 'xxl', 'xxxl', 'one size'}.contains(tag)) {
        return tag;
      }
      if (tag.startsWith('size ')) {
        final candidate = _normalizeSize(tag.replaceFirst('size ', ''));
        if (candidate.isNotEmpty) return candidate;
      }
      if (tag.startsWith('talla ')) {
        final candidate = _normalizeSize(tag.replaceFirst('talla ', ''));
        if (candidate.isNotEmpty) return candidate;
      }
    }

    return '';
  }

  bool _hasStyleMatch(Listing listing) {
    if (_registeredStylePreferences.isEmpty) return false;

    final preferred = _registeredStylePreferences
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
    if (preferred.isEmpty) return false;

    final listingTags = listing.tags
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
    return listingTags.any(preferred.contains);
  }

  bool _hasSizeMatch(Listing listing) {
    final registered = _normalizeSize(_registeredSize);
    if (registered.isEmpty) return false;
    final listingSize = _extractListingSize(listing);
    return listingSize.isNotEmpty && listingSize == registered;
  }

  bool isRecommendationMatch(Listing listing) {
    return _hasStyleMatch(listing) && _hasSizeMatch(listing);
  }

  int countRecommendationMatches(Iterable<Listing> recommendations) {
    return recommendations.where(isRecommendationMatch).length;
  }

  double recommendationMatchPercentage(Iterable<Listing> recommendations) {
    final total = recommendations.length;
    if (total == 0) return 0;
    final matches = countRecommendationMatches(recommendations);
    return (matches / total) * 100;
  }

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
  Map<String, bool> get savedItems => _savedItems;

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

  bool isSaved(String id) => _savedItems[id] ?? false;

  void clearFilters() {
    _category = 'All';
    notifyListeners();
  }

  bool get hasFilters =>
      _category != 'All' ||
      _size != 'All' ||
      _condition != 'All' ||
      _color != 'All';

  List<Listing> get filteredAndSorted {
    var filtered = _listings.where((l) {
      final matchSearch = l.title.toLowerCase().contains(_search.toLowerCase());
      final matchCat = _category == 'All' || l.tags.contains(_category);
      final matchCond = _condition == 'All' || l.conditionTag == _condition;
      // Size, color, style are not present in Listing, so skip those filters
      return matchSearch && matchCat && matchCond;
    }).map((l) => l.copyWith(saved: _savedItems[l.id] ?? l.saved)).toList();

    filtered.sort((a, b) {
      if (_sort == 'price-asc') return a.price.compareTo(b.price);
      if (_sort == 'price-desc') return b.price.compareTo(a.price);
      if (_sort == 'rating') return b.rating.compareTo(a.rating);
      return b.id.compareTo(a.id);
    });
    return filtered;
  }

  @override
  void dispose() {
    _listingsSub?.cancel();
    _confirmedSalesSub?.cancel();
    super.dispose();
  }
}
