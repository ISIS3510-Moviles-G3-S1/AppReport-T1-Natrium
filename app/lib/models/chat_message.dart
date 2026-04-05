import 'package:uuid/uuid.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isFromCurrentUser;
  final DateTime date;

  ChatMessage({
    String? id,
    required this.text,
    required this.isFromCurrentUser,
    DateTime? date,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now();

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isFromCurrentUser,
    DateTime? date,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isFromCurrentUser: isFromCurrentUser ?? this.isFromCurrentUser,
      date: date ?? this.date,
    );
  }
}
