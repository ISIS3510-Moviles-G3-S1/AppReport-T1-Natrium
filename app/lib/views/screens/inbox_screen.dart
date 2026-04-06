import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_theme.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('conversations')
            .where('participants', arrayContains: currentUser.uid)
            .snapshots(),
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

          final conversations = snapshot.data?.docs ?? [];

          // Sort conversations by lastMessageAt in memory
          conversations.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTimestamp = aData['lastMessageAt'] as Timestamp?;
            final bTimestamp = bData['lastMessageAt'] as Timestamp?;
            
            if (aTimestamp == null && bTimestamp == null) return 0;
            if (aTimestamp == null) return 1;
            if (bTimestamp == null) return -1;
            
            return bTimestamp.compareTo(aTimestamp); // descending order
          });

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
              final doc = conversations[index];
              final data = doc.data() as Map<String, dynamic>;
              final participants = data['participants'] as List<dynamic>? ?? [];
              final otherUserId = participants.firstWhere(
                (id) => id != currentUser.uid,
                orElse: () => '',
              );

              final lastMessageText = data['lastMessageText'] as String? ?? 'No messages';
              final lastMessageAt = data['lastMessageAt'] as Timestamp?;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
                  child: Icon(
                    Icons.person,
                    color: AppTheme.accent,
                  ),
                ),
                title: FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('users').doc(otherUserId).get(),
                  builder: (context, userSnap) {
                    if (userSnap.hasData && userSnap.data?.exists == true) {
                      final userData = userSnap.data!.data() as Map<String, dynamic>;
                      final displayName = userData['displayName'] as String? ?? 'Unknown';
                      return Text(displayName);
                    }
                    return const Text('Unknown User');
                  },
                ),
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
                    if (lastMessageAt != null)
                      Text(
                        _formatTime(lastMessageAt.toDate()),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    // TODO: Add unread count badge
                  ],
                ),
                onTap: () {
                  // Navigate to chat screen
                  final ids = [currentUser.uid, otherUserId]..sort();
                  final conversationId = ids.join('_');
                  // Navigate to chat - you'll need to pass the other user's name
                  // For now, just use the ID as a placeholder
                  context.go('/chat/$conversationId/$otherUserId/User/${Uri.encodeComponent('Item')}');
                },
              );
            },
          );
        },
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
