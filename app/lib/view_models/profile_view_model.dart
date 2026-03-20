import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/profile_models.dart';
import 'session_view_model.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this._session) {
    _session.addListener(_forwardSessionChanges);
  }

  final SessionViewModel _session;

  AppUser? get _user => _session.currentUser;

  int get xp => 0;

  String get profileName {
    final user = _user;
    if (user == null) return '';
    final name = user.displayName;
    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }
    final email = user.email;
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }
    return 'User';
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

  double get profileRating => 0;

  int get profileTransactions => 0;

  String get profileAvatar => '';

  List<ProfileBadge> get badges => const [];

  List<ActivityItem> get activityFeed => const [];

  List<MyListing> get listings => const [];

  Level get currentLevel => const Level(level: 1, name: 'Newcomer', minXp: 0);

  Level? get nextLevel => null;

  double get levelProgress => 0;

  void deleteListing(int id) {}

  void _forwardSessionChanges() => notifyListeners();

  @override
  void dispose() {
    _session.removeListener(_forwardSessionChanges);
    super.dispose();
  }
}
