/// Light listing for browse grid and home featured.
class Listing {
  final int id;
  final String name;
  final double price;
  final String size;
  final String condition;
  final String category;
  final String color;
  final String style;
  final String seller;
  final double rating;
  final String image;
  final List<String> tags;
  final bool saved;

  const Listing({
    required this.id,
    required this.name,
    required this.price,
    required this.size,
    required this.condition,
    required this.category,
    required this.color,
    required this.style,
    required this.seller,
    required this.rating,
    required this.image,
    this.tags = const [],
    this.saved = false,
  });

  Listing copyWith({bool? saved}) => Listing(
    id: id,
    name: name,
    price: price,
    size: size,
    condition: condition,
    category: category,
    color: color,
    style: style,
    seller: seller,
    rating: rating,
    image: image,
    tags: tags,
    saved: saved ?? this.saved,
  );
}
