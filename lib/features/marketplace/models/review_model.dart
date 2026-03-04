import 'package:cloud_firestore/cloud_firestore.dart';

class MarketplaceReview {
  const MarketplaceReview({
    required this.id,
    required this.orderId,
    required this.workerId,
    required this.clientId,
    required this.rating,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String orderId;
  final String workerId;
  final String clientId;

  final int rating;
  final String text;

  final DateTime? createdAt;

  factory MarketplaceReview.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final map = doc.data() ?? <String, dynamic>{};
    return MarketplaceReview.fromMap(map, id: doc.id);
  }

  factory MarketplaceReview.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return MarketplaceReview(
      id: id,
      orderId: (map['orderId'] ?? '').toString(),
      workerId: (map['workerId'] ?? '').toString(),
      clientId: (map['clientId'] ?? '').toString(),
      rating: _asInt(map['rating']),
      text: (map['text'] ?? '').toString().trim(),
      createdAt: _asDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'orderId': orderId,
      'workerId': workerId,
      'clientId': clientId,
      'rating': rating,
      'text': text,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value == null) return fallback;
  return int.tryParse(value.toString()) ?? fallback;
}

DateTime? _asDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
