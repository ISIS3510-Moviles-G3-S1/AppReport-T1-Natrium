import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class VisionPhotoQualityResult {
  final bool isBlurry;
  final bool isUnderexposed;
  final bool isOverexposed;
  final double blurLikelihood;
  final double exposureLikelihood;
  final String? error;

  VisionPhotoQualityResult({
    required this.isBlurry,
    required this.isUnderexposed,
    required this.isOverexposed,
    required this.blurLikelihood,
    required this.exposureLikelihood,
    this.error,
  });
}

class VisionPhotoQualityService {
  static const String _defaultEmbeddedApiKey = 'AIzaSyCDK12s_JVFxbtv-Wyn2AkI7LdDIYtpFSY';
  static const _visionUrl = 'https://vision.googleapis.com/v1/images:annotate';

  final String _apiKey;
  final http.Client _httpClient;

  VisionPhotoQualityService({String? apiKey, http.Client? httpClient})
      : _apiKey = (apiKey ?? _defaultEmbeddedApiKey).trim(),
        _httpClient = httpClient ?? http.Client();

  Future<VisionPhotoQualityResult> analyzePhoto(XFile image) async {
    final bytes = await image.readAsBytes();
    return analyzeBytes(bytes, fileName: image.name);
  }

  Future<VisionPhotoQualityResult> analyzeBytes(Uint8List bytes, {String? fileName}) async {
    if (bytes.isEmpty) {
      return VisionPhotoQualityResult(
        isBlurry: false,
        isUnderexposed: false,
        isOverexposed: false,
        blurLikelihood: 0.0,
        exposureLikelihood: 0.0,
        error: 'Invalid image',
      );
    }
    if (_apiKey.isEmpty) {
      return VisionPhotoQualityResult(
        isBlurry: false,
        isUnderexposed: false,
        isOverexposed: false,
        blurLikelihood: 0.0,
        exposureLikelihood: 0.0,
        error: 'API key missing',
      );
    }
    final payload = {
      'requests': [
        {
          'image': {'content': base64Encode(bytes)},
          'features': [
            {'type': 'IMAGE_PROPERTIES', 'maxResults': 1},
            {'type': 'LABEL_DETECTION', 'maxResults': 10},
          ],
        }
      ]
    };
    final uri = Uri.parse('$_visionUrl?key=$_apiKey');
    final response = await _httpClient.post(uri, body: jsonEncode(payload), headers: {'Content-Type': 'application/json'});
    if (response.statusCode != 200) {
      return VisionPhotoQualityResult(
        isBlurry: false,
        isUnderexposed: false,
        isOverexposed: false,
        blurLikelihood: 0.0,
        exposureLikelihood: 0.0,
        error: 'Vision API error: ${response.statusCode}',
      );
    }
    final data = jsonDecode(response.body);
    try {
      final resp = data['responses'][0];
      // Check for blur using LABEL_DETECTION (improved sensitivity)
      final labels = resp['labelAnnotations'] as List<dynamic>? ?? [];
      bool isBlurry = false;
      double blurLikelihood = 0.0;
      double sharpScore = 0.0;
      double focusScore = 0.0;
      for (final label in labels) {
        final desc = (label['description'] as String).toLowerCase();
        final score = (label['score'] as num?)?.toDouble() ?? 0.0;
        if (desc.contains('blurry')) {
          isBlurry = true;
          blurLikelihood = score;
        }
        if (desc.contains('sharp')) {
          sharpScore = score;
        }
        if (desc.contains('focus')) {
          focusScore = score;
        }
      }
      // If not labeled blurry, but sharp/focus confidence is low, treat as blurry
      if (!isBlurry && (sharpScore < 0.5 && focusScore < 0.5)) {
        isBlurry = true;
        blurLikelihood = 0.2; // Assign a moderate blur likelihood
      }
      // Check for exposure using IMAGE_PROPERTIES
      final props = resp['imagePropertiesAnnotation']?['dominantColors']?['colors'] as List<dynamic>? ?? [];
      double avgBrightness = 0.0;
      if (props.isNotEmpty) {
        for (final c in props) {
          avgBrightness += (c['color']['red'] as num) * 0.299 + (c['color']['green'] as num) * 0.587 + (c['color']['blue'] as num) * 0.114;
        }
        avgBrightness /= props.length;
      }
      // Heuristic: <60 underexposed, >200 overexposed
      bool isUnderexposed = avgBrightness < 60;
      bool isOverexposed = avgBrightness > 200;
      double exposureLikelihood = avgBrightness / 255.0;
      return VisionPhotoQualityResult(
        isBlurry: isBlurry,
        isUnderexposed: isUnderexposed,
        isOverexposed: isOverexposed,
        blurLikelihood: blurLikelihood,
        exposureLikelihood: exposureLikelihood,
        error: null,
      );
    } catch (e) {
      return VisionPhotoQualityResult(
        isBlurry: false,
        isUnderexposed: false,
        isOverexposed: false,
        blurLikelihood: 0.0,
        exposureLikelihood: 0.0,
        error: 'Parsing error: $e',
      );
    }
  }
}
