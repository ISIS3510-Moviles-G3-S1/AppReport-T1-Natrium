import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';

class ChatViewModel extends ChangeNotifier {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String itemName;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ChatViewModel({
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    required this.itemName,
  });

  Stream<List<Message>> get messagesStream {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }

  Future<void> ensureConversationExists() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('[ChatViewModel] ensureConversationExists aborted: no currentUser');
      return;
    }

    debugPrint('[ChatViewModel] ensureConversationExists for convo $conversationId with participants [${currentUser.uid}, $otherUserId]');
    try {
      await _firestore.collection('conversations').doc(conversationId).set({
        'participants': [currentUser.uid, otherUserId],
      }, SetOptions(merge: true));
      
      // Update conversation metadata with latest message info
      await updateConversationMetadata();
    } catch (e, stack) {
      debugPrint('[ChatViewModel] ensureConversationExists failed: $e');
      debugPrint(stack.toString());
    }
  }

  Future<void> updateConversationMetadata() async {
    try {
      // Get the most recent message
      final messagesQuery = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('sentAt', descending: true)
          .limit(1)
          .get();

      if (messagesQuery.docs.isNotEmpty) {
        final latestMessage = messagesQuery.docs.first;
        final messageData = latestMessage.data();
        
        await _firestore.collection('conversations').doc(conversationId).set({
          'lastMessageText': messageData['text'] ?? '',
          'lastMessageAt': messageData['sentAt'],
          'itemName': itemName,
        }, SetOptions(merge: true));
        
        debugPrint('[ChatViewModel] Updated conversation metadata for $conversationId');
      }
    } catch (e, stack) {
      debugPrint('[ChatViewModel] updateConversationMetadata failed: $e');
      debugPrint(stack.toString());
    }
  }

  Future<void> sendMessage(String text) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('[ChatViewModel] sendMessage aborted: no currentUser');
      return;
    }

    debugPrint('[ChatViewModel] sendMessage: uid=${currentUser.uid}, email=${currentUser.email}, emailVerified=${currentUser.emailVerified}, isAnonymous=${currentUser.isAnonymous}');

    try {
      final tokenResult = await currentUser.getIdTokenResult(true);
      debugPrint('[ChatViewModel] ID token claims: ${tokenResult.claims}');
    } catch (tokenError) {
      debugPrint('[ChatViewModel] Failed to fetch ID token result: $tokenError');
    }

    try {
      final messageData = {
        'senderId': currentUser.uid,
        'text': text,
        'imageURLs': [],
        'type': 'text',
        'sentAt': Timestamp.now(),
        'status': 'sent',
      };

      // Update conversation document with last message info
      debugPrint('[ChatViewModel] Updating conversation $conversationId with last message info');
      await _firestore.collection('conversations').doc(conversationId).set({
        'participants': [currentUser.uid, otherUserId],
        'lastMessageText': text,
        'lastMessageAt': messageData['sentAt'],
        'itemName': itemName,
      }, SetOptions(merge: true));

      debugPrint('[ChatViewModel] Adding message to conversation $conversationId: $messageData');
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(messageData);
      debugPrint('[ChatViewModel] Message send completed successfully.');
    } catch (e, stack) {
      debugPrint('[ChatViewModel] Error sending message: $e');
      debugPrint(stack.toString());
    }
  }

  Future<void> sendInitialMessage() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('[ChatViewModel] sendInitialMessage aborted: no currentUser');
      return;
    }

    debugPrint('[ChatViewModel] sendInitialMessage for convo $conversationId, uid=${currentUser.uid}');
    await ensureConversationExists();

    try {
      // Check if there are messages from current user
      final messages = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('senderId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (messages.docs.isNotEmpty) {
        debugPrint('[ChatViewModel] sendInitialMessage skipped: existing message found');
        return; // already sent
      }

      await sendMessage("Hi! Is the $itemName still available?");
    } catch (e, stack) {
      debugPrint('[ChatViewModel] sendInitialMessage error: $e');
      debugPrint(stack.toString());
      // If permission denied or other error, still try to send the message
      await sendMessage("Hi! Is the $itemName still available?");
    }
  }

  Future<void> markMessagesAsRead() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('[ChatViewModel] markMessagesAsRead aborted: no currentUser');
      return;
    }

    debugPrint('[ChatViewModel] markMessagesAsRead for convo $conversationId, uid=${currentUser.uid}');

    try {
      final messagesRef = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages');

      final unreadMessages = await messagesRef
          .where('senderId', isNotEqualTo: currentUser.uid)
          .where('readAt', isNull: true)
          .get();

      debugPrint('[ChatViewModel] unreadMessages count=${unreadMessages.docs.length}');

      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'readAt': Timestamp.now()});
      }
      await batch.commit();
      debugPrint('[ChatViewModel] markMessagesAsRead committed successfully.');
    } catch (e, stack) {
      debugPrint('[ChatViewModel] markMessagesAsRead error: $e');
      debugPrint(stack.toString());
    }
  }
}