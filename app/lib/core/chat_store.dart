import 'package:flutter/foundation.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';

class ChatStore extends ChangeNotifier {
  List<ChatConversation> _conversations = [];

  List<ChatConversation> get conversations => _conversations;

  /// Returns the sum of all unread counts across conversations
  int get totalUnreadCount {
    return _conversations.fold<int>(
      0,
      (sum, conv) => sum + conv.unreadCount,
    );
  }

  /// Start a new conversation or reuse existing if product+seller match
  String startConversation({
    required String productID,
    required String productTitle,
    required String sellerName,
    required String productImageUrl,
  }) {
    // Check if conversation already exists for this product and seller
    final existingIndex = _conversations.indexWhere(
      (conv) => conv.productID == productID && conv.sellerName == sellerName,
    );

    if (existingIndex != -1) {
      // Reuse existing conversation - move to top
      final existing = _conversations.removeAt(existingIndex);
      _conversations.insert(0, existing);
      notifyListeners();
      return existing.id;
    }

    // Create new conversation with initial message
    final initialMessage = ChatMessage(
      text: 'Hi! Is this still available?',
      isFromCurrentUser: true,
    );

    final newConversation = ChatConversation(
      sellerName: sellerName,
      productID: productID,
      productTitle: productTitle,
      productImageUrl: productImageUrl,
      messages: [initialMessage],
      unreadCount: 0,
    );

    // Insert at the top
    _conversations.insert(0, newConversation);
    notifyListeners();

    return newConversation.id;
  }

  /// Send a message in a conversation
  void sendMessage({
    required String conversationId,
    required String text,
    bool isFromCurrentUser = true,
  }) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    final index = _conversations.indexWhere((conv) => conv.id == conversationId);
    if (index == -1) return;

    final message = ChatMessage(
      text: trimmedText,
      isFromCurrentUser: isFromCurrentUser,
    );

    var updatedConversation = _conversations[index].addMessage(message);

    // If message is from other user (seller), increment unread
    if (!isFromCurrentUser) {
      updatedConversation = updatedConversation.copyWith(
        unreadCount: updatedConversation.unreadCount + 1,
      );
    }

    // Move conversation to top
    _conversations.removeAt(index);
    _conversations.insert(0, updatedConversation);

    notifyListeners();
  }

  /// Mark conversation as read (clear unread count)
  void markConversationAsRead(String conversationId) {
    final index = _conversations.indexWhere((conv) => conv.id == conversationId);
    if (index == -1) return;

    final conversation = _conversations[index];
    if (conversation.unreadCount == 0) return;

    _conversations[index] = conversation.copyWith(unreadCount: 0);
    notifyListeners();
  }

  /// Get conversation by ID
  ChatConversation? getConversation(String conversationId) {
    try {
      return _conversations.firstWhere((conv) => conv.id == conversationId);
    } catch (e) {
      return null;
    }
  }
}
