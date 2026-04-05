import 'package:flutter/material.dart';

import '../../models/clothing_tag.dart';

class TagChipWidget extends StatelessWidget {
  final ClothingTag tag;
  final VoidCallback? onRemove;
  final bool showRemoveButton;

  const TagChipWidget({
    super.key,
    required this.tag,
    this.onRemove,
    this.showRemoveButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorForCategory(tag.category);
    final textColor = _textColorForBackground(color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${tag.name} · ${(tag.confidence * 100).round()}%',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          if (showRemoveButton && onRemove != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: textColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _colorForCategory(TagCategory category) {
    return switch (category) {
      TagCategory.category => Colors.green.shade200,
      TagCategory.color => Colors.amber.shade200,
      TagCategory.style => Colors.blue.shade200,
      TagCategory.pattern => Colors.purple.shade200,
    };
  }

  Color _textColorForBackground(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.65 ? Colors.black87 : Colors.white;
  }
}