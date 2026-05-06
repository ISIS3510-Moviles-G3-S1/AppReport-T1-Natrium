import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

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
  final String size;
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
    this.size = '',
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
    String? size,
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
    size: size ?? this.size,
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

  static String _normalizeSize(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return '';
    if (normalized == 'one size' || normalized == 'onesize') return 'One Size';
    return normalized.toUpperCase();
  }

  static String _extractSizeFromTags(List<String> tags) {
    for (final tag in tags) {
      final normalized = tag.trim().toLowerCase();
      if (normalized.isEmpty) continue;

      if (normalized == 'one size' || normalized == 'onesize') {
        return 'One Size';
      }

      if (const {'xxs', 'xs', 's', 'm', 'l', 'xl', 'xxl', 'xxxl'}.contains(normalized)) {
        return normalized.toUpperCase();
      }

      if (normalized.startsWith('size ')) {
        return _normalizeSize(normalized.replaceFirst('size ', ''));
      }

      if (normalized.startsWith('talla ')) {
        return _normalizeSize(normalized.replaceFirst('talla ', ''));
      }
    }
    return '';
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
    final parsedTags = List<String>.from(data['tags'] ?? []);
    final explicitSize = (data['size'] ?? '').toString();

    return Listing(
      id: doc.id,
      sellerId: data['sellerId'] ?? '',
      title: data['title'] ?? '',
      price: (data['price'] ?? 0) is int ? data['price'] : int.tryParse(data['price'].toString()) ?? 0,
      conditionTag: data['conditionTag'] ?? '',
      description: data['description'] ?? '',
      sellerName: data['sellerName'] ?? '',
      exchangeType: data['exchangeType'] ?? data['exchange_type'] ?? 'sell',
      tags: parsedTags,
      rating: (data['rating'] ?? 0).toDouble(),
      imageName: data['imageName'] ?? '',
      createdAt: (data['createdAt'] is Timestamp) ? (data['createdAt'] as Timestamp).toDate() : null,
      soldAt: (data['soldAt'] is Timestamp) ? (data['soldAt'] as Timestamp).toDate() : null,
      imagePath: data['imagePath'] ?? '',
      imageURLs: _coerceStringList(rawImages),
      size: _normalizeSize(explicitSize).isNotEmpty
          ? _normalizeSize(explicitSize)
          : _extractSizeFromTags(parsedTags),
      status: listingStatusToString(listingStatusFromString(data['status']?.toString())),
      saved: false,
    );
  }

  /// Crea una instancia de Listing a partir de un mapa JSON.
  static Listing fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.trim().isNotEmpty) return DateTime.tryParse(value);
      return null;
    }

    return Listing(
      id: json['id'] ?? '',
      sellerId: json['sellerId'] ?? '',
      title: json['title'] ?? '',
      price: json['price'] ?? 0,
      conditionTag: json['conditionTag'] ?? '',
      description: json['description'] ?? '',
      sellerName: json['sellerName'] ?? '',
      exchangeType: json['exchangeType'] ?? 'sell',
      tags: _coerceStringList(json['tags']),
      rating: (json['rating'] ?? 0).toDouble(),
      imageName: json['imageName'] ?? '',
      createdAt: parseDate(json['createdAt']),
      soldAt: parseDate(json['soldAt']),
      imagePath: json['imagePath'] ?? '',
      imageURLs: _coerceStringList(json['imageURLs']),
      size: json['size'] ?? '',
      status: json['status'] ?? 'active',
      saved: json['saved'] ?? false,
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
      'size': size,
      'status': listingStatusToString(listingStatusFromString(status)),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'createdAt': createdAt?.toIso8601String(),
      'soldAt': soldAt?.toIso8601String(),
      'imagePath': imagePath,
      'imageURLs': imageURLs,
      'size': size,
      'status': status,
      'saved': saved,
    };
  }
}
