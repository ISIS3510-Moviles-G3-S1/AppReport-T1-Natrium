import 'dart:math';

enum TagCategory { category, color, style, pattern }

extension TagCategoryX on TagCategory {
  String get displayName => switch (this) {
        TagCategory.category => 'Category',
        TagCategory.color => 'Color',
        TagCategory.style => 'Style',
        TagCategory.pattern => 'Pattern',
      };
}

class ClothingTag {
  final String id;
  final String name;
  final double confidence;
  final TagCategory category;

  const ClothingTag({
    required this.id,
    required this.name,
    required this.confidence,
    required this.category,
  });

  ClothingTag copyWith({
    String? id,
    String? name,
    double? confidence,
    TagCategory? category,
  }) {
    return ClothingTag(
      id: id ?? this.id,
      name: name ?? this.name,
      confidence: confidence ?? this.confidence,
      category: category ?? this.category,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'confidence': confidence,
        'category': category.name,
      };
}

String generateClothingTagId() {
  final now = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final randomPart = Random().nextInt(1 << 31).toRadixString(36);
  return '$now-$randomPart';
}