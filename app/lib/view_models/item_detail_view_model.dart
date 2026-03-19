import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';
import '../view_models/browse_view_model.dart';
import '../models/item_detail.dart';
import '../data/mock_data.dart';

class ItemDetailViewModel extends ChangeNotifier {
  ItemDetail? _item;
  int _activeImageIndex = 0;
  bool _saved = false;
  bool _messageSent = false;

  ItemDetail? get item => _item;
  int get activeImageIndex => _activeImageIndex;
  bool get saved => _saved;
  bool get messageSent => _messageSent;

  void loadItem(int id) {
    try {
      _item = MockData.itemDetails.firstWhere((e) => e.id == id);
    } catch (_) {
      _item =
          MockData.itemDetails.isNotEmpty ? MockData.itemDetails.first : null;
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

  List<({int id, String name, double price, String image})> get similarItems =>
      MockData.similarItems;
}
