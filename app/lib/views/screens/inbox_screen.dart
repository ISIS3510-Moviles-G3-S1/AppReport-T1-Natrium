import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../data/chat_local_storage.dart';
import '../../data/chat_sync_service.dart';
import '../../core/app_theme.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChatLocalStorage _localStorage = ChatLocalStorage.instance;
  final ChatSyncService _syncService = ChatSyncService.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _remoteConversationSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _refreshConnectivity();
    _listenConnectivity();

    if (!_isOffline) {
      await _syncService.preloadAllConversationsForCurrentUser();
      _startRemoteConversationSync();
      await _syncService.syncPendingMessagesForCurrentUser();
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _refreshConnectivity() async {
    final connectivity = await Connectivity().checkConnectivity();
    _isOffline = _isDisconnected(connectivity);
  }

  void _listenConnectivity() {
    _connectivitySub ??= Connectivity().onConnectivityChanged.listen((results) {
      final wasOffline = _isOffline;
      _isOffline = _isDisconnected(results);

      if (wasOffline && !_isOffline) {
        unawaited(_syncService.preloadAllConversationsForCurrentUser());
        _startRemoteConversationSync();
        unawaited(_syncService.syncPendingMessagesForCurrentUser());
      }

      if (_isOffline) {
        _remoteConversationSub?.cancel();
        _remoteConversationSub = null;
      }

      if (mounted) {
        setState(() {});
      }
    });
  }

  bool _isDisconnected(List<ConnectivityResult> results) {
    if (results.isEmpty) return true;
    return results.every((result) => result == ConnectivityResult.none);
  }

  void _startRemoteConversationSync() {
    if (_remoteConversationSub != null) {
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    _remoteConversationSub = _firestore
        .collection('conversations')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .listen((snapshot) async {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final participants = (data['participants'] as List<dynamic>? ?? [])
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
        final displayName =
            (userData?['displayName'] as String?)?.trim().isNotEmpty == true
                ? (userData?['displayName'] as String).trim()
                : 'Unknown User';

        final lastMessageAt = data['lastMessageAt'] as Timestamp?;

        await _localStorage.upsertConversation(
          userId: user.uid,
          conversationId: doc.id,
          otherUserId: otherUserId,
          otherUserName: displayName,
          itemName: (data['itemName'] as String?) ?? '',
          lastMessageText: (data['lastMessageText'] as String?) ?? '',
          lastMessageAt:
              lastMessageAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
          lastMessageStatus: (data['lastMessageStatus'] as String?) ?? 'sent',
          notify: false,
        );
      }

      _localStorage.notifyChanged();
    }, onError: (error, stack) {
      debugPrint('[InboxScreen] remote sync failed: $error');
      debugPrint(stack.toString());
    });
  }

  @override
  void dispose() {
    _remoteConversationSub?.cancel();
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inbox')),
        body: const Center(
          child: Text('Please log in to view your inbox'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: double.infinity,
            height: _isOffline ? 52 : 0,
            color: Colors.amber.shade700,
            alignment: Alignment.center,
            child: _isOffline
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "You're offline. Pending messages will be sent as soon as connectivity is back.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  )
                : null,
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _localStorage.watchConversations(userId: currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: ${snapshot.error}'),
              ),
            );
          }

          final conversations = snapshot.data ?? const <Map<String, dynamic>>[];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mail_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a conversation by messaging a seller',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: Colors.grey[300],
            ),
            itemBuilder: (context, index) {
              final data = conversations[index];
              final otherUserId = (data['other_user_id'] as String?) ?? '';
              final otherUserName =
                  ((data['other_user_name'] as String?) ?? '').trim().isEmpty
                      ? 'Unknown User'
                      : (data['other_user_name'] as String).trim();
              final itemName = (data['item_name'] as String?) ?? '';
              final lastMessageText = (data['last_message_text'] as String?) ?? 'No messages yet';
              final lastMessageAtMillis = (data['last_message_at'] as int?) ?? 0;
              final lastMessageStatus = (data['last_message_status'] as String?) ?? 'sent';
              final conversationId = (data['conversation_id'] as String?) ?? '';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
                  child: Icon(
                    Icons.person,
                    color: AppTheme.accent,
                  ),
                ),
                title: Text(otherUserName),
                subtitle: Text(
                  lastMessageText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: 4,
                  children: [
                    if (lastMessageAtMillis > 0)
                      Text(
                        _formatTime(DateTime.fromMillisecondsSinceEpoch(lastMessageAtMillis)),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    if (lastMessageStatus == 'pending')
                      const Icon(
                        Icons.schedule,
                        size: 14,
                        color: Colors.orange,
                      ),
                  ],
                ),
                onTap: () {
                  if (conversationId.isEmpty || otherUserId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('This conversation is missing identifiers and cannot be opened.'),
                      ),
                    );
                    return;
                  }

                  context.go(
                    '/chat/$conversationId/$otherUserId?otherUserName=${Uri.encodeQueryComponent(otherUserName)}&itemName=${Uri.encodeQueryComponent(itemName)}',
                  );
                },
              );
            },
          );
        },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}
