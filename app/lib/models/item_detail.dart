import 'seller.dart';

/// Full item for detail page (gallery, seller, AI score, etc.).
class ItemDetail {
  final int id;
  final String name;
  final double price;
  final String size;
  final String condition;
  final String category;
  final String color;
  final String style;
  final Seller seller;
  final int aiScore;
  final String description;
  final List<String> images;
  final List<String> tags;
  final String exchangeType; // 'sell' | 'swap' | 'donate'

  const ItemDetail({
    required this.id,
    required this.name,
    required this.price,
    required this.size,
    required this.condition,
    required this.category,
    required this.color,
    required this.style,
    required this.seller,
    required this.aiScore,
    required this.description,
    required this.images,
    required this.tags,
    required this.exchangeType,
  });
}
