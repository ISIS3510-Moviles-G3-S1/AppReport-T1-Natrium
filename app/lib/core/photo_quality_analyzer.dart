import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class PhotoQualityResult {
  final double qualityScore;
  final List<String> issues;
  final List<String> suggestions;

  PhotoQualityResult({
    required this.qualityScore,
    required this.issues,
    required this.suggestions,
  });

  Map<String, dynamic> toJson() => {
        'qualityScore': qualityScore,
        'issues': issues,
        'suggestions': suggestions,
      };
}

class PhotoQualityAnalyzer {
  static const double minBrightness = 60.0; // 0-255
  static const double minBlurVariance = 100.0;
  static const int minWidth = 300;
  static const int minHeight = 300;
  static const double minObjectRatio = 0.4; // Optional

  static Future<PhotoQualityResult> analyze(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      return PhotoQualityResult(
        qualityScore: 0.0,
        issues: ['INVALID_IMAGE'],
        suggestions: ['The image could not be processed.'],
      );
    }

    final issues = <String>[];
    final suggestions = <String>[];
    double score = 1.0;

    // Brightness
    final brightness = _analyzeBrightness(image);
    print('[PhotoQualityAnalyzer] Brightness: $brightness');
    if (brightness < minBrightness) {
      issues.add('LOW_LIGHT');
      suggestions.add('Try taking the photo in a brighter area.');
      score -= 0.3;
    }

    // Blur
    final blur = _analyzeBlur(image);
    print('[PhotoQualityAnalyzer] Blur (variance): $blur');
    if (blur < minBlurVariance) {
      issues.add('BLURRY');
      suggestions.add('Hold the camera steady and retake the picture.');
      score -= 0.3;
    }

    // Archivo eliminado: PhotoQualityAnalyzer ya no se usa en la app.
    final pixels = lap.getBytes();
    final mean = pixels.reduce((a, b) => a + b) / pixels.length;
    final variance = pixels.map((p) => (p - mean) * (p - mean)).reduce((a, b) => a + b) / pixels.length;
    return variance;
  }
}
