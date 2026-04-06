import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String text;
  final List<String> imageURLs;
  final String type;
  final Timestamp sentAt;
  final Timestamp? readAt;
  final String status;
  final Map<String, dynamic>? replyTo;
  final Map<String, dynamic>? listingSnapshot;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.imageURLs,
    required this.type,
    required this.sentAt,
    this.readAt,
    required this.status,
    this.replyTo,
    this.listingSnapshot,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      imageURLs: List<String>.from(data['imageURLs'] ?? []),
      type: data['type'] ?? 'text',
      sentAt: data['sentAt'] ?? Timestamp.now(),
      readAt: data['readAt'],
      status: data['status'] ?? 'sent',
      replyTo: data['replyTo'],
      listingSnapshot: data['listingSnapshot'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'text': text,
      'imageURLs': imageURLs,
      'type': type,
      'sentAt': sentAt,
      'readAt': readAt,
      'status': status,
      if (replyTo != null) 'replyTo': replyTo,
      if (listingSnapshot != null) 'listingSnapshot': listingSnapshot,
    };
  }
}