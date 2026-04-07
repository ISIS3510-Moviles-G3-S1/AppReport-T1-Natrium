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

  ItemDetail? get item => _item;
  int get activeImageIndex => _activeImageIndex;
  bool get saved => _saved;
  bool get messageSent => _messageSent;
  List<Map<String, dynamic>> get similarItems => _similarItems;

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