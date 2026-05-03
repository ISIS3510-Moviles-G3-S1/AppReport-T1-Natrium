import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'app_database.dart';

class PendingPhotoAnalysis {
  final int? id;
  final String userId;
  final String filePath;
  final Uint8List imageBytes;
  final String? localResultJson;
  final int timestamp;
  final int synced;

  PendingPhotoAnalysis({
    this.id,
    required this.userId,
    required this.filePath,
    required this.imageBytes,
    this.localResultJson,
    required this.timestamp,
    this.synced = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'file_path': filePath,
        'image_bytes': imageBytes,
        'local_result_json': localResultJson,
        'timestamp': timestamp,
        'synced': synced,
      };

  static PendingPhotoAnalysis fromMap(Map<String, dynamic> map) => PendingPhotoAnalysis(
        id: map['id'] as int?,
        userId: map['user_id'] as String,
        filePath: map['file_path'] as String,
        imageBytes: map['image_bytes'] as Uint8List,
        localResultJson: map['local_result_json'] as String?,
        timestamp: map['timestamp'] as int,
        synced: map['synced'] as int? ?? 0,
      );
}

class PendingPhotoAnalysisStorage {
  static const table = 'pending_photo_analysis';

  Future<int> insert(PendingPhotoAnalysis item) async {
    final db = await AppDatabase().database;
    return await db.insert(table, item.toMap());
  }

  Future<List<PendingPhotoAnalysis>> getAllPending() async {
    final db = await AppDatabase().database;
    final maps = await db.query(table, where: 'synced = 0');
    return maps.map((m) => PendingPhotoAnalysis.fromMap(m)).toList();
  }

  Future<void> markAsSynced(int id) async {
    final db = await AppDatabase().database;
    await db.update(table, {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase().database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}
