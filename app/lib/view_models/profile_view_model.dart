import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/profile_models.dart';
import '../models/listing.dart';
import '../data/listing_service.dart';
import 'session_view_model.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this._session) {
    _session.addListener(_forwardSessionChanges);
    _startListingsListener();
  }

  final SessionViewModel _session;
  final ListingService _listingService = ListingService();
  StreamSubscription<List<Listing>>? _listingsSub;
  List<Listing> _listings = [];

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

  Level get currentLevel => const Level(level: 1, name: 'Newcomer', minXp: 0);

  Level? get nextLevel => null;

  double get levelProgress => 0;

  Future<void> deleteListing(String id) async {
    final listing = _listings.firstWhere((l) => l.id == id, orElse: () => const Listing(
      id: '',
      sellerId: '',
      title: '',
      price: 0,
      conditionTag: '',
      description: '',
      sellerName: '',
    ));
    if (listing.id.isEmpty) return;
    await _listingService.deleteListing(listing);
  }

  void _startListingsListener() {
    _listingsSub?.cancel();
    final user = _user;
    if (user == null) {
      _listings = [];
      notifyListeners();
      return;
    }
    _listingsSub = _listingService.getListingsBySellerId(user.uid).listen((items) {
      _listings = items;
      notifyListeners();
    });
  }

  void _forwardSessionChanges() {
    _startListingsListener();
    notifyListeners();
  }

  @override
  void dispose() {
    _session.removeListener(_forwardSessionChanges);
    _listingsSub?.cancel();
    super.dispose();
  }
}
