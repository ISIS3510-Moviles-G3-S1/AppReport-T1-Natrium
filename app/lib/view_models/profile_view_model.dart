import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/profile_models.dart';
import '../models/listing.dart';
import '../models/sustainability_impact.dart';
import '../core/analytics_event.dart';
import '../core/analytics_service.dart';
import '../core/eco_service.dart';
import '../data/listing_service.dart';
import '../data/meetup_transaction_service.dart';
import '../data/eco_cache.dart';
import 'session_view_model.dart';

Map<String, dynamic> _computeImpactPayloadIsolate(List<Map<String, dynamic>> rawItems) {
  final items = rawItems
      .map((item) => (
            tags: List<String>.from(item['tags'] as List<dynamic>? ?? const <String>[]),
            title: (item['title'] as String?) ?? '',
          ))
      .toList(growable: false);

  final impact = SustainabilityImpact.fromListings(items);
  return {
    'itemsReused': impact.itemsReused,
    'waterLiters': impact.waterLiters,
    'co2Kg': impact.co2Kg,
    'wasteKg': impact.wasteKg,
    'categoryCounts': impact.categoryCounts.map((k, v) => MapEntry(k.name, v)),
  };
}

Map<String, dynamic> _buildCardWarmupSeedIsolate(Map<String, dynamic> input) {
  final sanitizedName = (input['displayName'] as String? ?? '').trim();
  return {
    'displayName': sanitizedName,
    'xp': input['xp'] ?? 0,
    'transactions': input['transactions'] ?? 0,
    'soldCount': input['soldCount'] ?? 0,
  };
}

enum ProfileCardAsyncPhase {
  ecoRunning,
  ecoCompleted,
  impactRunning,
  impactCompleted,
  failed,
}

class ProfileCardAsyncEvent {
  const ProfileCardAsyncEvent({
    required this.phase,
    this.message,
  });

  final ProfileCardAsyncPhase phase;
  final String? message;
}

class EcoLevelInfo {
  const EcoLevelInfo({
    required this.title,
    required this.nextTitle,
    required this.xpToNext,
    required this.minXP,
    required this.maxXP,
  });

  final String title;
  final String nextTitle;
  final int xpToNext;
  final int minXP;
  final int maxXP;
}

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this._session, {EcoService? ecoService}) : _ecoService = ecoService ?? EcoService() {
    _session.addListener(_forwardSessionChanges);
    _startListingsListener();
    _primeCardsWithFutureHandler();
    Future.microtask(() => _maybeGenerateEcoMessage(forceRefresh: true));
  }

  final SessionViewModel _session;
  final EcoService _ecoService;
  final ListingService _listingService = ListingService();
  final MeetupTransactionService _meetupService = MeetupTransactionService();
  final EcoCache _ecoCache = EcoCache(maxSize: 20, ttlMinutes: 60);
  StreamSubscription<List<Listing>>? _listingsSub;
  List<Listing> _listings = [];
  List<Listing> _rawListings = [];
  Set<String> _confirmedListingIds = {};
  String _ecoMessage = '';
  bool _isGeneratingEcoMessage = false;
  String? _lastEcoRequestHash;
  DateTime? _lastEcoRequestAt;
  int _ecoRequestToken = 0;

  // ── Sustainability impact ─────────────────────────────────────────────────
  SustainabilityImpact _impactSummary = SustainabilityImpact.empty;
  String _impactMessage = '';
  bool _isGeneratingImpact = false;
  String? _lastImpactRequestHash;
  DateTime? _lastImpactRequestAt;
  int _impactRequestToken = 0;
  final StreamController<ProfileCardAsyncEvent> _cardEventsController =
      StreamController<ProfileCardAsyncEvent>.broadcast();
  ProfileCardAsyncEvent? _lastCardEvent;

  AppUser? get _user => _session.currentUser;

  int get xp => _user?.xpPoints ?? 0;

  String get profileName {
    final user = _user;
    if (user == null) return '';
    final name = user.displayName.trim();
    if (name.isNotEmpty) {
      return name;
    }
    return user.email.split('@').first;
  }

  String get profileSince {
    final since = _user?.createdAt;
    if (since == null) return '';
    final month = since.month.toString().padLeft(2, '0');
    return '$month/${since.year}';
  }

  String get profileUniversity {
    final email = _user?.email ?? '';
    final parts = email.split('@');
    if (parts.length == 2) {
      return parts[1];
    }
    return '';
  }

  double get profileRating => (_user?.ratingStars ?? 0).toDouble();

  int get profileTransactions => _user?.numTransactions ?? 0;

  String get profileAvatar => _user?.profilePic ?? '';

  List<ProfileBadge> get badges => const [];

  List<ActivityItem> get activityFeed => const [];

  List<Listing> get listings => _listings;

  String get ecoMessage => _ecoMessage.isEmpty ? _buildFallbackEcoMessage() : _ecoMessage;

  bool get isGeneratingEcoMessage => _isGeneratingEcoMessage;

  SustainabilityImpact get impactSummary => _impactSummary;
  String get impactMessage => _impactMessage;
  bool get isGeneratingImpact => _isGeneratingImpact;
  Stream<ProfileCardAsyncEvent> get cardEvents => _cardEventsController.stream;
  ProfileCardAsyncEvent? get lastCardEvent => _lastCardEvent;

  int get soldCount => _listings.where((item) => item.isSold).length;

  int get totalListingsCount => _listings.length;

  String get soldCountDisplay => '$soldCount';

  EcoLevelInfo get ecoLevelInfo => _buildEcoLevelInfo(xp);

  int get xpToNext => ecoLevelInfo.xpToNext;

  Level get currentLevel {
    final info = ecoLevelInfo;
    final levelNumber = _extractLevelNumber(info.title);
    final levelName = _extractLevelName(info.title);
    return Level(level: levelNumber, name: levelName, minXp: info.minXP);
  }

  Level? get nextLevel {
    final info = ecoLevelInfo;
    if (info.nextTitle == 'Max Level') {
      return null;
    }
    final levelNumber = _extractLevelNumber(info.nextTitle);
    final levelName = _extractLevelName(info.nextTitle);
    return Level(level: levelNumber, name: levelName, minXp: info.maxXP);
  }

  double get levelProgress {
    final info = ecoLevelInfo;
    final denominator = (info.maxXP - info.minXP).toDouble();
    if (denominator <= 0) return 100;
    final progress = ((xp - info.minXP) / denominator).clamp(0.0, 1.0);
    return progress * 100;
  }

  Future<bool> deleteListing(String id) async {
    final listing = _listings.firstWhere((l) => l.id == id, orElse: () => const Listing(
      id: '',
      sellerId: '',
      title: '',
      price: 0,
      conditionTag: '',
      description: '',
      sellerName: '',
    ));
    if (listing.id.isEmpty) return false;
    return _listingService.deleteListing(listing);
  }

  void _startListingsListener() {
    _listingsSub?.cancel();
    final user = _user;
    if (user == null) {
      _rawListings = [];
      _confirmedListingIds = {};
      _listings = [];
      _ecoMessage = '';
      _isGeneratingEcoMessage = false;
      _lastEcoRequestHash = null;
      _lastEcoRequestAt = null;
      notifyListeners();
      return;
    }
    _listingsSub = _listingService.getListingsBySellerId(user.uid).listen((items) {
      final oldCount = _rawListings.length;
      _rawListings = items;
      // ── Invalidar cache cuando se detecta nueva prenda (cambio relevante) ──
      if (_rawListings.length != oldCount) {
        _ecoCache.invalidate();
        debugPrint('[ProfileVM] ECO cache invalidated: ${_rawListings.length} listings detected');
      }
      _refreshConfirmedSalesOverlay(user.uid);
      Future.microtask(_maybeGenerateEcoMessage);
    }, onError: (error, stackTrace) async {
      debugPrint('[ProfileVM] listings stream failed, falling back to cache: $error');
      final cachedListings = await _listingService.getListings().first;
      _rawListings = cachedListings.where((listing) => listing.sellerId == user.uid).toList();
      _refreshConfirmedSalesOverlay(user.uid);
      Future.microtask(_maybeGenerateEcoMessage);
    });
  }

  Future<void> _refreshConfirmedSalesOverlay(String sellerId) async {
    try {
      final confirmedIds = await _meetupService.watchConfirmedListingIds().first;
      final oldConfirmedCount = _confirmedListingIds.length;
      _confirmedListingIds = confirmedIds;
      // ── Invalidar cache cuando cambian sales confirmadas ──
      if (_confirmedListingIds.length != oldConfirmedCount) {
        _ecoCache.invalidate();
        debugPrint('[ProfileVM] ECO cache invalidated: confirmed sales changed');
      }
      _listings = _rawListings.map((listing) {
        if (_confirmedListingIds.contains(listing.id)) {
          return listing.copyWith(status: 'sold');
        }
        return listing;
      }).toList();
      await _recomputeImpact();
      notifyListeners();
    } catch (_) {
      _listings = _rawListings;
      await _recomputeImpact();
      notifyListeners();
    }
  }

  void _forwardSessionChanges() {
    // ── Invalidar cache cuando usuario cambia (profile change) ──
    _ecoCache.invalidate();
    debugPrint('[ProfileVM] ECO cache invalidated: user session changed');
    _startListingsListener();
    notifyListeners();
    _primeCardsWithFutureHandler();
    Future.microtask(_maybeGenerateEcoMessage);
  }

  Future<void> refreshEcoMessage() async {
    await _maybeGenerateEcoMessage(forceRefresh: true)
        .then((_) => _emitCardEvent(const ProfileCardAsyncEvent(phase: ProfileCardAsyncPhase.ecoCompleted)))
        .catchError((error) {
      _emitCardEvent(ProfileCardAsyncEvent(
        phase: ProfileCardAsyncPhase.failed,
        message: 'Eco refresh failed: $error',
      ));
    });
  }

  Future<void> refreshImpactMessage() async {
    await _maybeGenerateImpactInsight(forceRefresh: true)
        .then((_) => _emitCardEvent(const ProfileCardAsyncEvent(phase: ProfileCardAsyncPhase.impactCompleted)))
        .catchError((error) {
      _emitCardEvent(ProfileCardAsyncEvent(
        phase: ProfileCardAsyncPhase.failed,
        message: 'Impact refresh failed: $error',
      ));
    });
  }

  Future<void> _maybeGenerateEcoMessage({bool forceRefresh = false}) async {
    final user = _user;
    if (user == null) {
      _ecoMessage = '';
      _isGeneratingEcoMessage = false;
      notifyListeners();
      return;
    }

    final info = ecoLevelInfo;
    final fallback = _buildFallbackEcoMessage();
    if (_ecoMessage != fallback) {
      _ecoMessage = fallback;
      notifyListeners();
    }

    final requestHash = [
      profileName,
      profileRating.toStringAsFixed(2),
      xp.toString(),
      info.title,
      info.xpToNext.toString(),
      soldCount.toString(),
      profileTransactions.toString(),
    ].join('|');

    // ── Consultar LRU cache primero (cache hit antes de API call) ──
    if (!forceRefresh) {
      final cachedMessage = _ecoCache.get(requestHash);
      if (cachedMessage != null) {
        _ecoMessage = cachedMessage;
        notifyListeners();
        debugPrint('[ProfileVM] ECO cache HIT: ${_ecoCache.getStats()}');
        return; // Skip API call
      }
    }

    final now = DateTime.now();
    final recentlyRequested =
        _lastEcoRequestHash == requestHash &&
        _lastEcoRequestAt != null &&
        now.difference(_lastEcoRequestAt!) < const Duration(minutes: 5);

    if (!forceRefresh && recentlyRequested) {
      return;
    }

    _lastEcoRequestHash = requestHash;
    _lastEcoRequestAt = now;

    final requestToken = ++_ecoRequestToken;
    _isGeneratingEcoMessage = true;
    _emitCardEvent(const ProfileCardAsyncEvent(phase: ProfileCardAsyncPhase.ecoRunning));
    notifyListeners();

    try {
      await _ecoService
          .generateRecommendation(
            displayName: profileName,
            rating: profileRating,
            xp: xp,
            levelTitle: info.title,
            xpToNext: info.xpToNext,
            soldCount: soldCount,
            transactions: profileTransactions,
          )
          .then((aiMessage) {
            if (requestToken != _ecoRequestToken) return;
            _ecoMessage = aiMessage.trim();
            // ── Guardar en LRU cache (cache put después de API success) ──
            _ecoCache.put(requestHash, _ecoMessage);
            debugPrint('[ProfileVM] ECO cache PUT: ${_ecoCache.getStats()}');

            final uid = _user?.uid;
            if (uid != null && _ecoMessage.isNotEmpty) {
              AnalyticsService.instance.track(
                AnalyticsEvent.ecoRecommendationShown(
                  userId: uid,
                  levelTitle: info.title,
                  soldCount: soldCount,
                  transactions: profileTransactions,
                  messageLength: _ecoMessage.length,
                  timestamp: DateTime.now().toUtc().toIso8601String(),
                ),
              );
            }
          })
          .catchError((_) {
            // Keep fallback message on API errors.
          });
    } finally {
      if (requestToken == _ecoRequestToken) {
        _isGeneratingEcoMessage = false;
        _emitCardEvent(const ProfileCardAsyncEvent(phase: ProfileCardAsyncPhase.ecoCompleted));
        notifyListeners();
      }
    }
  }

  EcoLevelInfo _buildEcoLevelInfo(int xp) {
    switch (xp) {
      case >= 0 && < 100:
        return EcoLevelInfo(
          title: 'Level 1 - Newcomer',
          nextTitle: 'Level 2 - Eco Learner',
          xpToNext: 100 - xp,
          minXP: 0,
          maxXP: 100,
        );
      case >= 100 && < 300:
        return EcoLevelInfo(
          title: 'Level 2 - Eco Learner',
          nextTitle: 'Level 3 - Eco Enthusiast',
          xpToNext: 300 - xp,
          minXP: 100,
          maxXP: 300,
        );
      case >= 300 && < 600:
        return EcoLevelInfo(
          title: 'Level 3 - Eco Enthusiast',
          nextTitle: 'Level 4 - Eco Explorer',
          xpToNext: 600 - xp,
          minXP: 300,
          maxXP: 600,
        );
      case >= 600 && < 1000:
        return EcoLevelInfo(
          title: 'Level 4 - Eco Explorer',
          nextTitle: 'Level 5 - Sustainability Star',
          xpToNext: 1000 - xp,
          minXP: 600,
          maxXP: 1000,
        );
      default:
        return const EcoLevelInfo(
          title: 'Level 5 - Sustainability Star',
          nextTitle: 'Max Level',
          xpToNext: 0,
          minXP: 1000,
          maxXP: 10000,
        );
    }
  }

  // ── Sustainability impact ─────────────────────────────────────────────────

  Future<void> _recomputeImpact() async {
    final soldListings = _listings.where((l) => l.isSold).toList(growable: false);
    final rawItems = soldListings
        .map((l) => <String, dynamic>{'tags': l.tags, 'title': l.title})
        .toList(growable: false);

    final payload = await Isolate.run(() => _computeImpactPayloadIsolate(rawItems));

    final countsRaw = Map<String, dynamic>.from(
      payload['categoryCounts'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );

    final counts = <ImpactCategory, int>{};
    for (final entry in countsRaw.entries) {
      final category = ImpactCategory.values.firstWhere(
        (value) => value.name == entry.key,
        orElse: () => ImpactCategory.other,
      );
      counts[category] = (entry.value as num?)?.toInt() ?? 0;
    }

    _impactSummary = SustainabilityImpact(
      itemsReused: (payload['itemsReused'] as num?)?.toInt() ?? 0,
      waterLiters: (payload['waterLiters'] as num?)?.toInt() ?? 0,
      co2Kg: (payload['co2Kg'] as num?)?.toDouble() ?? 0,
      wasteKg: (payload['wasteKg'] as num?)?.toDouble() ?? 0,
      categoryCounts: counts,
    );

    Future.microtask(_maybeGenerateImpactInsight);
  }

  Future<void> _maybeGenerateImpactInsight({bool forceRefresh = false}) async {
    final user = _user;
    if (user == null) {
      _impactMessage = '';
      _isGeneratingImpact = false;
      notifyListeners();
      return;
    }

    // No items reused yet — show a static nudge, no API call needed.
    if (_impactSummary.itemsReused == 0) {
      _impactMessage = '';
      _isGeneratingImpact = false;
      notifyListeners();
      return;
    }

    final requestHash = [
      _impactSummary.itemsReused.toString(),
      _impactSummary.waterLiters.toString(),
      _impactSummary.co2Kg.toStringAsFixed(1),
      _impactSummary.wasteKg.toStringAsFixed(1),
    ].join('|');

    final now = DateTime.now();
    final recentlyRequested =
        _lastImpactRequestHash == requestHash &&
        _lastImpactRequestAt != null &&
        now.difference(_lastImpactRequestAt!) < const Duration(minutes: 5);

    if (!forceRefresh && recentlyRequested) return;

    _lastImpactRequestHash = requestHash;
    _lastImpactRequestAt = now;

    final requestToken = ++_impactRequestToken;
    _isGeneratingImpact = true;
    _emitCardEvent(const ProfileCardAsyncEvent(phase: ProfileCardAsyncPhase.impactRunning));
    notifyListeners();

    try {
      await _ecoService
          .generateImpactInsight(
            impact: _impactSummary,
            displayName: profileName,
          )
          .then((insight) {
            if (requestToken != _impactRequestToken) return;
            _impactMessage = insight;
          })
          .catchError((_) {
            // Keep previous message on error.
          });
    } finally {
      if (requestToken == _impactRequestToken) {
        _isGeneratingImpact = false;
        _emitCardEvent(const ProfileCardAsyncEvent(phase: ProfileCardAsyncPhase.impactCompleted));
        notifyListeners();
      }
    }
  }

  String _buildFallbackEcoMessage() {    final info = ecoLevelInfo;
    if (info.xpToNext <= 0) {
      return 'Amazing work, $profileName! You reached Max Level and are leading by example on UniMarket.';
    }
    return "You're just ${info.xpToNext} XP away from ${info.nextTitle}. Keep going, $profileName!";
  }

  int _extractLevelNumber(String title) {
    final match = RegExp(r'Level\s+(\d+)').firstMatch(title);
    return int.tryParse(match?.group(1) ?? '') ?? 1;
  }

  String _extractLevelName(String title) {
    final parts = title.split('-');
    if (parts.length < 2) return title.trim();
    return parts.sublist(1).join('-').trim();
  }

  void _primeCardsWithFutureHandler() {
    _warmupCardSeedFuture()
        .then((_) {
          _emitCardEvent(const ProfileCardAsyncEvent(phase: ProfileCardAsyncPhase.ecoCompleted));
        })
        .catchError((error) {
          _emitCardEvent(ProfileCardAsyncEvent(
            phase: ProfileCardAsyncPhase.failed,
            message: 'Card warmup failed: $error',
          ));
        });
  }

  Future<Map<String, dynamic>> _warmupCardSeedFuture() async {
    final seed = <String, dynamic>{
      'displayName': profileName,
      'xp': xp,
      'transactions': profileTransactions,
      'soldCount': soldCount,
    };
    return Isolate.run(() => _buildCardWarmupSeedIsolate(seed));
  }

  void _emitCardEvent(ProfileCardAsyncEvent event) {
    _lastCardEvent = event;
    if (!_cardEventsController.isClosed) {
      _cardEventsController.add(event);
    }
  }

  @override
  void dispose() {
    _session.removeListener(_forwardSessionChanges);
    _listingsSub?.cancel();
    _cardEventsController.close();
    super.dispose();
  }
}
