import 'package:string_similarity/string_similarity.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/analytics_event.dart';
import '../core/analytics_service.dart';
import '../models/listing.dart';
import '../data/listing_service.dart';


import '../core/recommendation_service.dart';
import '../core/recommendation_system.dart';
import '../core/ai_recommendation_decorator.dart';


class BrowseViewModel extends ChangeNotifier {
  List<Listing> _listings = [];
  List<Listing> _allListings = [];
  late ListingService _listingService;
  StreamSubscription<List<Listing>>? _listingsSub;
  final Map<String, bool> _savedItems = {};
  String _search = '';
  String _category = 'All';
  String _size = 'All';
  String _condition = 'All';
  String _color = 'All';
  String _sort = 'newest';
  bool _aiSearch = false;
  bool _showFilters = false;

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

  BrowseViewModel() {
    _listingService = ListingService();
    _listenListings();
  }

  void _listenListings() {
    _listingsSub = _listingService.getListings().listen((listings) {
      _allListings = listings;
      _recomputeVisibleListings();
    });
  }

  void _recomputeVisibleListings() {
    _listings = _allListings
        .where((listing) => !listing.isSold)
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
  void toggleSave(String itemId) {
    _savedItems[itemId] = !_savedItems[itemId]!;
    final isNowSaved = _savedItems[itemId]!;
    final item = _listings.firstWhere((l) => l.id == itemId);
    final cat = item.tags.isNotEmpty ? item.tags[0] : 'Other';
    _categoryInteractionCounts[cat] = (_categoryInteractionCounts[cat] ?? 0) + 1;

    if (isNowSaved) {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isNotEmpty) {
        AnalyticsService.instance.track(
          AnalyticsEvent.userMeaningfulInteraction(
            userId: userId,
            interactionType: 'like',
            timestamp: DateTime.now().toUtc().toIso8601String(),
            category: cat,
          ),
        );
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


  // 'For You' recommendations (favoritos + similaridad de tags)
  List<Listing> get forYouRecommendations {
    // 1. Obtener los favoritos, vistos y comprados
    final favoriteIds = _savedItems.entries.where((e) => e.value).map((e) => e.key).toSet();
    final allInteractedIds = <String>{}
      ..addAll(favoriteIds)
      ..addAll(_viewedItemIds)
      ..addAll(_purchasedItemIds);
    final interactedListings = _listings.where((l) => allInteractedIds.contains(l.id)).toList();

    // 2. Obtener todos los tags de los ítems con los que interactuó
    final interactedTags = <String>{};
    for (final item in interactedListings) {
      interactedTags.addAll(item.tags.where((t) => t.trim().isNotEmpty));
    }

    // LOG: Mostrar tags de interacción
    debugPrint('[ForYou] Interacted tags: ${interactedTags.join(", ")}');

    // 3. Incluir todos los ítems que tengan al menos un tag similar a los de interacción (usando similaridad de strings)
    const double similarityThreshold = 0.6; // Puedes ajustar este valor
    final similarListings = _listings.where((l) {
      if (allInteractedIds.contains(l.id)) return false; // No incluir repetidos
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

    // 4. Combinar interactuados y similares, sin duplicados
    final allForYou = [...interactedListings, ...similarListings];

    // LOG: Mostrar cuántos ítems se recomiendan
    debugPrint('[ForYou] Total recommendations: ${allForYou.length}');

    return allForYou;
  }

  // 'For You' recomendaciones IA (asíncrono)
  Future<List<Listing>> getForYouAIRecommendations() async {
    final base = AllItemsRecommendation(_listings);
    final tagFiltered = TagFilterDecorator(base, _categoryInteractionCounts.keys.toList());
    final newPriority = NewItemPriorityDecorator(tagFiltered, DateTime.now().subtract(Duration(days: 5)), _itemUploadDates);
    final ai = AIRecommendationDecorator(
      newPriority,
      apiUrl: 'http://localhost:8000/recommend', // Cambia por la IP de tu PC si usas dispositivo físico
      userId: 'demo-user',
    );
    return await ai.getRecommendedItems();
  }

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
    super.dispose();
  }
}
