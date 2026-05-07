import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../models/item_detail.dart';
import '../models/listing.dart';
import '../models/seller.dart';
import '../data/listing_service.dart';
import '../view_models/browse_view_model.dart';

class ItemDetailViewModel extends ChangeNotifier {
  ItemDetail? _item;
  final ListingService _listingService = ListingService();
  List<Map<String, dynamic>> _similarItems = const [];
  int _activeImageIndex = 0;
  bool _saved = false;
  bool _messageSent = false;
  bool _isUpdating = false;
  bool _lastUpdateWasOffline = false;

  ItemDetail? get item => _item;
  int get activeImageIndex => _activeImageIndex;
  bool get saved => _saved;
  bool get messageSent => _messageSent;
  List<Map<String, dynamic>> get similarItems => _similarItems;
  bool get isUpdating => _isUpdating;
  bool get lastUpdateWasOffline => _lastUpdateWasOffline;

  Future<void> loadItem(String id) async {
    final listing = await _listingService.getListingById(id);
    if (listing != null) {
        final allImages = [
          ...listing.imageURLs.where((url) => url.trim().isNotEmpty),
          if (listing.imagePath.trim().isNotEmpty) listing.imagePath.trim(),
        ];
        final uniqueImages = <String>[];
        for (final image in allImages) {
          if (!uniqueImages.contains(image)) {
            uniqueImages.add(image);
          }
        }

        _item = ItemDetail(
          id: id,
          sellerId: listing.sellerId,
          name: listing.title,
          price: listing.price.toDouble(),
          condition: listing.conditionTag,
          exchangeType: listing.exchangeType,
          size: listing.size,
          seller: Seller(id: listing.sellerId, name: listing.sellerName, university: '', rating: listing.rating, sales: 0, avatar: '', verified: false),
          aiScore: 0,
          description: listing.description,
          images: uniqueImages,
          tags: listing.tags,
        );

        // Load similar real listings from Firestore and keep only active items.
        final allListings = await _listingService.getListings().first;
        _similarItems = _buildSimilarItems(currentListingId: id, listings: allListings);
    } else {
      _item = null;
      _similarItems = const [];
    }
    _activeImageIndex = 0;
    _saved = false;
    _messageSent = false;
    notifyListeners();
  }

  void setActiveImage(int index) {
    _activeImageIndex = index;
    notifyListeners();
  }

  void toggleSaved(BuildContext context) {
    if (_item != null) {
      final browseVM = Provider.of<BrowseViewModel>(context, listen: false);
      browseVM.toggleSave(_item!.id);
      _saved = browseVM.savedItems[_item!.id] ?? false;
      notifyListeners();
    }
  }

  void sendMessage(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _item == null) return;

    final ids = [currentUser.uid, _item!.seller.id]..sort();
    final conversationId = ids.join('_');
    final otherUserId = _item!.seller.id;
    final otherUserName = _item!.seller.name.trim();
    final itemName = _item!.name.trim();

    context.go(
      '/chat/$conversationId/$otherUserId?otherUserName=${Uri.encodeQueryComponent(otherUserName)}&itemName=${Uri.encodeQueryComponent(itemName)}',
    );
    _messageSent = true;
    notifyListeners();
  }

  Future<void> updateListingDetails({
    required String title,
    required String priceText,
    required String size,
    required String condition,
    required String exchangeType,
    required String description,
    required List<String> tags,
  }) async {
    final current = _item;
    if (current == null) {
      throw ArgumentError('Listing not found.');
    }

    final normalizedTitle = title.trim();
    final normalizedDescription = description.trim();
    final price = int.tryParse(priceText.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (normalizedTitle.isEmpty) {
      throw ArgumentError('Title is required.');
    }
    if (price <= 0) {
      throw ArgumentError('Price must be greater than 0.');
    }
    if (size.trim().isEmpty) {
      throw ArgumentError('Size is required.');
    }
    if (normalizedDescription.isEmpty) {
      throw ArgumentError('Description is required.');
    }

    final normalizedTags = tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    final currentImages = List<String>.from(current.images);
    final imagePath = currentImages.isNotEmpty ? currentImages.first : '';

    _isUpdating = true;
    notifyListeners();

    try {
      final existingListing = await _listingService.getListingById(current.id);
      final listing = Listing(
        id: current.id,
        sellerId: current.sellerId,
        title: normalizedTitle,
        price: price,
        conditionTag: condition,
        description: normalizedDescription,
        sellerName: current.seller.name,
        exchangeType: exchangeType,
        tags: normalizedTags,
        rating: current.seller.rating,
        imageName: '',
        createdAt: null,
        soldAt: null,
        imagePath: imagePath,
        imageURLs: currentImages,
        size: size.trim(),
        status: 'active',
        saved: _saved,
      );

      _lastUpdateWasOffline = await _listingService.updateListing(listing);

      _item = ItemDetail(
        id: current.id,
        sellerId: current.sellerId,
        name: normalizedTitle,
        price: price.toDouble(),
        condition: condition,
        exchangeType: exchangeType,
        seller: current.seller,
        aiScore: current.aiScore,
        description: normalizedDescription,
        images: currentImages,
        tags: normalizedTags,
      );
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _buildSimilarItems({
    required String currentListingId,
    required List<Listing> listings,
  }) {
    Listing? current;
    for (final listing in listings) {
      if (listing.id == currentListingId) {
        current = listing;
        break;
      }
    }

    final currentTags = current?.tags ?? const <String>[];

    final filtered = listings
        .where((l) => l.id != currentListingId)
        .where((l) => !l.isSold)
        .toList();

    filtered.sort((a, b) {
      int score(Listing listing) {
        final overlap = listing.tags.where((t) => currentTags.contains(t)).length;
        final sameCondition = listing.conditionTag == current?.conditionTag ? 1 : 0;
        return overlap * 10 + sameCondition;
      }

      return score(b).compareTo(score(a));
    });

    return filtered.take(8).map((l) {
      final image = l.imageURLs.isNotEmpty ? l.imageURLs.first : l.imagePath;

      return {
        'id': l.id,
        'name': l.title,
        'price': l.price,
        'image': image,
      };
    }).toList();
  }
}