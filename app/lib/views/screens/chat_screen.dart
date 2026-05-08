import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../view_models/chat_view_model.dart';
import '../../models/message.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String itemName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    required this.itemName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _readMarked = false;
  bool _initialSent = false;
  int _previousMessageCount = 0;
  String? _errorMessage;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatViewModel>().initialize();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty && !_isSending) {
      setState(() => _isSending = true);
      _messageController.clear();
      final viewModel = context.read<ChatViewModel>();
      viewModel.sendMessage(text).then((_) {
        if (mounted) {
          setState(() {
            _isSending = false;
            _errorMessage = null;
          });
          _scrollToBottom();
        }
      }).catchError((e) {
        if (mounted) {
          setState(() {
            _isSending = false;
            _errorMessage = e.toString();
          });
        }
      });
    }
  }

  Future<void> _sendImage() async {
    final viewModel = context.read<ChatViewModel>();
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      
      setState(() => _isSending = true);
      
      // For now, just show a message indicating image support
      // Full implementation would require image upload service
      await viewModel.sendMessage('📷 Image');
      
      if (mounted) {
        setState(() {
          _isSending = false;
          _errorMessage = null;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _errorMessage = 'Failed to send image: $e';
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatViewModel>();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/inbox'),
        ),
      ),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: double.infinity,
            height: vm.isOffline ? 52 : 0,
            color: Colors.amber.shade700,
            alignment: Alignment.center,
            child: vm.isOffline
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
          // Listing banner
          if (widget.itemName.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? Colors.grey[900] : Colors.white.withValues(alpha: 0.6),
              child: Row(
                spacing: 10,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.shopping_bag, size: 20),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 1,
                      children: [
                        Text(
                          widget.itemName,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Item for sale',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Messages list
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: vm.messagesStream,
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
                
                final messages = snapshot.data ?? [];
                
                if (messages.isNotEmpty && !_readMarked) {
                  _readMarked = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.read<ChatViewModel>().markMessagesAsRead();
                  });
                }
                
                if (messages.isEmpty && !_initialSent) {
                  _initialSent = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.read<ChatViewModel>().sendInitialMessage();
                  });
                }
                
                if (messages.length > _previousMessageCount) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                  _previousMessageCount = messages.length;
                }
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser = message.senderId == currentUserId;
                    
                    return Align(
                      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          spacing: 2,
                          children: [
                            Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isCurrentUser 
                                  ? Theme.of(context).primaryColor 
                                  : (isDark ? Colors.grey[800] : Colors.grey[300]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 4,
                                children: [
                                  if (message.imageURLs.isNotEmpty)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        message.imageURLs.first,
                                        width: 180,
                                        height: 180,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  if (message.text.isNotEmpty)
                                    Text(
                                      message.text,
                                      style: TextStyle(
                                        color: isCurrentUser ? Colors.white : (isDark ? Colors.white : Colors.black),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 4,
                                children: [
                                  Text(
                                    _formatTime(message.sentAt.toDate()),
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                  if (isCurrentUser)
                                    message.status == 'pending'
                                        ? const Icon(
                                            Icons.schedule,
                                            size: 12,
                                            color: Colors.orange,
                                          )
                                        : Icon(
                                            message.readAt != null ? Icons.done_all : Icons.done,
                                            size: 12,
                                            color: message.readAt != null
                                                ? Theme.of(context).primaryColor
                                                : Colors.grey,
                                          ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Error banner
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.red.withValues(alpha: 0.85),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          
          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              spacing: 8,
              children: [
                IconButton(
                  onPressed: _isSending ? null : _sendImage,
                  icon: const Icon(Icons.photo),
                  tooltip: 'Add photo',
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Write a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      isDense: true,
                    ),
                    onSubmitted: _isSending ? null : (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSending ? null : _sendMessage,
                  icon: _isSending 
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      )
                    : const Icon(Icons.send),
                  color: Theme.of(context).primaryColor,
                ),
              ],
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
