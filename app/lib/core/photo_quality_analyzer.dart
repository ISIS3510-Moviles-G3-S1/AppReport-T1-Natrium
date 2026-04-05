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

    // Resolution
    print('[PhotoQualityAnalyzer] Resolution: ${image.width}x${image.height}');
    if (image.width < minWidth || image.height < minHeight) {
      issues.add('LOW_RESOLUTION');
      suggestions.add('Use a higher resolution image.');
      score -= 0.2;
    }

    // Clamp score
    score = score.clamp(0.0, 1.0);

    return PhotoQualityResult(
      qualityScore: score,
      issues: issues,
      suggestions: suggestions,
    );
  }

  static double _analyzeBrightness(img.Image image) {
    int sum = 0;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        // Use only bitwise extraction for compatibility with image >=4.0.0
        final r = (pixel >> 16) & 0xFF;
        final g = (pixel >> 8) & 0xFF;
        final b = pixel & 0xFF;
        final gray = (0.299 * r + 0.587 * g + 0.114 * b).round();
        sum += gray;
      }
    }
    return sum / (image.width * image.height);
  }

  static double _analyzeBlur(img.Image image) {
    // Laplacian variance (approximation)
    final gray = img.grayscale(image);
    final lap = img.convolution(gray, [
      0,  1, 0,
      1, -4, 1,
      0,  1, 0,
    ]);
    final pixels = lap.getBytes();
    final mean = pixels.reduce((a, b) => a + b) / pixels.length;
    final variance = pixels.map((p) => (p - mean) * (p - mean)).reduce((a, b) => a + b) / pixels.length;
    return variance;
  }
}
