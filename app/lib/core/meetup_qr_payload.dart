import 'dart:convert';

class MeetupQrPayload {
  final String transactionId;
  final String listingId;
  final String sellerId;
  final String buyerId;

  const MeetupQrPayload({
    required this.transactionId,
    required this.listingId,
    required this.sellerId,
    required this.buyerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'listingId': listingId,
      'sellerId': sellerId,
      'buyerId': buyerId,
    };
  }

  String encode() => jsonEncode(toJson());

  factory MeetupQrPayload.decode(String rawValue) {
    final dynamic decoded = jsonDecode(rawValue);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('QR code payload is not a JSON object');
    }

    String readRequiredKey(String key) {
      final value = decoded[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Missing or invalid "$key" in QR payload');
      }
      return value.trim();
    }

    return MeetupQrPayload(
      transactionId: readRequiredKey('transactionId'),
      listingId: readRequiredKey('listingId'),
      sellerId: readRequiredKey('sellerId'),
      buyerId: readRequiredKey('buyerId'),
    );
  }
}
