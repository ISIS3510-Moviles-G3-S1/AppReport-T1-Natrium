import 'package:flutter/foundation.dart';
import '../models/profile_models.dart';
import '../data/mock_data.dart';

class ProfileViewModel extends ChangeNotifier {
  List<MyListing> _listings = List.from(MockData.myListings);

  int get xp => MockData.profileXp;
  String get profileName => MockData.profileName;
  String get profileSince => MockData.profileSince;
  String get profileUniversity => MockData.profileUniversity;
  double get profileRating => MockData.profileRating;
  int get profileTransactions => MockData.profileTransactions;
  String get profileAvatar => MockData.profileAvatar;

  List<ProfileBadge> get badges => MockData.badges;
  List<ActivityItem> get activityFeed => MockData.activityFeed;
  List<MyListing> get listings => _listings;

  Level get currentLevel {
    final eligible = MockData.levels.where((l) => xp >= l.minXp).toList();
    return eligible.isEmpty ? MockData.levels.first : eligible.last;
  }

  Level? get nextLevel {
    for (final l in MockData.levels) {
      if (l.minXp > xp) return l;
    }
    return null;
  }

  double get levelProgress {
    final next = nextLevel;
    if (next == null) return 100;
    final current = currentLevel;
    return ((xp - current.minXp) / (next.minXp - current.minXp)) * 100;
  }

  void deleteListing(int id) {
    _listings = _listings.where((l) => l.id != id).toList();
    notifyListeners();
  }
}
