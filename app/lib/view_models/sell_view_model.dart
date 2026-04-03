import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../core/photo_quality_analyzer.dart';
import 'package:flutter/material.dart';
import '../data/listing_service.dart';
import '../models/listing.dart';
import 'session_view_model.dart';

class SellViewModel extends ChangeNotifier {
  SellViewModel(this._session);

  final ListingService _listingService = ListingService();
  SessionViewModel _session;

  void updateSession(SessionViewModel session) {
    _session = session;
  }

  bool _published = false;

  String _title = '';
  String _description = '';
  String _price = '';
  String _condition = 'Good';
  String _exchangeType = 'sell';
  List<String> _tags = [];
  String _tagsInput = '';
  List<XFile> _images = [];

  bool get published => _published;

  String get title => _title;
  set title(String v) {
    _title = v;
    notifyListeners();
  }

  String get description => _description;
  set description(String v) {
    _description = v;
    notifyListeners();
  }

  String get price => _price;
  set price(String v) {
    _price = v;
    notifyListeners();
  }

  String get condition => _condition;
  set condition(String v) {
    _condition = v;
    notifyListeners();
  }

  String get exchangeType => _exchangeType;
  set exchangeType(String v) {
    _exchangeType = v;
    notifyListeners();
  }

  List<String> get tags => _tags;
  set tags(List<String> v) {
    _tags = v;
    _tagsInput = _tags.join(', ');
    notifyListeners();
  }

  String get tagsInput => _tagsInput;
  set tagsInput(String v) {
    _tagsInput = v;
    _tags = _parseTags(v);
    notifyListeners();
  }

  List<XFile> get images => _images;

  List<String> _parseTags(String value) {
    return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  void applyAnalysisTags(Map<String, List<String>> tags) {
    final ordered = <String>[];
    for (final key in const ['category', 'color', 'style', 'pattern']) {
      ordered.addAll(tags[key] ?? const []);
    }

    _tags = ordered;
    _tagsInput = ordered.join(', ');

    if (_title.isEmpty && (tags['category']?.isNotEmpty ?? false)) {
      _title = tags['category']!.first;
    }

    notifyListeners();
  }

  /// Returns true if the photo should be kept, false if retake is requested.
  Future<bool> analyzeAndPromptPhoto(BuildContext context, XFile file) async {
    final result = await PhotoQualityAnalyzer.analyze(File(file.path));
    if (result.qualityScore < 0.5) {
      final choice = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Photo Quality Warning'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This photo may not be suitable:'),
              const SizedBox(height: 8),
              ...result.suggestions.map((s) => Text('• $s')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Retake'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Keep'),
            ),
          ],
        ),
      );
      return choice == true;
    }
    return true;
  }

  // (keep only one addImage method)

  void addImage(XFile file) {
    if (_images.length < 5) {
      _images.add(file);
      debugPrint('[SellVM] add image: ${file.name}');
      notifyListeners();
    }
  }

  void removeImageAt(int index) {
    if (index >= 0 && index < _images.length) {
      _images.removeAt(index);
      notifyListeners();
    }
  }

  Future<void> publish() async {
    final user = _session.currentUser;
    final sellerName = user == null
        ? 'Me'
        : (user.displayName.trim().isNotEmpty
            ? user.displayName
            : user.email.split('@').first);
    final parsedPrice = int.tryParse(_price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    // Soporte para múltiples imágenes
    final listing = Listing(
      id: '', // Se asignará por Firestore
      sellerId: '', // Se asignará en ListingService
      title: _title,
      price: parsedPrice,
      conditionTag: _condition,
      description: _description,
      sellerName: sellerName,
      exchangeType: _exchangeType,
      tags: _tags,
      rating: 0,
      imageName: '',
      createdAt: null,
      soldAt: null,
      imagePath: '',
      imageURLs: const [],
      status: 'active',
      saved: false,
    );
    debugPrint('[SellVM] publishing ${_images.length} selected images');
    await _listingService.createListing(listing: listing, images: _images);
    _published = true;
    notifyListeners();
  }

  void resetAfterPublish() {
    _published = false;
    _title = '';
    _images = [];
    _price = '';
    _condition = 'Good';
    _exchangeType = 'sell';
    _tags = [];
    _tagsInput = '';
    notifyListeners();
  }
}
