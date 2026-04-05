import 'package:uuid/uuid.dart';
import 'chat_message.dart';

class ChatConversation {
  final String id;
  final String sellerName;
  final String productID;
  final String productTitle;
  final String productImageUrl;
  final List<ChatMessage> messages;
  final int unreadCount;
  final DateTime lastMessageDate;

  ChatConversation({
    String? id,
    required this.sellerName,
    required this.productID,
    required this.productTitle,
    required this.productImageUrl,
    List<ChatMessage>? messages,
    this.unreadCount = 0,
    DateTime? lastMessageDate,
  })  : id = id ?? const Uuid().v4(),
        messages = messages ?? [],
        lastMessageDate = lastMessageDate ?? DateTime.now();

  /// Returns the last message text or empty string if no messages
  String get lastMessagePreview {
    if (messages.isEmpty) return '';
    return messages.last.text;
  }

  ChatConversation copyWith({
    String? id,
    String? sellerName,
    String? productID,
    String? productTitle,
    String? productImageUrl,
    List<ChatMessage>? messages,
    int? unreadCount,
    DateTime? lastMessageDate,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      sellerName: sellerName ?? this.sellerName,
      productID: productID ?? this.productID,
      productTitle: productTitle ?? this.productTitle,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      messages: messages ?? this.messages,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageDate: lastMessageDate ?? this.lastMessageDate,
    );
  }

  /// Add a message to the conversation
  ChatConversation addMessage(ChatMessage message) {
    return copyWith(
      messages: [...messages, message],
      lastMessageDate: message.date,
    );
  }
}
