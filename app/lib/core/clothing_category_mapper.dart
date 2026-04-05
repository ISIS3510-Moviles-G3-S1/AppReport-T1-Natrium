class ClothingCategoryMapper {
  /// Maps common ML labels to a clean, user-facing clothing category.
  ///
  /// The matching is intentionally substring-based because image labeling
  /// models often return noisy labels such as "t-shirt", "jean jacket",
  /// or "athletic shoe". A forgiving matcher gives a better UX for student
  /// project prototypes than requiring exact model labels.
  String mapLabelToCategory(String label) {
    final value = label.toLowerCase();

    if (_containsAny(value, ['shirts', 't-shirt', 'tee', 'jersey', 'blouse', 'top', 'tank'])) {
      return 'Shirt';
    }
    if (_containsAny(value, ['pants', 'jeans', 'denim', 'trousers', 'shorts', 'leggings'])) {
      return 'Pants';
    }
    if (_containsAny(value, ['dress', 'gown', 'skirt'])) {
      return 'Dress';
    }
    if (_containsAny(value, ['shoe', 'sneaker', 'boot', 'loafer', 'sandal', 'pump', 'heel'])) {
      return 'Shoes';
    }
    if (_containsAny(value, ['jacket', 'coat', 'blazer', 'cardigan', 'sweater', 'hoodie', 'vest'])) {
      return 'Jacket';
    }
    if (_containsAny(value, ['hat', 'cap', 'scarf', 'belt', 'bag', 'backpack'])) {
      return 'Accessory';
    }
    if (value.contains('suit')) {
      return 'Suit';
    }

    return 'Clothing';
  }

  String inferStyle({
    required String category,
    required List<String> colors,
    String? labelHint,
  }) {
    final categoryValue = category.toLowerCase();
    final hint = (labelHint ?? '').toLowerCase();
    final normalizedColors = colors.map((c) => c.toLowerCase()).toList();

    if (_containsAny(hint, ['formal', 'blazer', 'suit'])) {
      return 'Formal';
    }

    if (categoryValue == 'suit' || categoryValue == 'jacket' || _containsAny(categoryValue, ['coat', 'blazer'])) {
      if (_containsAny(normalizedColors.join(' '), ['black', 'navy', 'gray', 'grey', 'white'])) {
        return 'Formal';
      }
    }

    if (_containsAny(normalizedColors.join(' '), ['white', 'beige', 'gray', 'grey', 'black'])) {
      return 'Classic';
    }

    return 'Casual';
  }

  String? inferPattern({
    required String category,
    required List<String> colors,
    String? labelHint,
  }) {
    final hint = (labelHint ?? '').toLowerCase();
    final normalizedColors = colors.map((c) => c.toLowerCase()).toList();

    if (_containsAny(hint, ['stripe', 'striped'])) {
      return 'Striped';
    }
    if (_containsAny(hint, ['check', 'checked', 'plaid'])) {
      return 'Checkered';
    }
    if (_containsAny(hint, ['floral', 'flower'])) {
      return 'Floral';
    }
    if (_containsAny(hint, ['dot', 'dotted', 'polka'])) {
      return 'Dotted';
    }

    final hasLight = _containsAny(normalizedColors.join(' '), ['white', 'beige', 'yellow', 'pink']);
    final hasDark = _containsAny(normalizedColors.join(' '), ['black', 'navy', 'gray', 'grey', 'brown']);
    if (hasLight && hasDark && category.toLowerCase() != 'shoes') {
      return normalizedColors.length > 2 ? 'Checkered' : 'Striped';
    }

    if (_containsAny(normalizedColors.join(' '), ['pink', 'green', 'red']) && category.toLowerCase() == 'dress') {
      return 'Floral';
    }

    return 'Solid';
  }

  bool _containsAny(String value, List<String> needles) {
    return needles.any(value.contains);
  }
}