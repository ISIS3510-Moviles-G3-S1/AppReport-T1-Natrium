// ...existing code...
// ...existing code...

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../models/item_detail.dart';
import '../models/seller.dart';
import '../data/listing_service.dart';
import '../view_models/browse_view_model.dart';

class ItemDetailViewModel extends ChangeNotifier {
  ItemDetail? _item;
  final ListingService _listingService = ListingService();
  int _activeImageIndex = 0;
  bool _saved = false;
  bool _messageSent = false;

  ItemDetail? get item => _item;
  int get activeImageIndex => _activeImageIndex;
  bool get saved => _saved;
  bool get messageSent => _messageSent;

  Future<void> loadItem(String id) async {
    final listing = await _listingService.getListingById(id);
    if (listing != null) {
      _item = ItemDetail(
        id: id,
        sellerId: listing.sellerId,
        name: listing.title,
        price: listing.price.toDouble(),
        condition: listing.conditionTag,
        seller: Seller(
          name: listing.sellerName,
          university: '',
          rating: listing.rating,
          sales: 0,
          avatar: '',
          verified: false,
        ),
        aiScore: 0,
        description: listing.description,
        images:
            listing.imageURLs.isNotEmpty
                ? [listing.imageURLs[0]]
                : [listing.imagePath],
        tags: listing.tags,
      );
    } else {
      _item = null;
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

  void sendMessage() {
    _messageSent = true;
    notifyListeners();
  }

  List<Map<String, dynamic>> get similarItems => [
    {
      'id': 1,
      'name': 'Item 1',
      'price': 10.0,
      'image': 'https://via.placeholder.com/150',
    },
    {
      'id': 2,
      'name': 'Item 2',
      'price': 20.0,
      'image': 'https://via.placeholder.com/150',
    },
    {
      'id': 3,
      'name': 'Item 3',
      'price': 30.0,
      'image': 'https://via.placeholder.com/150',
    },
  ];
}
