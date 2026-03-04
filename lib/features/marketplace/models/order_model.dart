import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kuryl_kz/features/location/models/kato_models.dart';

enum MarketplaceOrderStatus { open, inProgress, completed, cancelled }

extension MarketplaceOrderStatusX on MarketplaceOrderStatus {
  String get wire {
    switch (this) {
      case MarketplaceOrderStatus.open:
        return 'OPEN';
      case MarketplaceOrderStatus.inProgress:
        return 'IN_PROGRESS';
      case MarketplaceOrderStatus.completed:
        return 'COMPLETED';
      case MarketplaceOrderStatus.cancelled:
        return 'CANCELLED';
    }
  }

  static MarketplaceOrderStatus fromWire(String? raw) {
    final normalized = (raw ?? '').trim().toUpperCase();
    switch (normalized) {
      case 'IN_PROGRESS':
      case 'ACTIVE':
      case 'ACCEPTED':
        return MarketplaceOrderStatus.inProgress;
      case 'COMPLETED':
      case 'DONE':
      case 'FINISHED':
        return MarketplaceOrderStatus.completed;
      case 'CANCELLED':
      case 'CANCELED':
        return MarketplaceOrderStatus.cancelled;
      case 'OPEN':
      case 'PENDING':
      default:
        return MarketplaceOrderStatus.open;
    }
  }
}

class MarketplaceOrder {
  const MarketplaceOrder({
    required this.id,
    required this.clientId,
    required this.title,
    required this.categoryId,
    required this.categoryPathIds,
    required this.categoryRootId,
    required this.categoryName,
    required this.description,
    required this.budgetPrice,
    required this.negotiable,
    required this.locationShort,
    required this.location,
    required this.photos,
    required this.status,
    required this.createdAt,
    required this.acceptedWorkerId,
    required this.doneByWorker,
    required this.doneByClient,
    required this.cancelledBy,
    required this.cancelReason,
    required this.offerWorkerIds,
    required this.offersCount,
    required this.updatedAt,
    required this.reviewCreatedAt,
  });

  final String id;
  final String clientId;

  final String title;
  final String categoryId;
  final List<String> categoryPathIds;
  final String categoryRootId;
  final String categoryName;
  final String description;

  final double? budgetPrice;
  final bool negotiable;
  final String locationShort;
  final LocationBreakdown? location;
  final List<String> photos;

  final MarketplaceOrderStatus status;
  final DateTime? createdAt;
  final String? acceptedWorkerId;

  final bool doneByWorker;
  final bool doneByClient;

  final String? cancelledBy;
  final String? cancelReason;

  final List<String> offerWorkerIds;
  final int offersCount;

  final DateTime? updatedAt;
  final DateTime? reviewCreatedAt;

  bool get hasPhoto => photos.isNotEmpty;

  bool get isOpen => status == MarketplaceOrderStatus.open;

  bool get isInProgress => status == MarketplaceOrderStatus.inProgress;

  bool get isCompleted => status == MarketplaceOrderStatus.completed;

  bool get isCancelled => status == MarketplaceOrderStatus.cancelled;

  String get budgetLabel {
    if (negotiable) return 'Келісімді';
    if (budgetPrice == null) return 'Келісімді';
    final normalized = budgetPrice!.round();
    return '${_formatWithSpaces(normalized)} ₸';
  }

  factory MarketplaceOrder.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return MarketplaceOrder.fromMap(data, id: doc.id);
  }

  factory MarketplaceOrder.fromMap(
    Map<String, dynamic> data, {
    required String id,
  }) {
    final categoryId = _asString(data['categoryId']);
    final categoryPathIds = _asStringList(data['categoryPathIds']);
    final effectivePathIds = categoryPathIds.isNotEmpty
        ? categoryPathIds
        : (categoryId.isEmpty ? const <String>[] : <String>[categoryId]);
    final parsedLocation = LocationBreakdown.fromDocumentData(data);
    final effectiveLocation = parsedLocation != null && parsedLocation.isValid
        ? parsedLocation
        : null;
    final legacyLocation = data['location'] is String
        ? data['location'] as String
        : null;

    return MarketplaceOrder(
      id: id,
      clientId: _asString(data['clientId']),
      title: _asString(data['title']),
      categoryId: categoryId,
      categoryPathIds: effectivePathIds,
      categoryRootId: _asString(
        data['categoryRootId'],
        fallback: effectivePathIds.isNotEmpty ? effectivePathIds.first : '',
      ),
      categoryName: _asString(
        data['categoryName'] ?? data['category'] ?? data['categoryLabel'],
      ),
      description: _asString(data['description']),
      budgetPrice: _asNullableDouble(data['budgetPrice'] ?? data['price']),
      negotiable: _asBool(data['negotiable']),
      locationShort: _asString(
        data['locationShort'] ??
            data['locationLabel'] ??
            effectiveLocation?.shortLabel ??
            legacyLocation ??
            data['address'],
      ),
      location: effectiveLocation,
      photos: _asStringList(data['photos'] ?? data['images']),
      status: MarketplaceOrderStatusX.fromWire(_asString(data['status'])),
      createdAt: _asDateTime(data['createdAt'] ?? data['created_at']),
      acceptedWorkerId: _asNullableString(data['acceptedWorkerId']),
      doneByWorker: _asBool(data['doneByWorker']),
      doneByClient: _asBool(data['doneByClient']),
      cancelledBy: _asNullableString(data['cancelledBy']),
      cancelReason: _asNullableString(data['cancelReason']),
      offerWorkerIds: _asStringList(data['offerWorkerIds']),
      offersCount: _asInt(data['offersCount']),
      updatedAt: _asDateTime(data['updatedAt'] ?? data['updated_at']),
      reviewCreatedAt: _asDateTime(data['reviewCreatedAt']),
    );
  }

  Map<String, dynamic> toMapForCreate() {
    final map = <String, dynamic>{
      'clientId': clientId,
      'title': title,
      'categoryId': categoryId,
      'categoryPathIds': categoryPathIds,
      'categoryRootId': categoryRootId,
      'categoryName': categoryName,
      'description': description,
      'budgetPrice': budgetPrice,
      'negotiable': negotiable,
      'locationShort': locationShort,
      'photos': photos,
      'status': MarketplaceOrderStatus.open.wire,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'acceptedWorkerId': null,
      'doneByWorker': false,
      'doneByClient': false,
      'cancelledBy': null,
      'cancelReason': null,
      'offerWorkerIds': <String>[],
      'offersCount': 0,
    };

    final locationData = location;
    if (locationData != null && locationData.isValid) {
      map['location'] = locationData.toFirestoreMap();
      map.addAll(locationData.toDenormalizedFields());
      map['locationShort'] = locationShort;
    }

    return map;
  }
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String? _asNullableString(dynamic value) {
  final text = _asString(value);
  if (text.isEmpty || text.toLowerCase() == 'null') return null;
  return text;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value == null) return fallback;
  final text = value.toString().toLowerCase();
  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;
  return fallback;
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value == null) return fallback;
  return int.tryParse(value.toString()) ?? fallback;
}

double? _asNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();

  final normalized = value.toString().replaceAll(',', '.').trim();
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

DateTime? _asDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return <String>[];
}

String _formatWithSpaces(int number) {
  final digits = number.toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    final reverseIndex = digits.length - i;
    buffer.write(digits[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(' ');
    }
  }

  return buffer.toString();
}
