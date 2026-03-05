import 'package:flutter/foundation.dart';
import '../models/listing.dart';
import '../data/mock_data.dart';

class BrowseViewModel extends ChangeNotifier {
  List<Listing> _listings = List.from(MockData.browseListings);
  final Map<int, bool> _savedItems = {};
  String _search = '';
  String _category = 'All';
  String _size = 'All';
  String _condition = 'All';
  String _color = 'All';
  String _sort = 'newest';
  bool _aiSearch = false;
  bool _showFilters = false;

  BrowseViewModel() {
    for (final l in _listings) {
      _savedItems[l.id] = l.saved;
    }
  }

  String get search => _search;
  set search(String v) {
    _search = v;
    notifyListeners();
  }

  String get category => _category;
  set category(String v) {
    _category = v;
    notifyListeners();
  }

  String get size => _size;
  set size(String v) {
    _size = v;
    notifyListeners();
  }

  String get condition => _condition;
  set condition(String v) {
    _condition = v;
    notifyListeners();
  }

  String get color => _color;
  set color(String v) {
    _color = v;
    notifyListeners();
  }

  String get sort => _sort;
  set sort(String v) {
    _sort = v;
    notifyListeners();
  }

  bool get aiSearch => _aiSearch;
  set aiSearch(bool v) {
    _aiSearch = v;
    notifyListeners();
  }

  bool get showFilters => _showFilters;
  set showFilters(bool v) {
    _showFilters = v;
    notifyListeners();
  }

  bool isSaved(int id) => _savedItems[id] ?? false;

  void toggleSave(int id) {
    _savedItems[id] = !(_savedItems[id] ?? false);
    notifyListeners();
  }

  void clearFilters() {
    _category = 'All';
    _size = 'All';
    _condition = 'All';
    _color = 'All';
    notifyListeners();
  }

  bool get hasFilters =>
      _category != 'All' ||
      _size != 'All' ||
      _condition != 'All' ||
      _color != 'All';

  List<Listing> get filteredAndSorted {
    var filtered =
        _listings
            .where((l) {
              final matchSearch = l.name.toLowerCase().contains(
                _search.toLowerCase(),
              );
              final matchCat = _category == 'All' || l.category == _category;
              final matchSize = _size == 'All' || l.size == _size;
              final matchCond =
                  _condition == 'All' || l.condition == _condition;
              final matchColor = _color == 'All' || l.color == _color;
              return matchSearch &&
                  matchCat &&
                  matchSize &&
                  matchCond &&
                  matchColor;
            })
            .map((l) => l.copyWith(saved: _savedItems[l.id] ?? l.saved))
            .toList();

    filtered.sort((a, b) {
      if (_sort == 'price-asc') return a.price.compareTo(b.price);
      if (_sort == 'price-desc') return b.price.compareTo(a.price);
      if (_sort == 'rating') return b.rating.compareTo(a.rating);
      return b.id.compareTo(a.id);
    });
    return filtered;
  }
}
