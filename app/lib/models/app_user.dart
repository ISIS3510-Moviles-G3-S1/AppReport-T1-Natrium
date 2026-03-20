import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? profilePic;
  final int xpPoints;

  final bool isVerified;
  final int numTransactions;
  final int ratingStars;
  final DateTime? createdAt;

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.profilePic,
    this.xpPoints = 0,
    this.isVerified = false,
    this.numTransactions = 0,
    this.ratingStars = 0,
    this.createdAt,
  });

  factory AppUser.fromFirebaseUser(User user) {
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      profilePic: user.photoURL,
    );
  }

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      return AppUser(uid: doc.id);
    }

    return AppUser(
      uid: data['uid'] ?? doc.id,
      email: data['email'] as String?,
      displayName: data['displayName'] as String?,
      profilePic: data['profilePic'] as String?,
      xpPoints: (data['xpPoints'] ?? 0) as int,
      isVerified: (data['isVerified'] ?? false) as bool,
      numTransactions: (data['numTransactions'] ?? 0) as int,
      ratingStars: (data['ratingStars'] ?? 0) as int,
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