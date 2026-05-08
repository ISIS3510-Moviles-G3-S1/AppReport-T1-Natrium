import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/chat_local_storage.dart';
import '../data/chat_sync_service.dart';
import '../data/chat_draft_storage.dart';
import '../models/message.dart';

class ChatViewModel extends ChangeNotifier {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String itemName;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChatLocalStorage _localStorage = ChatLocalStorage.instance;
  final ChatSyncService _syncService = ChatSyncService.instance;
  final ChatDraftStorage _draftStorage = ChatDraftStorage.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _remoteMessagesSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Stream<List<Message>>? _messagesStream;
  bool _isInitialized = false;
  bool _isOffline = false;

  bool get isOffline => _isOffline;

  ChatViewModel({
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    required this.itemName,
  });

  Stream<List<Message>> get messagesStream {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(const []);
    }

    if (!_isInitialized) {
      unawaited(initialize());
    }

    return _messagesStream ??
        _localStorage.watchMessages(
          userId: user.uid,
          conversationId: conversationId,
        );
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return;
    }

    _isInitialized = true;
    _messagesStream = _localStorage.watchMessages(
      userId: currentUser.uid,
      conversationId: conversationId,
    );

    await _localStorage.upsertConversation(
      userId: currentUser.uid,
      conversationId: conversationId,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      itemName: itemName,
      lastMessageText: '',
      lastMessageAt: DateTime.now().millisecondsSinceEpoch,
      lastMessageStatus: 'sent',
    );

    await _refreshConnectivity();
    _subscribeConnectivity();

    if (!_isOffline) {
      await ensureConversationExists();
      await _syncService.preloadAllConversationsForCurrentUser();
      _startRemoteMessagesListener();
      await _syncService.syncPendingMessagesForCurrentUser();
    }

    notifyListeners();
  }

  Future<void> _refreshConnectivity() async {
    final connectivity = await Connectivity().checkConnectivity();
    _isOffline = _isDisconnected(connectivity);
  }

  void _subscribeConnectivity() {
    _connectivitySub ??= Connectivity().onConnectivityChanged.listen((results) {
      final wasOffline = _isOffline;
      _isOffline = _isDisconnected(results);

      if (wasOffline && !_isOffline) {
        unawaited(ensureConversationExists());
        unawaited(_syncService.preloadAllConversationsForCurrentUser());
        _startRemoteMessagesListener();
        unawaited(_syncService.syncPendingMessagesForCurrentUser());
      }

      if (_isOffline) {
        _remoteMessagesSub?.cancel();
        _remoteMessagesSub = null;
      }

      notifyListeners();
    });
  }

  bool _isDisconnected(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return true;
    }
    return results.every((result) => result == ConnectivityResult.none);
  }

  void _startRemoteMessagesListener() {
    if (_remoteMessagesSub != null) {
      return;
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return;
    }

    _remoteMessagesSub = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .listen((snapshot) async {
      for (final doc in snapshot.docs) {
        final message = Message.fromFirestore(doc);
        await _localStorage.upsertRemoteMessage(
          userId: currentUser.uid,
          conversationId: conversationId,
          message: message,
        );
      }

      await _localStorage.refreshConversationFromMessages(
        userId: currentUser.uid,
        conversationId: conversationId,
        fallbackOtherUserId: otherUserId,
        fallbackOtherUserName: otherUserName,
        fallbackItemName: itemName,
      );
    }, onError: (error, stack) {
      debugPrint('[ChatViewModel] Remote listener failed: $error');
      debugPrint(stack.toString());
    });
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

    final normalized = text.trim();
    if (normalized.isEmpty) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    await _localStorage.enqueueOutgoingMessage(
      userId: currentUser.uid,
      conversationId: conversationId,
      senderId: currentUser.uid,
      text: normalized,
    );

    await _localStorage.upsertConversation(
      userId: currentUser.uid,
      conversationId: conversationId,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      itemName: itemName,
      lastMessageText: normalized,
      lastMessageAt: now,
      lastMessageStatus: 'pending',
    );

    if (!_isOffline) {
      await _syncService
          .syncPendingMessagesForCurrentUser()
          .then((_) {
            debugPrint('[ChatViewModel] Pending messages synced after send.');
          })
          .catchError((error, stack) {
            debugPrint('[ChatViewModel] Pending sync after send failed: $error');
            debugPrint(stack.toString());
          });
    }
  }

  Future<void> saveDraftForCurrentUser(String text) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    await _draftStorage.saveDraft(
      userId: currentUser.uid,
      conversationId: conversationId,
      text: text,
    );
  }

  Future<String> getDraftForCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return '';
    return _draftStorage.getDraft(
      userId: currentUser.uid,
      conversationId: conversationId,
    );
  }

  Future<void> clearDraftForCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    await _draftStorage.clearDraft(
      userId: currentUser.uid,
      conversationId: conversationId,
    );
  }

  Future<void> sendInitialMessage() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('[ChatViewModel] sendInitialMessage aborted: no currentUser');
      return;
    }

    final cached = await _localStorage.getMessages(
      userId: currentUser.uid,
      conversationId: conversationId,
    );

    if (cached.isNotEmpty) {
      return;
    }

    await sendMessage('Hi! Is the $itemName still available?');
  }

  Future<void> markMessagesAsRead() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('[ChatViewModel] markMessagesAsRead aborted: no currentUser');
      return;
    }

    await _localStorage.markMessagesAsRead(
      userId: currentUser.uid,
      conversationId: conversationId,
      currentUserId: currentUser.uid,
    );

    if (_isOffline) {
      return;
    }

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

  @override
  void dispose() {
    _remoteMessagesSub?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }
}