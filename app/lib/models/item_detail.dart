import 'seller.dart';

/// Full item for detail page (gallery, seller, AI score, etc.).
class ItemDetail {
  final String id;
  final String sellerId;
  final String name;
  final double price;
  final String condition;
  final Seller seller;
  final int aiScore;
  final String description;
  final List<String> images;
  final List<String> tags;
  // Removed deprecated field: exchangeType

  const ItemDetail({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.price,
    required this.condition,
    required this.seller,
    required this.aiScore,
    required this.description,
    required this.images,
    required this.tags,
  });
}
