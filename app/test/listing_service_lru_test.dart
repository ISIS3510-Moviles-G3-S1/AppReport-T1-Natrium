import 'package:flutter_test/flutter_test.dart';
import 'dart:collection';
import 'package:uni_market/data/listing_service.dart';
import 'package:uni_market/models/listing.dart';

void main() {
  test('trimLinkedListingCacheKeys evicts oldest LinkedHashMap entries', () {
    final cache = LinkedHashMap<String, Map<String, dynamic>>.fromEntries(
      List.generate(
        5,
        (i) => MapEntry(
          'id$i',
          {'id': 'id$i'},
        ),
      ),
    );

    final kept = ListingService.trimLinkedListingCacheKeys(cache, 3);

    expect(kept, ['id2', 'id3', 'id4']);
  });

  test('touching a key moves it to the most recent position', () {
    final cache = LinkedHashMap<String, Map<String, dynamic>>.fromEntries(
      [
        MapEntry('id0', {'id': 'id0'}),
        MapEntry('id1', {'id': 'id1'}),
        MapEntry('id2', {'id': 'id2'}),
      ],
    );

    cache.remove('id0');
    cache['id0'] = {'id': 'id0'};

    expect(cache.keys.toList(), ['id1', 'id2', 'id0']);
  });
}
