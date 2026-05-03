import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'unimarket.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE favs (
            id TEXT PRIMARY KEY
          );
        ''');
        await db.execute('''
          CREATE TABLE fyp_items (
            id TEXT PRIMARY KEY
          );
        ''');
        await db.execute('''
          CREATE TABLE fav_fyp_relations (
            fav_id TEXT,
            fyp_item_id TEXT,
            PRIMARY KEY (fav_id, fyp_item_id),
            FOREIGN KEY (fav_id) REFERENCES favs(id) ON DELETE CASCADE,
            FOREIGN KEY (fyp_item_id) REFERENCES fyp_items(id) ON DELETE CASCADE
          );
        ''');
        await db.execute('''
          CREATE TABLE search_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT,
            query TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            count INTEGER DEFAULT 1
          );
        ''');
        await db.execute('''
          CREATE TABLE pending_reviews (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            comment TEXT NOT NULL,
            rating INTEGER NOT NULL,
            timestamp INTEGER NOT NULL,
            synced INTEGER DEFAULT 0
          );
        ''');
        await db.execute('''
          CREATE TABLE pending_photo_analysis (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            file_path TEXT NOT NULL,
            image_bytes BLOB NOT NULL,
            local_result_json TEXT,
            timestamp INTEGER NOT NULL,
            synced INTEGER DEFAULT 0
          );
        ''');
      },
    );
  }
}
