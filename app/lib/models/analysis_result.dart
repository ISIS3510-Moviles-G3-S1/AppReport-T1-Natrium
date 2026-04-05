import 'clothing_tag.dart';

class AnalysisResult {
  final String category;
  final List<String> colors;
  final String? style;
  final String? pattern;
  final double confidence;
  final int processingTimeMs;
  final List<ClothingTag> allTags;
  final DateTime timestamp;

  const AnalysisResult({
    required this.category,
    required this.colors,
    required this.style,
    required this.pattern,
    required this.confidence,
    required this.processingTimeMs,
    required this.allTags,
    required this.timestamp,
  });

  AnalysisResult copyWith({
    String? category,
    List<String>? colors,
    String? style,
    String? pattern,
    double? confidence,
    int? processingTimeMs,
    List<ClothingTag>? allTags,
    DateTime? timestamp,
  }) {
    return AnalysisResult(
      category: category ?? this.category,
      colors: colors ?? this.colors,
      style: style ?? this.style,
      pattern: pattern ?? this.pattern,
      confidence: confidence ?? this.confidence,
      processingTimeMs: processingTimeMs ?? this.processingTimeMs,
      allTags: allTags ?? this.allTags,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, List<String>> toListingTagsMap() {
    return {
      'category': category.isEmpty ? const [] : [category],
      'color': List<String>.from(colors),
      if (style != null && style!.isNotEmpty) 'style': [style!],
      if (pattern != null && pattern!.isNotEmpty) 'pattern': [pattern!],
    };
  }
}