import 'package:quiver/collection.dart';

class LruCacheService<K, V> {
  final LruMap<K, V> _cache;

  LruCacheService({int maxEntries = 100}) : _cache = LruMap(maximumSize: maxEntries);

  void save(K key, V value) {
    _cache[key] = value;
  }

  V? retrieve(K key) {
    return _cache[key];
  }

  bool contains(K key) {
    return _cache.containsKey(key);
  }

  void clear() {
    _cache.clear();
  }

  void remove(K key) {
    _cache.remove(key);
  }
}
