import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_local_storage.dart';
import '../models/message.dart';

class ChatSyncService {
  ChatSyncService._();
  static final ChatSyncService instance = ChatSyncService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChatLocalStorage _localStorage = ChatLocalStorage.instance;

  bool _syncInProgress = false;

  Future<void> preloadAllConversationsForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    final conversationsSnapshot = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: user.uid)
        .get();

    for (final conversationDoc in conversationsSnapshot.docs) {
      final data = conversationDoc.data();
      final participants = (data['participants'] as List<dynamic>? ?? const <dynamic>[])
          .map((value) => value.toString())
          .toList(growable: false);

      final otherUserId = participants.firstWhere(
        (id) => id != user.uid,
        orElse: () => '',
      );

      if (otherUserId.isEmpty) {
        continue;
      }

      final userDoc = await _firestore.collection('users').doc(otherUserId).get();
      final userData = userDoc.data();
      final otherUserName =
          (userData?['displayName'] as String?)?.trim().isNotEmpty == true
              ? (userData?['displayName'] as String).trim()
              : 'Unknown User';

      final lastMessageAt = data['lastMessageAt'] as Timestamp?;
      await _localStorage.upsertConversation(
        userId: user.uid,
        conversationId: conversationDoc.id,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        itemName: (data['itemName'] as String?) ?? '',
        lastMessageText: (data['lastMessageText'] as String?) ?? '',
        lastMessageAt: lastMessageAt?.millisecondsSinceEpoch ?? 0,
        lastMessageStatus: (data['lastMessageStatus'] as String?) ?? 'sent',
        notify: false,
      );

      final messagesSnapshot = await _firestore
          .collection('conversations')
          .doc(conversationDoc.id)
          .collection('messages')
          .orderBy('sentAt', descending: false)
          .get();

      for (final messageDoc in messagesSnapshot.docs) {
        await _localStorage.upsertRemoteMessage(
          userId: user.uid,
          conversationId: conversationDoc.id,
          message: Message.fromFirestore(messageDoc),
          notify: false,
        );
      }
    }

    _localStorage.notifyChanged();
  }

  Future<void> syncPendingMessagesForCurrentUser() async {
    if (_syncInProgress) {
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    _syncInProgress = true;
    try {
      final pending = await _localStorage.getPendingMessages(userId: user.uid);
      for (final row in pending) {
        await _syncOnePendingMessage(userId: user.uid, row: row);
      }
    } finally {
      _syncInProgress = false;
    }
  }

  Future<void> _syncOnePendingMessage({
    required String userId,
    required Map<String, dynamic> row,
  }) async {
    final localId = (row['local_id'] as String?) ?? '';
    final conversationId = (row['conversation_id'] as String?) ?? '';
    final text = (row['text'] as String?) ?? '';
    final senderId = (row['sender_id'] as String?) ?? '';
    final sentAt = (row['sent_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch;

    if (localId.isEmpty || conversationId.isEmpty || text.trim().isEmpty || senderId.isEmpty) {
      return;
    }

    final conversation = await _localStorage.getConversation(
      userId: userId,
      conversationId: conversationId,
    );

    final otherUserId = (conversation?['other_user_id'] as String?) ?? '';
    final otherUserName = (conversation?['other_user_name'] as String?) ?? 'User';
    final itemName = (conversation?['item_name'] as String?) ?? '';

    if (otherUserId.isEmpty) {
      return;
    }

    final sentAtTimestamp = Timestamp.fromMillisecondsSinceEpoch(sentAt);

    await _firestore.collection('conversations').doc(conversationId).set({
      'participants': [senderId, otherUserId],
      'lastMessageText': text,
      'lastMessageAt': sentAtTimestamp,
      'itemName': itemName,
    }, SetOptions(merge: true));

    final messageRef = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'text': text,
      'imageURLs': <String>[],
      'type': 'text',
      'sentAt': sentAtTimestamp,
      'status': 'sent',
    });

    await _localStorage.markMessageAsSent(
      userId: userId,
      localId: localId,
      remoteId: messageRef.id,
      sentAtMillis: sentAt,
    );

    await _localStorage.upsertConversation(
      userId: userId,
      conversationId: conversationId,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      itemName: itemName,
      lastMessageText: text,
      lastMessageAt: sentAt,
      lastMessageStatus: 'sent',
    );
  }
}
