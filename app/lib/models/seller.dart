class Seller {
  final String id;
  final String name;
  final String university;
  final double rating;
  final int sales;
  final String avatar;
  final bool verified;

  const Seller({
    required this.id,
    required this.name,
    required this.university,
    required this.rating,
    required this.sales,
    required this.avatar,
    this.verified = false,
  });
}
