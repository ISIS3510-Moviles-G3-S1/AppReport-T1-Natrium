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
import '../data/search_history_storage.dart';
import 'package:hive/hive.dart';
import '../core/lru_cache_service.dart';
import 'dart:isolate';
import '../core/recommendation_service.dart';
import '../core/recommendation_system.dart';

class BrowseViewModel extends ChangeNotifier {
    // --- Search Results Cache ---
    // Guarda los resultados de búsqueda por query (en memoria y Hive)
    Future<void> cacheSearchResults(String query, List<Listing> results) async {
      _memoryCache.save('search_result_\u001f$query', results.map((e) => e.toJson()).toList());
      final box = await Hive.openBox<List>('search_results_cache');
      await box.put('search_result_\u001f$query', results.map((e) => e.toJson()).toList());
    }

    // Recupera resultados cacheados para una query
    Future<List<Listing>?> getCachedSearchResults(String query) async {
      final mem = _memoryCache.retrieve('search_result_\u001f$query');
      if (mem != null) {
        return (mem as List).map((json) => Listing.fromJson(json)).toList();
      }
      final box = await Hive.openBox<List>('search_results_cache');
      final cached = box.get('search_result_\u001f$query');
      if (cached != null) {
        return (cached as List).map((json) => Listing.fromJson(json)).toList();
      }
      return null;
    }
  final FypFavRelationStorage _favStorage = FypFavRelationStorage();
  final SearchHistoryStorage _searchHistoryStorage = SearchHistoryStorage();
  final LruCacheService<String, dynamic> _memoryCache = LruCacheService<String, dynamic>();
  final Box<dynamic> _localStorage = Hive.box<dynamic>('browse_view_model');
  // Llama esto cuando el usuario realiza una búsqueda
  Future<void> saveSearchHistoryAndCache(String query, List<Listing> results) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    await _searchHistoryStorage.addSearch(query: query, userId: userId);
    await cacheSearchResults(query, results);
  }
  List<Listing> _listings = [];
  List<Listing> _allListings = [];
  late ListingService _listingService;
  final MeetupTransactionService _meetupService = MeetupTransactionService();
  StreamSubscription<List<Listing>>? _listingsSub;
  StreamSubscription<Set<String>>? _confirmedSalesSub;
  Set<String> _confirmedListingIds = {};
  Map<String, bool> _savedItems = {}; // Declarar el campo _savedItems
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

  List<Map<String, dynamic>> _pendingOperations = [];

  BrowseViewModel() {
    _listingService = ListingService();
    _listenListings();
  }

  Future<void> cacheCatalogSnapshot(Map<String, dynamic> catalog) async {
    _memoryCache.save('catalog', catalog);
    await _localStorage.put('catalog_snapshot', catalog);
    print('Caching catalog snapshot: \\n');
    print(catalog.toString());
  }

  Map<String, dynamic>? getCachedCatalog() {
    return _memoryCache.retrieve('catalog') ??
        _localStorage.get('catalog_snapshot') as Map<String, dynamic>?;
  }

  void logCachedCatalog() {
    debugLogMessage('Retrieving cached catalog:');
    final catalog = getCachedCatalog();
    debugLogMessage(catalog?.toString() ?? 'No catalog found in cache.');
  }

  // Función global para logs de depuración
  void debugLogMessage(String message) {
    debugPrint(message);
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

  // Guarda las recomendaciones de FYP en Hive
  Future<void> _cacheForYouRecommendations(List<Listing> recommendations) async {
    final box = await Hive.openBox<List>('fyp_cache');
    await box.put('cached_fyp', recommendations.map((listing) => listing.toJson()).toList());
    debugPrint('Recomendaciones de FYP guardadas en Hive.');
  }

  // Recupera las recomendaciones de FYP desde Hive
  Future<List<Listing>> _getCachedForYouRecommendations() async {
    final box = await Hive.openBox<List>('fyp_cache');
    final cachedData = box.get('cached_fyp', defaultValue: []);
    return cachedData?.map<Listing>((json) => Listing.fromJson(json)).toList() ?? []; // Manejar el caso nulo
  }


  // Guarda los favoritos en Hive
  Future<void> _cacheFavorites() async {
    final box = await Hive.openBox<Map>('favorites_cache');
    await box.put('cached_favorites', _savedItems);
    debugPrint('Favoritos guardados en Hive.');
  }

  // Recupera los favoritos desde Hive
  Future<void> _getCachedFavorites() async {
    final box = await Hive.openBox<Map>('favorites_cache');
    final cachedData = box.get('cached_favorites', defaultValue: {});
    _savedItems = Map<String, bool>.from(cachedData ?? {}); // Manejar el caso nulo
    debugPrint('Favoritos recuperados desde Hive: ${_savedItems.length} items.');
  }

  @override
  Future<void> reloadFavoritesForCurrentUser() async {
    await _getCachedFavorites(); // Recuperar favoritos desde Hive
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      debugPrint('No connection. Adding operation to pending queue.');
      _pendingOperations.add({'itemId': userId, 'isNowSaved': true});
      notifyListeners();
      return;
    }
    final relations = await _favStorage.getRelationsByFavId(userId);
    for (final fypItemId in relations) {
      _savedItems[fypItemId] = true;
    }
    await _cacheFavorites(); // Guardar favoritos en Hive
    notifyListeners();
  }

  void _listenListings() async {
    debugPrint('Listening to listings...');
    _listingsSub = _listingService.getListings().listen((listings) async {
      debugPrint('Listings received:');
      for (var listing in listings) {
        debugPrint(listing.toString());
      }
      _allListings = listings;
      debugPrint('Total listings received: ${_allListings.length}');

      await cacheCatalogSnapshot({
        'listings': listings.map((listing) => listing.toJson()).toList(),
      });
      debugPrint('Catalog snapshot cached.');

      debugPrint('Recomputing visible listings...');
      _recomputeVisibleListings();
    }, onError: (error, stackTrace) async {
      debugPrint('[BrowseVM] listings stream failed, falling back to cache: $error');
      final cachedListings = await _listingService.getListings().first;
      _allListings = cachedListings;
      await cacheCatalogSnapshot({
        'listings': cachedListings.map((listing) => listing.toJson()).toList(),
      });
      _recomputeVisibleListings();
    });
  }

  void _listenConfirmedSales() {
    _confirmedSalesSub = _meetupService.watchConfirmedListingIds().listen((ids) {
      _confirmedListingIds = ids;
      _recomputeVisibleListings();
    }, onError: (error, stackTrace) {
      debugPrint('[BrowseVM] confirmed sales stream failed: $error');
      _confirmedListingIds = {};
      _recomputeVisibleListings();
    });
  }

  void _recomputeVisibleListings() {
    debugPrint('Recomputing visible listings...');
    _listings = _allListings
        .where((listing) => listing.isAvailable)
        .where((listing) => !_confirmedListingIds.contains(listing.id))
        .toList();

    debugPrint('Filtered listings:');
    for (var listing in _listings) {
      debugPrint(listing.toString());
    }

    for (final l in _listings) {
      _savedItems[l.id] = l.saved;
      final cat = l.tags.isNotEmpty ? l.tags[0] : 'Other';
      _categoryInteractionCounts[cat] = (_categoryInteractionCounts[cat] ?? 0);
    }
    _updateRecommendationService();
    notifyListeners();
  }

  void _updateRecommendationService() {
    // Auto-update registered preferences based on user interactions
    _updateRegisteredPreferencesFromInteractions();
    
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

  void _updateRegisteredPreferencesFromInteractions() {
    // Extract style preferences from items the user has favorited or viewed
    final interactedIds = <String>{}
      ..addAll(_savedItems.entries.where((e) => e.value).map((e) => e.key))
      ..addAll(_viewedItemIds)
      ..addAll(_purchasedItemIds);

    if (interactedIds.isEmpty) {
      print('[Prefs] No user interactions yet, keeping hardcoded defaults');
      return;
    }

    final interactedListings = _listings.where((l) => interactedIds.contains(l.id)).toList();

    // Extract all tags from interacted items
    final allTags = <String>{};
    for (final item in interactedListings) {
      allTags.addAll(item.tags.where((t) => t.trim().isNotEmpty));
    }

    if (allTags.isNotEmpty) {
      // Take top tags (sort by frequency)
      final tagFrequency = <String, int>{};
      for (final item in interactedListings) {
        for (final tag in item.tags.where((t) => t.trim().isNotEmpty)) {
          tagFrequency[tag] = (tagFrequency[tag] ?? 0) + 1;
        }
      }

      // Get top 3 tags by frequency
      final topTags = tagFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      _registeredStylePreferences = topTags.take(3).map((e) => e.key).toList(growable: false);
      print('[Prefs] Auto-detected style preferences: $_registeredStylePreferences');
    }

    // Extract size preferences from interacted items
    for (final item in interactedListings) {
      final itemSize = _extractListingSize(item);
      if (itemSize.isNotEmpty) {
        _registeredSize = itemSize;
        print('[Prefs] Auto-detected size preference: $_registeredSize');
        break; // Use the first item's size we find
      }
    }
  }


  // User favorites an item
  Future<void> toggleSave(String itemId) async {
    debugPrint('Toggling favorite for item: $itemId');
    debugPrint('Current favorite state: ${_savedItems[itemId]}');

    _savedItems[itemId] = !_savedItems[itemId]!;
    final isNowSaved = _savedItems[itemId]!;
    final item = _listings.firstWhere((l) => l.id == itemId);
    final cat = item.tags.isNotEmpty ? item.tags[0] : 'Other';
    _categoryInteractionCounts[cat] = (_categoryInteractionCounts[cat] ?? 0) + 1;

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      debugPrint('No connection. Adding operation to pending queue.');
      _pendingOperations.add({'itemId': itemId, 'isNowSaved': isNowSaved});
      notifyListeners();
      return;
    }
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
    print('[ForYou] Interacted tags: ${interactedTags.join(", ")}');

    // 3. Include all items with at least one tag similar to the interacted tags (using string similarity)
    const double similarityThreshold = 0.6; // You can adjust this value
    final similarListings = _listings.where((l) {
      if (allInteractedIds.contains(l.id)) return false; // Do not include duplicates
      for (final tag in l.tags) {
        for (final interactedTag in interactedTags) {
          final similarity = StringSimilarity.compareTwoStrings(
            tag.toLowerCase(), interactedTag.toLowerCase());
          if (similarity >= similarityThreshold) {
            print('[ForYou] Similar: ${l.title} (tag: $tag) ~ $interactedTag (sim: $similarity)');
            return true;
          }
        }
      }
      return false;
    }).toList();

    // 4. Combine interacted and similar items, without duplicates
    final allForYou = [...interactedListings, ...similarListings];

    // LOG: Show how many items are recommended
    print('[ForYou] Total recommendations: ${allForYou.length}');

    return allForYou;
  }

  Future<List<Listing>> generateForYouRecommendations() async {
    debugPrint('Generando recomendaciones para FYP...');

    // Tarea 1: Calcular puntajes basados en favoritos
    Future<List<Listing>> favoritesTask = Future(() {
      debugPrint('Calculando puntajes basados en favoritos...');
      final favoriteIds = _savedItems.entries.where((e) => e.value).map((e) => e.key).toSet();
      return _listings.where((listing) => favoriteIds.contains(listing.id)).toList();
    });

    // Tarea 2: Calcular puntajes basados en búsquedas recientes
    Future<List<Listing>> recentSearchesTask = Future(() {
      debugPrint('Calculando puntajes basados en búsquedas recientes...');
      return _listings.where((listing) => listing.tags.any((tag) => _search.contains(tag))).toList();
    });

    // Tarea 3: Calcular puntajes basados en tags
    Future<List<Listing>> tagsTask = Future(() {
      debugPrint('Calculando puntajes basados en tags...');
      final interactedTags = _categoryInteractionCounts.keys.toSet();
      return _listings.where((listing) => listing.tags.any((tag) => interactedTags.contains(tag))).toList();
    });

    final results = await Future.wait([favoritesTask, recentSearchesTask, tagsTask]);
    final recommendations = results.expand((list) => list).toList();

    await _cacheForYouRecommendations(recommendations); // Guardar en Hive
    return recommendations;
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
    if (_registeredStylePreferences.isEmpty) {
      print('[Match] Style check FAILED: No registered preferences');
      return false;
    }

    final preferred = _registeredStylePreferences
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
    if (preferred.isEmpty) {
      print('[Match] Style check FAILED: Preferred set is empty');
      return false;
    }

    final listingTags = listing.tags
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
    
    final hasMatch = listingTags.any(preferred.contains);
    if (!hasMatch) {
      print('[Match] ${listing.title}: tags=$listingTags vs preferred=$preferred = NO MATCH');
    } else {
      print('[Match] ${listing.title}: tags=$listingTags vs preferred=$preferred = STYLE MATCH ✓');
    }
    return hasMatch;
  }

  bool _hasSizeMatch(Listing listing) {
    final registered = _normalizeSize(_registeredSize);
    if (registered.isEmpty) {
      print('[Match] Size check FAILED: Registered size is empty (raw: $_registeredSize)');
      return false;
    }
    final listingSize = _extractListingSize(listing);
    final hasMatch = listingSize.isNotEmpty && listingSize == registered;
    
    if (!hasMatch) {
      print('[Match] ${listing.title}: item_size=$listingSize vs registered=$registered = NO MATCH');
    } else {
      print('[Match] ${listing.title}: item_size=$listingSize vs registered=$registered = SIZE MATCH ✓');
    }
    return hasMatch;
  }

  bool isRecommendationMatch(Listing listing) {
    final styleMatch = _hasStyleMatch(listing);
    final sizeMatch = _hasSizeMatch(listing);
    final result = styleMatch && sizeMatch;
    if (result) {
      print('[Match] ✓✓✓ ${listing.title} is a FULL MATCH ✓✓✓');
    }
    return result;
  }

  int countRecommendationMatches(Iterable<Listing> recommendations) {
    print('\n[Match] ========== Starting match count ==========');
    print('[Match] Registered preferences: $_registeredStylePreferences');
    print('[Match] Registered size: $_registeredSize');
    print('[Match] Total items to check: ${recommendations.length}');
    
    int count = 0;
    for (final listing in recommendations) {
      if (isRecommendationMatch(listing)) {
        count++;
      }
    }
    
    print('[Match] ========== Final result: $count / ${recommendations.length} matches ==========\n');
    return count;
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
    // Guardar historial y cachear resultados actuales si hay
    saveSearchHistoryAndCache(v, _listings);
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

  void _processPendingOperations() async {
    if (_pendingOperations.isEmpty) return;

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    debugPrint('Processing pending operations...');
    for (final operation in List.from(_pendingOperations)) {
      final itemId = operation['itemId'];
      final isNowSaved = operation['isNowSaved'];

      try {
        if (isNowSaved) {
          await _favStorage.addRelation(favId: userId, fypItemId: itemId);
        } else {
          await _favStorage.removeRelation(favId: userId, fypItemId: itemId);
        }
        _pendingOperations.remove(operation);
        debugPrint('Operation synced for item: $itemId');
      } catch (e) {
        debugPrint('Failed to sync operation for item: $itemId. Retrying later.');
      }
    }
  }

  Future<void> performSearchWithIsolate(String query) async {
    debugPrint('Starting search with isolate...');

    // Crear un ReceivePort para recibir resultados del Isolate
    final receivePort = ReceivePort();

    // Crear un Isolate y pasarle los datos necesarios
    await Isolate.spawn(_searchIsolateEntry, [query, _listings, receivePort.sendPort]);

    // Escuchar los resultados del Isolate
    receivePort.listen((filteredResults) {
      debugPrint('Search results received from isolate: ${filteredResults.length} items.');
      _listings = List<Listing>.from(filteredResults);
      notifyListeners();
    });
  }

  // Método que se ejecuta en el Isolate
  static void _searchIsolateEntry(List<dynamic> args) {
    final query = args[0] as String;
    final listings = args[1] as List<Listing>;
    final sendPort = args[2] as SendPort;

    // Filtrar los productos según el query
    final filteredResults = listings.where((listing) {
      return listing.title.toLowerCase().contains(query.toLowerCase()) ||
             listing.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
    }).toList();

    // Enviar los resultados de vuelta al hilo principal
    sendPort.send(filteredResults);
  }

  @override
  void dispose() {
    _listingsSub?.cancel();
    _confirmedSalesSub?.cancel();
    super.dispose();
  }
}
