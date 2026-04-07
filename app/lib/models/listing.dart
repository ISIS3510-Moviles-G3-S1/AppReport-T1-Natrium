import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore-backed listing status values.
///
/// These helpers keep the app's listing states consistent when we count sold
/// items for seller performance feedback.
enum ListingStatus { active, sold, reserved, archived }

String listingStatusToString(ListingStatus status) {
  switch (status) {
    case ListingStatus.sold:
      return 'sold';
    case ListingStatus.reserved:
      return 'reserved';
    case ListingStatus.archived:
      return 'archived';
    case ListingStatus.active:
      return 'active';
  }
}

ListingStatus listingStatusFromString(String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case 'sold':
      return ListingStatus.sold;
    case 'reserved':
      return ListingStatus.reserved;
    case 'archived':
      return ListingStatus.archived;
    case 'available':
    case 'active':
    default:
      return ListingStatus.active;
  }
}

/// Light listing for browse grid and home featured.
class Listing {
    Map<String, dynamic> toJson() => toFirestore();
  final String id;
  final String sellerId;
  final String title;
  final int price;
  final String conditionTag;
  final String description;
  final String sellerName;
  final String exchangeType;
  final List<String> tags;
  final double rating;
  final String imageName;
  final DateTime? createdAt;
  final DateTime? soldAt;
  final String imagePath;
  final List<String> imageURLs;
  final String status;
  final bool saved;

  const Listing({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.price,
    required this.conditionTag,
    required this.description,
    required this.sellerName,
    this.exchangeType = 'sell',
    this.tags = const [],
    this.rating = 0,
    this.imageName = '',
    this.createdAt,
    this.soldAt,
    this.imagePath = '',
    this.imageURLs = const [],
    this.status = 'active',
    this.saved = false,
  });

  ListingStatus get listingStatus => listingStatusFromString(status);
  bool get isSold => listingStatus == ListingStatus.sold;
  bool get isActive => listingStatus == ListingStatus.active;

  Listing copyWith({
    bool? saved,
    String? status,
    DateTime? soldAt,
  }) => Listing(
    id: id,
    sellerId: sellerId,
    title: title,
    price: price,
    conditionTag: conditionTag,
    description: description,
    sellerName: sellerName,
    exchangeType: exchangeType,
    tags: tags,
    rating: rating,
    imageName: imageName,
    createdAt: createdAt,
    soldAt: soldAt ?? this.soldAt,
    imagePath: imagePath,
    imageURLs: imageURLs,
    status: status ?? this.status,
    saved: saved ?? this.saved,
  );

  String get primaryImageUrl {
    for (final url in imageURLs) {
      if (url.trim().isNotEmpty) return url;
    }
    if (imagePath.trim().isNotEmpty) return imagePath;
    return '';
  }

  bool get hasPrimaryImage => primaryImageUrl.isNotEmpty;

  static List<String> _coerceStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return [value];
    }
    return [];
  }

  factory Listing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawImages =
        data['imageURLs'] ??
        data['imageUrls'] ??
        data['imageURLS'] ??
        data['imageUrl'] ??
        data['image'] ??
        [];
    return Listing(
      id: doc.id,
      sellerId: data['sellerId'] ?? '',
      title: data['title'] ?? '',
      price: (data['price'] ?? 0) is int ? data['price'] : int.tryParse(data['price'].toString()) ?? 0,
      conditionTag: data['conditionTag'] ?? '',
      description: data['description'] ?? '',
      sellerName: data['sellerName'] ?? '',
      exchangeType: data['exchangeType'] ?? data['exchange_type'] ?? 'sell',
      tags: List<String>.from(data['tags'] ?? []),
      rating: (data['rating'] ?? 0).toDouble(),
      imageName: data['imageName'] ?? '',
      createdAt: (data['createdAt'] is Timestamp) ? (data['createdAt'] as Timestamp).toDate() : null,
      soldAt: (data['soldAt'] is Timestamp) ? (data['soldAt'] as Timestamp).toDate() : null,
      imagePath: data['imagePath'] ?? '',
      imageURLs: _coerceStringList(rawImages),
      status: listingStatusToString(listingStatusFromString(data['status']?.toString())),
      saved: false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sellerId': sellerId,
      'title': title,
      'price': price,
      'conditionTag': conditionTag,
      'description': description,
      'sellerName': sellerName,
      'exchangeType': exchangeType,
      'tags': tags,
      'rating': rating,
      'imageName': imageName,
      'createdAt': createdAt,
      'soldAt': soldAt,
      'imagePath': imagePath,
      'imageURLs': imageURLs,
      'status': listingStatusToString(listingStatusFromString(status)),
    };
  }
}
