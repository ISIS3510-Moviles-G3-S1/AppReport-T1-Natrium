import 'package:sqflite/sqflite.dart';
import 'app_database.dart';

class SearchHistoryStorage {
  Future<void> addSearch({required String query, String? userId}) async {
    final db = await AppDatabase().database;
    final now = DateTime.now().millisecondsSinceEpoch;
    // Si ya existe la búsqueda, actualiza timestamp y count
    final existing = await db.query(
      'search_history',
      where: 'query = ? AND user_id IS ?',
      whereArgs: [query, userId],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      final count = (existing.first['count'] as int? ?? 1) + 1;
      await db.update(
        'search_history',
        {'timestamp': now, 'count': count},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      await db.insert('search_history', {
        'user_id': userId,
        'query': query,
        'timestamp': now,
        'count': 1,
      });
    }
  }

  Future<List<String>> getRecentSearches({String? userId, int limit = 10}) async {
    final db = await AppDatabase().database;
    final result = await db.query(
      'search_history',
      where: 'user_id IS ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return result.map((row) => row['query'] as String).toList();
  }

  Future<void> clearHistory({String? userId}) async {
    final db = await AppDatabase().database;
    await db.delete(
      'search_history',
      where: 'user_id IS ?',
      whereArgs: [userId],
    );
  }
}
