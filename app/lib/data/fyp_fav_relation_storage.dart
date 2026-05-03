
import 'package:sqflite/sqflite.dart';
import 'app_database.dart';

class FypFavRelationStorage {
  Future<void> addRelation({required String favId, required String fypItemId}) async {
    final db = await AppDatabase().database;
    // Insert fav and item if not exist
    await db.insert('favs', {'id': favId}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('fyp_items', {'id': fypItemId}, conflictAlgorithm: ConflictAlgorithm.ignore);
    // Insert relation
    await db.insert('fav_fyp_relations', {
      'fav_id': favId,
      'fyp_item_id': fypItemId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<String>> getRelationsByFavId(String favId) async {
    final db = await AppDatabase().database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fav_fyp_relations',
      columns: ['fyp_item_id'],
      where: 'fav_id = ?',
      whereArgs: [favId],
    );
    return maps.map((row) => row['fyp_item_id'] as String).toList();
  }

  Future<void> removeRelation({required String favId, required String fypItemId}) async {
    final db = await AppDatabase().database;
    await db.delete(
      'fav_fyp_relations',
      where: 'fav_id = ? AND fyp_item_id = ?',
      whereArgs: [favId, fypItemId],
    );
  }

  Future<void> clearAll() async {
    final db = await AppDatabase().database;
    await db.delete('fav_fyp_relations');
    await db.delete('favs');
    await db.delete('fyp_items');
  }
}
