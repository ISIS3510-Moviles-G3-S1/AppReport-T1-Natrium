import 'package:cloud_firestore/cloud_firestore.dart';

enum MeetupTransactionStatus { pending, confirmed, completed }

MeetupTransactionStatus meetupStatusFromString(String value) {
  switch (value) {
    case 'confirmed':
      return MeetupTransactionStatus.confirmed;
    case 'completed':
      return MeetupTransactionStatus.completed;
    case 'pending':
    default:
      return MeetupTransactionStatus.pending;
  }
}

String meetupStatusToString(MeetupTransactionStatus status) {
  switch (status) {
    case MeetupTransactionStatus.confirmed:
      return 'confirmed';
    case MeetupTransactionStatus.completed:
      return 'completed';
    case MeetupTransactionStatus.pending:
      return 'pending';
  }
}

class MeetupTransaction {
  final String transactionId;
  final String listingId;
  final String sellerId;
  final String buyerId;
  final MeetupTransactionStatus status;
  final DateTime? createdAt;
  final DateTime? confirmedAt;

  const MeetupTransaction({
    required this.transactionId,
    required this.listingId,
    required this.sellerId,
    required this.buyerId,
    required this.status,
    this.createdAt,
    this.confirmedAt,
  });

  bool get isPending => status == MeetupTransactionStatus.pending;
  bool get isConfirmed => status == MeetupTransactionStatus.confirmed;
  bool get isCompleted => status == MeetupTransactionStatus.completed;

  MeetupTransaction copyWith({
    String? transactionId,
    String? listingId,
    String? sellerId,
    String? buyerId,
    MeetupTransactionStatus? status,
    DateTime? createdAt,
    DateTime? confirmedAt,
  }) {
    return MeetupTransaction(
      transactionId: transactionId ?? this.transactionId,
      listingId: listingId ?? this.listingId,
      sellerId: sellerId ?? this.sellerId,
      buyerId: buyerId ?? this.buyerId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'transactionId': transactionId,
      'listingId': listingId,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'status': meetupStatusToString(status),
      'createdAt': createdAt,
      'confirmedAt': confirmedAt,
    };
  }

  factory MeetupTransaction.fromMap(Map<String, dynamic> data) {
    return MeetupTransaction(
      transactionId: (data['transactionId'] as String?) ?? '',
      listingId: (data['listingId'] as String?) ?? '',
      sellerId: (data['sellerId'] as String?) ?? '',
      buyerId: (data['buyerId'] as String?) ?? '',
      status: meetupStatusFromString((data['status'] as String?) ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory MeetupTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MeetupTransaction.fromMap({
      ...data,
      'transactionId': (data['transactionId'] as String?) ?? doc.id,
    });
  }
}
