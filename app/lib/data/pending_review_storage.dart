import 'package:sqflite/sqflite.dart';
import 'app_database.dart';

class PendingReviewStorage {
  Future<void> addPendingReview({
    required String productId,
    required String userId,
    required String comment,
    required int rating,
    required int timestamp,
  }) async {
    final db = await AppDatabase().database;
    await db.insert('pending_reviews', {
      'product_id': productId,
      'user_id': userId,
      'comment': comment,
      'rating': rating,
      'timestamp': timestamp,
      'synced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingReviews() async {
    final db = await AppDatabase().database;
    return await db.query('pending_reviews', where: 'synced = 0');
  }

  Future<void> markReviewAsSynced(int id) async {
    final db = await AppDatabase().database;
    await db.update('pending_reviews', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await AppDatabase().database;
    await db.delete('pending_reviews');
  }
}
