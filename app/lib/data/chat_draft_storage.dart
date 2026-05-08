import 'package:hive/hive.dart';

class ChatDraftStorage {
  ChatDraftStorage._();
  static final ChatDraftStorage instance = ChatDraftStorage._();

  static const String _boxName = 'chat_drafts_v1';

  Future<Box<String>> _openBox() async {
    return Hive.openBox<String>(_boxName);
  }

  String _key({required String userId, required String conversationId}) {
    return '${userId}_$conversationId';
  }

  Future<void> saveDraft({
    required String userId,
    required String conversationId,
    required String text,
  }) async {
    final box = await _openBox();
    final key = _key(userId: userId, conversationId: conversationId);
    if (text.trim().isEmpty) {
      await box.delete(key);
      return;
    }
    await box.put(key, text);
  }

  Future<String> getDraft({
    required String userId,
    required String conversationId,
  }) async {
    final box = await _openBox();
    final key = _key(userId: userId, conversationId: conversationId);
    return box.get(key, defaultValue: '') ?? '';
  }

  Future<void> clearDraft({
    required String userId,
    required String conversationId,
  }) async {
    final box = await _openBox();
    final key = _key(userId: userId, conversationId: conversationId);
    await box.delete(key);
  }
}
