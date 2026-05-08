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
      version: 2,
      onCreate: (db, version) async {
        await _createBaseTables(db);
        await _createChatTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createChatTables(db);
        }
      },
    );
  }

  Future<void> _createBaseTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS favs (
        id TEXT PRIMARY KEY
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS fyp_items (
        id TEXT PRIMARY KEY
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS fav_fyp_relations (
        fav_id TEXT,
        fyp_item_id TEXT,
        PRIMARY KEY (fav_id, fyp_item_id),
        FOREIGN KEY (fav_id) REFERENCES favs(id) ON DELETE CASCADE,
        FOREIGN KEY (fyp_item_id) REFERENCES fyp_items(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS search_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        query TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        count INTEGER DEFAULT 1
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_reviews (
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
      CREATE TABLE IF NOT EXISTS pending_photo_analysis (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        file_path TEXT NOT NULL,
        image_bytes BLOB NOT NULL,
        local_result_json TEXT,
        timestamp INTEGER NOT NULL,
        synced INTEGER DEFAULT 0
      );
    ''');
  }

  Future<void> _createChatTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_conversations (
        conversation_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        other_user_id TEXT NOT NULL,
        other_user_name TEXT,
        item_name TEXT,
        last_message_text TEXT,
        last_message_at INTEGER,
        last_message_status TEXT DEFAULT 'sent',
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (conversation_id, user_id)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_messages (
        local_id TEXT PRIMARY KEY,
        remote_id TEXT,
        conversation_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        text TEXT NOT NULL,
        type TEXT NOT NULL,
        sent_at INTEGER NOT NULL,
        read_at INTEGER,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL
      );
    ''');

    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_chat_messages_remote_user ON chat_messages(remote_id, user_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_chat_messages_conversation_user ON chat_messages(conversation_id, user_id, sent_at);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_chat_messages_pending_user ON chat_messages(user_id, status, sent_at);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_chat_conversations_user_updated ON chat_conversations(user_id, updated_at);',
    );
  }
}
