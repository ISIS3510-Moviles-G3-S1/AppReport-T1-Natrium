import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String profilePic;
  final int xpPoints;
  final bool isVerified;
  final int numTransactions;
  final int ratingStars;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.profilePic,
    this.xpPoints = 0,
    this.isVerified = false,
    this.numTransactions = 0,
    this.ratingStars = 0,
    this.createdAt,
  });

  factory AppUser.fromFirebaseUser(User user) {
    final email = user.email ?? '';
    return AppUser(
      uid: user.uid,
      email: email,
      displayName: user.displayName ?? email.split('@').first,
      profilePic: user.photoURL ?? '',
      xpPoints: 0,
      isVerified: user.emailVerified,
      numTransactions: 0,
      ratingStars: 0,
      createdAt: user.metadata.creationTime,
    );
  }

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppUser(
      uid: (data['uid'] as String?) ?? doc.id,
      email: (data['email'] as String?) ?? '',
      displayName: (data['displayName'] as String?) ?? '',
      profilePic: (data['profilePic'] as String?) ?? '',
      xpPoints: (data['xpPoints'] as num?)?.toInt() ?? 0,
      isVerified: (data['isVerified'] as bool?) ?? false,
      numTransactions: (data['numTransactions'] as num?)?.toInt() ?? 0,
      ratingStars: (data['ratingStars'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? profilePic,
    int? xpPoints,
    bool? isVerified,
    int? numTransactions,
    int? ratingStars,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      profilePic: profilePic ?? this.profilePic,
      xpPoints: xpPoints ?? this.xpPoints,
      isVerified: isVerified ?? this.isVerified,
      numTransactions: numTransactions ?? this.numTransactions,
      ratingStars: ratingStars ?? this.ratingStars,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
