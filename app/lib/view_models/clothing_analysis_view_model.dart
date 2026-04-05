import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../core/analysis_error.dart';
import '../core/image_analysis_service.dart';
import '../models/analysis_result.dart';
import '../models/clothing_tag.dart';

enum ClothingAnalysisStatus { initial, loading, results, error }

class ClothingAnalysisViewModel extends ChangeNotifier {
  ClothingAnalysisViewModel({
    ImageAnalysisService? analysisService,
    XFile? initialImage,
  })  : _analysisService = analysisService ?? CloudVisionImageAnalysisService(),
        _selectedImage = initialImage {
    if (initialImage != null) {
      Future.microtask(_startInitialAnalysis);
    }
  }

  final ImageAnalysisService _analysisService;
  final ImagePicker _picker = ImagePicker();

  ClothingAnalysisStatus _status = ClothingAnalysisStatus.initial;
  AnalysisResult? _result;
  AnalysisError? _error;
  XFile? _selectedImage;

  ClothingAnalysisStatus get status => _status;
  AnalysisResult? get result => _result;
  AnalysisError? get error => _error;
  XFile? get selectedImage => _selectedImage;

  bool get isLoading => _status == ClothingAnalysisStatus.loading;

  List<ClothingTag> get editableTags => List.unmodifiable(_result?.allTags ?? const []);

  List<ClothingTag> tagsFor(TagCategory category) {
    return editableTags.where((tag) => tag.category == category).toList();
  }

  Future<void> takePhoto() async {
    final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (image == null) return;
    await analyze(image);
  }

  Future<void> chooseFromGallery() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (image == null) return;
    await analyze(image);
  }

  Future<void> analyze(XFile image) async {
    _selectedImage = image;
    debugPrint('[ClothingAnalysisVM] analyze start name=${image.name} path=${image.path}');
    _status = ClothingAnalysisStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _result = await _analysisService.analyzeImage(image);
      _status = ClothingAnalysisStatus.results;
      debugPrint('[ClothingAnalysisVM] analyze result category=${_result?.category} colors=${_result?.colors.join(', ')}');
    } on AnalysisError catch (error) {
      _error = error;
      _status = ClothingAnalysisStatus.error;
      debugPrint('[ClothingAnalysisVM] analysis error ${error.userMessage}');
    } catch (error) {
      _error = AnalysisError.processingFailed(error.toString());
      _status = ClothingAnalysisStatus.error;
      debugPrint('[ClothingAnalysisVM] unexpected analysis error: $error');
    }

    notifyListeners();
  }

  Future<void> _startInitialAnalysis() async {
    final image = _selectedImage;
    if (image == null) return;
    await analyze(image);
  }

  Future<void> retry() async {
    final image = _selectedImage;
    if (image == null) return;
    await analyze(image);
  }

  void removeTag(String id) {
    final current = _result;
    if (current == null) return;

    final remaining = current.allTags.where((tag) => tag.id != id).toList();
    _result = _rebuildResultFromTags(current, remaining);
    _status = ClothingAnalysisStatus.results;
    notifyListeners();
  }

  void analyzeAnotherItem() {
    _status = ClothingAnalysisStatus.initial;
    _result = null;
    _error = null;
    _selectedImage = null;
    notifyListeners();
  }

  void startOver() => analyzeAnotherItem();

  Map<String, List<String>> buildListingTags() {
    return _result?.toListingTagsMap() ?? const {};
  }

  AnalysisResult _rebuildResultFromTags(AnalysisResult current, List<ClothingTag> tags) {
    final categoryTags = tags.where((tag) => tag.category == TagCategory.category).toList();
    final colorTags = tags.where((tag) => tag.category == TagCategory.color).toList();
    final styleTags = tags.where((tag) => tag.category == TagCategory.style).toList();
    final patternTags = tags.where((tag) => tag.category == TagCategory.pattern).toList();

    final category = categoryTags.isNotEmpty ? categoryTags.first.name : 'Clothing';
    final colors = colorTags.map((tag) => tag.name).toList();
    final style = styleTags.isNotEmpty ? styleTags.first.name : null;
    final pattern = patternTags.isNotEmpty ? patternTags.first.name : null;

    final confidenceValues = tags.map((tag) => tag.confidence).toList();
    final confidence = confidenceValues.isEmpty
        ? 0.0
        : confidenceValues.fold<double>(0, (sum, value) => sum + value) / confidenceValues.length;

    return current.copyWith(
      category: category,
      colors: colors,
      style: style,
      pattern: pattern,
      confidence: confidence,
      allTags: tags,
    );
  }
}