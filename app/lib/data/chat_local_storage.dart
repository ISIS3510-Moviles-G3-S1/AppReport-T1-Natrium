import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../models/message.dart';
import 'app_database.dart';

class ChatLocalStorage {
  ChatLocalStorage._();
  static final ChatLocalStorage instance = ChatLocalStorage._();

  final StreamController<void> _changes = StreamController<void>.broadcast();

  void notifyChanged() {
    _changes.add(null);
  }

  Stream<List<Message>> watchMessages({
    required String userId,
    required String conversationId,
  }) async* {
    yield await getMessages(userId: userId, conversationId: conversationId);
    yield* _changes.stream.asyncMap(
      (_) => getMessages(userId: userId, conversationId: conversationId),
    );
  }

  Stream<List<Map<String, dynamic>>> watchConversations({
    required String userId,
  }) async* {
    yield await getConversations(userId: userId);
    yield* _changes.stream.asyncMap((_) => getConversations(userId: userId));
  }

  Future<List<Message>> getMessages({
    required String userId,
    required String conversationId,
  }) async {
    final db = await AppDatabase().database;
    final rows = await db.query(
      'chat_messages',
      where: 'user_id = ? AND conversation_id = ?',
      whereArgs: [userId, conversationId],
      orderBy: 'sent_at ASC, created_at ASC',
    );

    return rows.map(Message.fromLocalMap).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> getConversations({
    required String userId,
  }) async {
    final db = await AppDatabase().database;
    return db.query(
      'chat_conversations',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );
  }

  Future<void> upsertRemoteMessage({
    required String userId,
    required String conversationId,
    required Message message,
    bool notify = true,
  }) async {
    final db = await AppDatabase().database;

    await db.insert('chat_messages', {
      'local_id': _remoteLocalId(message.id),
      'remote_id': message.id,
      'conversation_id': conversationId,
      'user_id': userId,
      'sender_id': message.senderId,
      'text': message.text,
      'type': message.type,
      'sent_at': message.sentAt.millisecondsSinceEpoch,
      'read_at': message.readAt?.millisecondsSinceEpoch,
      'status': message.status,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    if (notify) {
      _changes.add(null);
    }
  }

  Future<String> enqueueOutgoingMessage({
    required String userId,
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final localId = _localPendingId();
    final db = await AppDatabase().database;

    await db.insert('chat_messages', {
      'local_id': localId,
      'remote_id': null,
      'conversation_id': conversationId,
      'user_id': userId,
      'sender_id': senderId,
      'text': text,
      'type': 'text',
      'sent_at': now,
      'read_at': null,
      'status': 'pending',
      'created_at': now,
    });

    _changes.add(null);
    return localId;
  }

  Future<void> markMessageAsSent({
    required String userId,
    required String localId,
    required String remoteId,
    required int sentAtMillis,
  }) async {
    final db = await AppDatabase().database;
    await db.transaction((txn) async {
      // If a remote row already exists (race with remote listener), remove
      // the local pending duplicate instead of violating UNIQUE(remote_id,user_id).
      final existingRemote = await txn.query(
        'chat_messages',
        columns: ['local_id'],
        where: 'user_id = ? AND remote_id = ?',
        whereArgs: [userId, remoteId],
        limit: 1,
      );

      if (existingRemote.isNotEmpty) {
        await txn.delete(
          'chat_messages',
          where: 'user_id = ? AND local_id = ?',
          whereArgs: [userId, localId],
        );
        return;
      }

      await txn.update(
        'chat_messages',
        {
          'remote_id': remoteId,
          'sent_at': sentAtMillis,
          'status': 'sent',
        },
        where: 'user_id = ? AND local_id = ?',
        whereArgs: [userId, localId],
      );
    });

    _changes.add(null);
  }

  Future<List<Map<String, dynamic>>> getPendingMessages({
    required String userId,
    String? conversationId,
  }) async {
    final db = await AppDatabase().database;
    if (conversationId != null && conversationId.isNotEmpty) {
      return db.query(
        'chat_messages',
        where: 'user_id = ? AND status = ? AND conversation_id = ?',
        whereArgs: [userId, 'pending', conversationId],
        orderBy: 'sent_at ASC',
      );
    }

    return db.query(
      'chat_messages',
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, 'pending'],
      orderBy: 'sent_at ASC',
    );
  }

  Future<int> getPendingCount({
    required String userId,
  }) async {
    final db = await AppDatabase().database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM chat_messages WHERE user_id = ? AND status = ?',
      [userId, 'pending'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> upsertConversation({
    required String userId,
    required String conversationId,
    required String otherUserId,
    required String otherUserName,
    required String itemName,
    required String lastMessageText,
    required int lastMessageAt,
    required String lastMessageStatus,
    bool notify = true,
  }) async {
    final db = await AppDatabase().database;
    await db.insert('chat_conversations', {
      'conversation_id': conversationId,
      'user_id': userId,
      'other_user_id': otherUserId,
      'other_user_name': otherUserName,
      'item_name': itemName,
      'last_message_text': lastMessageText,
      'last_message_at': lastMessageAt,
      'last_message_status': lastMessageStatus,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    if (notify) {
      _changes.add(null);
    }
  }

  Future<Map<String, dynamic>?> getConversation({
    required String userId,
    required String conversationId,
  }) async {
    final db = await AppDatabase().database;
    final rows = await db.query(
      'chat_conversations',
      where: 'user_id = ? AND conversation_id = ?',
      whereArgs: [userId, conversationId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> refreshConversationFromMessages({
    required String userId,
    required String conversationId,
    required String fallbackOtherUserId,
    required String fallbackOtherUserName,
    required String fallbackItemName,
  }) async {
    final db = await AppDatabase().database;
    final rows = await db.query(
      'chat_messages',
      where: 'user_id = ? AND conversation_id = ?',
      whereArgs: [userId, conversationId],
      orderBy: 'sent_at DESC, created_at DESC',
      limit: 1,
    );

    if (rows.isEmpty) {
      return;
    }

    final latest = rows.first;
    await upsertConversation(
      userId: userId,
      conversationId: conversationId,
      otherUserId: fallbackOtherUserId,
      otherUserName: fallbackOtherUserName,
      itemName: fallbackItemName,
      lastMessageText: (latest['text'] as String?) ?? '',
      lastMessageAt: (latest['sent_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      lastMessageStatus: (latest['status'] as String?) ?? 'sent',
      notify: false,
    );

    _changes.add(null);
  }

  Future<void> markMessagesAsRead({
    required String userId,
    required String conversationId,
    required String currentUserId,
  }) async {
    final db = await AppDatabase().database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'chat_messages',
      {'read_at': now},
      where:
          'user_id = ? AND conversation_id = ? AND sender_id != ? AND read_at IS NULL',
      whereArgs: [userId, conversationId, currentUserId],
    );

    _changes.add(null);
  }

  static String _remoteLocalId(String remoteId) => 'remote_$remoteId';

  static String _localPendingId() =>
      'local_${DateTime.now().microsecondsSinceEpoch}';
}
