import 'dart:collection';

/// LRU Cache para recomendaciones ECO (Least Recently Used).
///
/// **Decisiones de implementación:**
/// - Usa LinkedHashMap para mantener insertion order + MRU tracking.
/// - Cuando capacity se llena, expulsa el entry menos recientemente usado.
/// - Thread-safe para acceso desde ViewModel async context.
/// - Invalidación explícita al cambiar perfil o subir prendas.
///
/// **Parámetros clave:**
/// - maxSize: Capacidad máxima de cache (default: 20 recomendaciones).
/// - ttlMinutes: Validez de entry antes de expiración por antigüedad (default: 60 min).
///
/// **Métricas:**
/// - hits/misses para medir hit rate (cache efficiency).
/// - requestHash como key para evitar regenerar mismas recomendaciones.
class EcoCacheEntry {
  EcoCacheEntry({
    required this.ecoMessage,
    required this.requestHash,
    required this.createdAt,
  });

  final String ecoMessage;
  final String requestHash;
  final DateTime createdAt;

  bool isExpired(int ttlMinutes) {
    final age = DateTime.now().difference(createdAt).inMinutes;
    return age > ttlMinutes;
  }
}

class EcoCache {
  /// Construye un LRU Cache con capacidad configurable.
  ///
  /// Parámetros:
  /// - maxSize: Número máximo de entradas (default: 20).
  /// - ttlMinutes: Time-to-live en minutos (default: 60).
  EcoCache({
    this.maxSize = 20,
    this.ttlMinutes = 60,
  });

  final int maxSize;
  final int ttlMinutes;

  /// LinkedHashMap: insertion order = aceso order via forEach; podemos rastrear MRU.
  /// Key = requestHash (parámetros del usuario), Value = EcoCacheEntry.
  final LinkedHashMap<String, EcoCacheEntry> _cache = LinkedHashMap<String, EcoCacheEntry>();

  // ── Métricas LRU ──────────────────────────────────────────────────────

  int _hits = 0;
  int _misses = 0;

  /// Retorna el hit rate actual (0.0 - 1.0). Si no hay requests, retorna 0.0.
  double get hitRate {
    final total = _hits + _misses;
    if (total == 0) return 0.0;
    return _hits / total;
  }

  /// Retorna hits totales.
  int get hits => _hits;

  /// Retorna misses totales.
  int get misses => _misses;

  /// Retorna tamaño actual del cache.
  int get size => _cache.length;

  /// Retorna capacidad máxima.
  int get capacity => maxSize;

  // ── Operaciones LRU ───────────────────────────────────────────────────

  /// Obtiene una recomendación del cache si existe y no ha expirado.
  /// Marca como "hit" o "miss" para tracking de eficiencia.
  ///
  /// Retorna null si:
  /// - requestHash no está en cache.
  /// - Entry ha expirado (edad > ttlMinutes).
  String? get(String requestHash) {
    final entry = _cache[requestHash];
    if (entry == null) {
      _misses++;
      return null;
    }

    if (entry.isExpired(ttlMinutes)) {
      _cache.remove(requestHash);
      _misses++;
      return null;
    }

    // ── Actualizar orden MRU ──────────────────────────────────────────
    // En LinkedHashMap, remover + re-insertar pone al final (más reciente).
    _cache.remove(requestHash);
    _cache[requestHash] = entry;

    _hits++;
    return entry.ecoMessage;
  }

  /// Inserta o actualiza una recomendación en cache.
  /// Si size + 1 > maxSize, expulsa el entry más antiguo (FIFO/LRU).
  ///
  /// Parámetros:
  /// - requestHash: Clave única basada en parámetros del usuario.
  /// - ecoMessage: Recomendación generada por AI.
  void put(String requestHash, String ecoMessage) {
    // Si ya existe, actualizar directamente (no afecta orden).
    if (_cache.containsKey(requestHash)) {
      _cache[requestHash] = EcoCacheEntry(
        ecoMessage: ecoMessage,
        requestHash: requestHash,
        createdAt: DateTime.now(),
      );
      // Mover al final para marcar como MRU:
      _cache.remove(requestHash);
      _cache[requestHash] = EcoCacheEntry(
        ecoMessage: ecoMessage,
        requestHash: requestHash,
        createdAt: DateTime.now(),
      );
      return;
    }

    // ── Eviction: Cuando lleno, sacar el LRU (primer entry) ──────────
    if (_cache.length >= maxSize) {
      // En LinkedHashMap, .keys.first es el más antiguo (LRU).
      final lruKey = _cache.keys.first;
      _cache.remove(lruKey);
    }

    _cache[requestHash] = EcoCacheEntry(
      ecoMessage: ecoMessage,
      requestHash: requestHash,
      createdAt: DateTime.now(),
    );
  }

  /// Invalida toda la caché (limpia cuando perfil cambia o se sube una prenda).
  void invalidate() {
    _cache.clear();
    _hits = 0;
    _misses = 0;
  }

  /// Retorna estadísticas de debug en formato legible.
  String getStats() {
    final total = _hits + _misses;
    final rate = total == 0 ? 0.0 : (_hits / total * 100).toStringAsFixed(2);
    return 'ECO CACHE: size=$size/$capacity, hits=$_hits, misses=$_misses, hitRate=$rate%';
  }
}
