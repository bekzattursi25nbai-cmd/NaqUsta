import 'package:cloud_firestore/cloud_firestore.dart';

enum MarketplaceOfferStatus { sent, accepted, rejected }

extension MarketplaceOfferStatusX on MarketplaceOfferStatus {
  String get wire {
    switch (this) {
      case MarketplaceOfferStatus.sent:
        return 'SENT';
      case MarketplaceOfferStatus.accepted:
        return 'ACCEPTED';
      case MarketplaceOfferStatus.rejected:
        return 'REJECTED';
    }
  }

  static MarketplaceOfferStatus fromWire(String? raw) {
    switch ((raw ?? '').trim().toUpperCase()) {
      case 'ACCEPTED':
        return MarketplaceOfferStatus.accepted;
      case 'REJECTED':
      case 'INACTIVE':
        return MarketplaceOfferStatus.rejected;
      case 'SENT':
      default:
        return MarketplaceOfferStatus.sent;
    }
  }
}

class MarketplaceOffer {
  const MarketplaceOffer({
    required this.id,
    required this.orderId,
    required this.workerId,
    required this.offeredPrice,
    required this.message,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
  });

  final String id;
  final String orderId;
  final String workerId;

  final double offeredPrice;
  final String message;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final MarketplaceOfferStatus status;

  bool get isSent => status == MarketplaceOfferStatus.sent;

  bool get isAccepted => status == MarketplaceOfferStatus.accepted;

  bool get isRejected => status == MarketplaceOfferStatus.rejected;

  static String documentId({
    required String orderId,
    required String workerId,
  }) {
    return '${orderId}_$workerId';
  }

  factory MarketplaceOffer.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return MarketplaceOffer.fromMap(data, id: doc.id);
  }

  factory MarketplaceOffer.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return MarketplaceOffer(
      id: id,
      orderId: (map['orderId'] ?? '').toString(),
      workerId: (map['workerId'] ?? '').toString(),
      offeredPrice: _asDouble(map['offeredPrice']),
      message: (map['message'] ?? '').toString().trim(),
      createdAt: _asDateTime(map['createdAt']),
      updatedAt: _asDateTime(map['updatedAt']),
      status: MarketplaceOfferStatusX.fromWire(
        (map['status'] ?? '').toString(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'orderId': orderId,
      'workerId': workerId,
      'offeredPrice': offeredPrice,
      'message': message,
      'status': status.wire,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value == null) return fallback;
  final parsed = double.tryParse(value.toString().replaceAll(',', '.'));
  return parsed ?? fallback;
}

DateTime? _asDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
