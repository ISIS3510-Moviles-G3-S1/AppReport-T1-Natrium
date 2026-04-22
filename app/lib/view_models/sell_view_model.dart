import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../core/photo_quality_analyzer.dart';
import 'package:flutter/material.dart';
import '../core/analytics_event.dart';
import '../core/analytics_service.dart';
import '../data/listing_service.dart';
import '../models/listing.dart';
import 'session_view_model.dart';

class SellViewModel extends ChangeNotifier {
  SellViewModel(this._session);

  static const int titleMaxLength = 80;
  static const int descriptionMinLength = 10;
  static const int descriptionMaxLength = 300;

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

  bool get _hasNegativePriceSign => _price.contains('-');

  int get parsedPrice {
    if (_hasNegativePriceSign) return 0;
    return int.tryParse(_price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  String? get titleError {
    final value = _title.trim();
    if (value.isEmpty) return 'Title is required.';
    if (value.length > titleMaxLength) {
      return 'Title must be at most $titleMaxLength characters.';
    }
    return null;
  }

  String? get priceError {
    final raw = _price.trim();
    if (raw.isEmpty) return 'Price is required.';
    if (_hasNegativePriceSign) return 'Price cannot be negative.';
    if (parsedPrice <= 0) return 'Price must be greater than 0.';
    return null;
  }

  String? get tagsError {
    return null;
  }

  String? get descriptionError {
    final value = _description.trim();
    if (value.isEmpty) return 'Description is required.';
    if (value.length < descriptionMinLength) {
      return 'Description must be at least $descriptionMinLength characters.';
    }
    if (value.length > descriptionMaxLength) {
      return 'Description must be at most $descriptionMaxLength characters.';
    }
    if (RegExp(r'^\d+$').hasMatch(value)) {
      return 'Description cannot contain only numbers.';
    }
    return null;
  }

  String? get imageError {
    if (_images.isEmpty) return 'Add at least one photo.';
    return null;
  }

  String? get firstPublishValidationError {
    return imageError ?? titleError ?? priceError ?? descriptionError;
  }

  bool get canPublish => firstPublishValidationError == null;

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
    final validationError = firstPublishValidationError;
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    if (_tags.isEmpty) {
      final online = await _listingService.isOnlineNow();
      if (online) {
        throw ArgumentError('Add at least one tag, or publish while offline to use automatic tag generation later.');
      }
    }

    final user = _session.currentUser;
    final sellerName = user == null
        ? 'Me'
        : (user.displayName.trim().isNotEmpty
            ? user.displayName
            : user.email.split('@').first);

    // Soporte para múltiples imágenes
    final listing = Listing(
      id: '', // Se asignará por Firestore
      sellerId: '', // Se asignará en ListingService
      title: _title.trim(),
      price: parsedPrice,
      conditionTag: _condition,
      description: _description.trim(),
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

    final userId = user?.uid ?? '';
    if (userId.isNotEmpty) {
      // Use the first tag as category, or 'Other' if none
      final category = _tags.isNotEmpty ? _tags[0] : 'Other';
      AnalyticsService.instance.track(
        AnalyticsEvent.userMeaningfulInteraction(
          userId: userId,
          interactionType: 'sell',
          timestamp: DateTime.now().toUtc().toIso8601String(),
          category: category,
        ),
      );
    }

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
