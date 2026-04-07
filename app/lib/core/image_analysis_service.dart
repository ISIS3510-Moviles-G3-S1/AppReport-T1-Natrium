import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/analysis_result.dart';
import '../models/clothing_tag.dart';
import 'analysis_error.dart';
import 'clothing_category_mapper.dart';
import 'color_analyzer.dart';

abstract class ImageAnalysisService {
  Future<AnalysisResult> analyzeImage(XFile image);
  Future<AnalysisResult> analyzeBytes(Uint8List bytes, {String? fileName});
}

class CloudVisionImageAnalysisService implements ImageAnalysisService {
  // Read from --dart-define=GOOGLE_CLOUD_VISION_API_KEY=... at build/run time.
  static const String _visionApiKeyFromEnv = String.fromEnvironment(
    'GOOGLE_CLOUD_VISION_API_KEY',
  );

  CloudVisionImageAnalysisService({
    String? apiKey,
    http.Client? httpClient,
    ClothingCategoryMapper? categoryMapper,
    ImageAnalysisService? fallbackService,
  })  : _apiKey = (apiKey ?? _visionApiKeyFromEnv).trim(),
        _httpClient = httpClient ?? http.Client(),
        _categoryMapper = categoryMapper ?? ClothingCategoryMapper(),
        _fallbackService = fallbackService ?? MockClothingAnalysisService();

  final String _apiKey;
  final http.Client _httpClient;
  final ClothingCategoryMapper _categoryMapper;
  final ImageAnalysisService _fallbackService;

  static const _visionUrl = 'https://vision.googleapis.com/v1/images:annotate';

  @override
  Future<AnalysisResult> analyzeImage(XFile image) async {
    final bytes = await image.readAsBytes();
    return analyzeBytes(bytes, fileName: image.name);
  }

  @override
  Future<AnalysisResult> analyzeBytes(Uint8List bytes, {String? fileName}) async {
    if (bytes.isEmpty) {
      throw const AnalysisError.invalidImage();
    }

    if (_apiKey.isEmpty) {
      debugPrint('[CloudVision] API key missing; using fallback analyzer. file=$fileName');
      return _fallbackService.analyzeBytes(bytes, fileName: fileName);
    }

    final stopwatch = Stopwatch()..start();

    try {
      final response = await _sendRequest(bytes, fileName: fileName);
      final parsed = _parseResponse(response, stopwatch.elapsedMilliseconds, fileName: fileName);
      debugPrint('[CloudVision] analysis ok file=$fileName category=${parsed.category} colors=${parsed.colors.join(', ')}');
      return parsed;
    } on _NoResultsError {
      debugPrint('[CloudVision] parsed result empty; using fallback analyzer. file=$fileName');
      return _fallbackService.analyzeBytes(bytes, fileName: fileName);
    } on AnalysisError {
      rethrow;
    } catch (e) {
      debugPrint('[CloudVision] analysis failed file=$fileName error=$e');
      return _fallbackService.analyzeBytes(bytes, fileName: fileName);
    }
  }

  Future<Map<String, dynamic>> _sendRequest(Uint8List bytes, {String? fileName}) async {
    final payload = <String, dynamic>{
      'requests': [
        {
          'image': {'content': base64Encode(bytes)},
          'features': [
            {'type': 'LABEL_DETECTION', 'maxResults': 12},
            {'type': 'OBJECT_LOCALIZATION', 'maxResults': 12},
            {'type': 'IMAGE_PROPERTIES', 'maxResults': 5},
          ],
        },
      ],
    };

    debugPrint('[CloudVision] request start file=$fileName bytes=${bytes.length}');

    final uri = Uri.parse('$_visionUrl?key=$_apiKey');
    final response = await _httpClient.post(
      uri,
      headers: const {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(payload),
    );

    debugPrint('[CloudVision] response status=${response.statusCode} file=$fileName');

    if (response.statusCode != 200) {
      throw AnalysisError.processingFailed('Cloud Vision HTTP ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AnalysisError.noResults();
    }

    final responses = decoded['responses'];
    if (responses is! List || responses.isEmpty) {
      throw const AnalysisError.noResults();
    }

    final first = _firstOrNull(responses.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList());
    if (first == null) {
      throw const AnalysisError.noResults();
    }

    if (first['error'] is Map) {
      throw AnalysisError.processingFailed(first['error'].toString());
    }

    return first;
  }

  AnalysisResult _parseResponse(Map<String, dynamic> response, int processingTimeMs, {String? fileName}) {
    final labels = _parseLabels(response);
    final labelTexts = labels.map((e) => e.description).toList();
    final dominantColors = _extractDominantColors(response);
    final colorNames = dominantColors.map((c) => c.name).toList();

    debugPrint('[CloudVision] raw labels file=$fileName => ${labelTexts.isEmpty ? '[]' : labelTexts.join(' | ')}');
    debugPrint('[CloudVision] raw colors file=$fileName => ${colorNames.isEmpty ? '[]' : colorNames.join(' | ')}');

    final categoryLabel = _findBestCategoryLabel(labels);
    final category = categoryLabel == null
        ? 'unknown'
        : _categoryMapper.mapLabelToCategory(categoryLabel.description);
    debugPrint('[CloudVision] mapped category file=$fileName => ${categoryLabel?.description ?? 'none'} -> $category');

    final style = _categoryMapper.inferStyle(
      category: category,
      colors: colorNames,
      labelHint: labelTexts.join(' '),
    );
    final pattern = _categoryMapper.inferPattern(
          category: category,
          colors: colorNames,
          labelHint: labelTexts.join(' '),
        ) ??
        'Solid';

    debugPrint('[CloudVision] derived style file=$fileName => $style');
    debugPrint('[CloudVision] derived pattern file=$fileName => $pattern');

    if (labels.isEmpty && dominantColors.isEmpty) {
      debugPrint('[CloudVision] empty parse result file=$fileName; fallback required');
      throw const _NoResultsError();
    }

    final categoryConfidence = categoryLabel?.score ?? 0.5;
    final tags = <ClothingTag>[
      ClothingTag(
        id: generateClothingTagId(),
        name: category,
        confidence: categoryConfidence,
        category: TagCategory.category,
      ),
      ...dominantColors.map(
        (color) => ClothingTag(
          id: generateClothingTagId(),
          name: color.name,
          confidence: color.confidence,
          category: TagCategory.color,
        ),
      ),
      ClothingTag(
        id: generateClothingTagId(),
        name: style,
        confidence: _styleConfidence(style, labels),
        category: TagCategory.style,
      ),
      ClothingTag(
        id: generateClothingTagId(),
        name: pattern,
        confidence: _patternConfidence(pattern, labels),
        category: TagCategory.pattern,
      ),
    ];

    return AnalysisResult(
      category: category,
      colors: colorNames,
      style: style,
      pattern: pattern,
      confidence: _averageConfidence(tags.map((e) => e.confidence).toList()),
      processingTimeMs: processingTimeMs,
      allTags: tags,
      timestamp: DateTime.now(),
    );
  }

  List<_VisionLabel> _parseLabels(Map<String, dynamic> response) {
    final labelAnnotations = (response['labelAnnotations'] as List?) ?? const [];
    final localizedObjectAnnotations = (response['localizedObjectAnnotations'] as List?) ?? const [];

    final labels = <_VisionLabel>[];

    for (final raw in labelAnnotations.whereType<Map>()) {
      final parsed = _VisionLabel.fromJson(Map<String, dynamic>.from(raw));
      if (parsed.description.trim().isNotEmpty) {
        labels.add(parsed);
      }
    }

    for (final raw in localizedObjectAnnotations.whereType<Map>()) {
      final json = Map<String, dynamic>.from(raw);
      final parsed = _VisionLabel(
        description: (json['name'] ?? '').toString(),
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
      );
      if (parsed.description.trim().isNotEmpty) {
        labels.add(parsed);
      }
    }

    labels.sort((a, b) => b.score.compareTo(a.score));
    return labels;
  }

  List<_DominantColorTag> _extractDominantColors(Map<String, dynamic> response) {
    final properties = response['imagePropertiesAnnotation'];
    if (properties is! Map<String, dynamic>) {
      debugPrint('[CloudVision] imagePropertiesAnnotation missing');
      return const [];
    }

    final dominantColors = properties['dominantColors'];
    if (dominantColors is! Map<String, dynamic>) {
      debugPrint('[CloudVision] dominantColors missing');
      return const [];
    }

    final entries = dominantColors['colors'];
    if (entries is! List || entries.isEmpty) {
      debugPrint('[CloudVision] dominantColors.colors empty');
      return const [];
    }

    final extracted = <_DominantColorTag>[];
    final seen = <String>{};

    for (final entry in entries.whereType<Map>()) {
      final map = Map<String, dynamic>.from(entry);
      final color = map['color'];
      if (color is! Map) continue;

      final rgb = Map<String, dynamic>.from(color);
      final name = _nearestColorName(
        (rgb['red'] as num?)?.toInt() ?? 0,
        (rgb['green'] as num?)?.toInt() ?? 0,
        (rgb['blue'] as num?)?.toInt() ?? 0,
      );

      if (seen.add(name)) {
        final confidence = ((map['score'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0);
        extracted.add(_DominantColorTag(name: name, confidence: confidence));
        debugPrint('[CloudVision] color parsed => $name confidence=$confidence');
      }

      if (extracted.length >= 3) break;
    }

    debugPrint('[CloudVision] parsed colors count=${extracted.length}');
    return extracted;
  }

  _VisionLabel? _findBestCategoryLabel(List<_VisionLabel> labels) {
    if (labels.isEmpty) {
      debugPrint('[CloudVision] no labels found; category will be unknown');
      return null;
    }

    for (final label in labels) {
      final mapped = _categoryMapper.mapLabelToCategory(label.description);
      debugPrint('[CloudVision] label mapped ${label.description} -> $mapped');
      if (mapped != 'Clothing') {
        return label;
      }
    }

    return null;
  }

  double _styleConfidence(String style, List<_VisionLabel> labels) {
    final hit = labels.any((label) => label.description.toLowerCase().contains(style.toLowerCase()));
    return hit ? 0.74 : 0.62;
  }

  double _patternConfidence(String pattern, List<_VisionLabel> labels) {
    final hit = labels.any((label) => label.description.toLowerCase().contains(pattern.toLowerCase()));
    return hit ? 0.72 : 0.56;
  }

  String _nearestColorName(int red, int green, int blue) {
    const known = <String, List<int>>{
      'Black': [0, 0, 0],
      'White': [255, 255, 255],
      'Gray': [128, 128, 128],
      'Navy': [25, 42, 86],
      'Blue': [33, 150, 243],
      'Teal': [0, 128, 128],
      'Green': [76, 175, 80],
      'Yellow': [255, 235, 59],
      'Orange': [255, 152, 0],
      'Red': [244, 67, 54],
      'Pink': [233, 30, 99],
      'Purple': [156, 39, 176],
      'Brown': [141, 110, 99],
      'Beige': [245, 230, 196],
      'Tan': [210, 180, 140],
    };

    String best = 'Blue';
    var bestDistance = double.infinity;

    for (final entry in known.entries) {
      final dr = red - entry.value[0];
      final dg = green - entry.value[1];
      final db = blue - entry.value[2];
      final distance = (dr * dr + dg * dg + db * db).toDouble();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = entry.key;
      }
    }

    return best;
  }

  double _averageConfidence(List<double> values) {
    if (values.isEmpty) return 0.0;
    final total = values.fold<double>(0, (sum, value) => sum + value);
    return (total / values.length).clamp(0.0, 1.0);
  }

  T? _firstOrNull<T>(List<T> values) {
    if (values.isEmpty) return null;
    return values[0];
  }
}

class _VisionLabel {
  final String description;
  final double score;

  const _VisionLabel({required this.description, required this.score});

  factory _VisionLabel.fromJson(Map<String, dynamic> json) {
    return _VisionLabel(
      description: (json['description'] ?? '').toString(),
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class _DominantColorTag {
  final String name;
  final double confidence;

  const _DominantColorTag({required this.name, required this.confidence});
}

class MockClothingAnalysisService implements ImageAnalysisService {
  MockClothingAnalysisService({
    ColorAnalyzer? colorAnalyzer,
    ClothingCategoryMapper? categoryMapper,
  })  : _colorAnalyzer = colorAnalyzer ?? ColorAnalyzer(),
        _categoryMapper = categoryMapper ?? ClothingCategoryMapper();

  final ColorAnalyzer _colorAnalyzer;
  final ClothingCategoryMapper _categoryMapper;

  @override
  Future<AnalysisResult> analyzeImage(XFile image) async {
    final bytes = await image.readAsBytes();
    return analyzeBytes(bytes, fileName: image.name);
  }

  @override
  Future<AnalysisResult> analyzeBytes(Uint8List bytes, {String? fileName}) async {
    if (bytes.isEmpty) {
      throw const AnalysisError.invalidImage();
    }

    final stopwatch = Stopwatch()..start();

    try {
      final colors = await _colorAnalyzer.extractDominantColors(bytes, maxColors: 3);
      final primary = _pickPrimaryCategory(bytes, colors);
      final category = _categoryMapper.mapLabelToCategory(primary);
      final style = _categoryMapper.inferStyle(
        category: category,
        colors: colors,
        labelHint: primary,
      );
      final pattern = _categoryMapper.inferPattern(
            category: category,
            colors: colors,
            labelHint: primary,
          ) ??
          'Solid';

      final categoryConfidence = _confidenceForCategory(category);
      final colorConfidence = [0.92, 0.84, 0.76].take(colors.length).toList();

      final tags = <ClothingTag>[
        ClothingTag(
          id: generateClothingTagId(),
          name: category,
          confidence: categoryConfidence,
          category: TagCategory.category,
        ),
        for (var i = 0; i < colors.length; i++)
          ClothingTag(
            id: generateClothingTagId(),
            name: colors[i],
            confidence: colorConfidence[i],
            category: TagCategory.color,
          ),
        ClothingTag(
          id: generateClothingTagId(),
          name: style,
          confidence: 0.66,
          category: TagCategory.style,
        ),
        ClothingTag(
          id: generateClothingTagId(),
          name: pattern,
          confidence: 0.58,
          category: TagCategory.pattern,
        ),
      ];

      stopwatch.stop();

      return AnalysisResult(
        category: category,
        colors: colors,
        style: style,
        pattern: pattern,
        confidence: _averageConfidence(tags.map((e) => e.confidence).toList()),
        processingTimeMs: stopwatch.elapsedMilliseconds,
        allTags: tags,
        timestamp: DateTime.now(),
      );
    } on AnalysisError {
      rethrow;
    } catch (e) {
      throw AnalysisError.processingFailed(e.toString());
    }
  }

  String _pickPrimaryCategory(Uint8List bytes, List<String> colors) {
    final signature = bytes.fold<int>(0, (sum, byte) => (sum + byte) & 0x7fffffff);
    final dominant = colors.isNotEmpty ? colors.first.toLowerCase() : 'blue';

    if (_containsAny(dominant, ['black', 'gray', 'grey', 'navy'])) {
      return ['Shirt', 'Jacket', 'Jeans', 'Sweater', 'Shoes'][signature % 5];
    }
    if (_containsAny(dominant, ['blue', 'teal', 'cyan'])) {
      return ['Shirt', 'Jeans', 'Sweater', 'Jacket', 'Shoes'][(signature + 1) % 5];
    }
    if (_containsAny(dominant, ['red', 'pink', 'orange', 'yellow'])) {
      return ['Shirt', 'Dress', 'Sweater', 'Jacket', 'Shoes'][(signature + 2) % 5];
    }
    if (_containsAny(dominant, ['white', 'beige', 'tan'])) {
      return ['Shirt', 'Pants', 'Dress', 'Jacket', 'Accessory'][(signature + 3) % 5];
    }

    return ['Shirt', 'Jeans', 'Sweater', 'Jacket', 'Shoes'][signature % 5];
  }

  double _confidenceForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'shirt':
        return 0.75;
      case 'pants':
        return 0.68;
      case 'dress':
        return 0.66;
      case 'jacket':
        return 0.62;
      case 'shoes':
        return 0.48;
      case 'accessory':
        return 0.55;
      case 'suit':
        return 0.61;
      default:
        return 0.50;
    }
  }

  double _averageConfidence(List<double> values) {
    if (values.isEmpty) return 0.0;
    final total = values.fold<double>(0, (sum, value) => sum + value);
    return (total / values.length).clamp(0.0, 1.0);
  }

  bool _containsAny(String value, List<String> needles) => needles.any(value.contains);
}

class _NoResultsError implements Exception {
  const _NoResultsError();
}
