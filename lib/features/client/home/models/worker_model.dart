class WorkerModel {
  final String id;
  final String name;
  final String avatarUrl;
  final String specialty;
  final String price;
  final String city;
  final String experience;
  final double rating;
  final int completedOrders;
  final int reviewCount;
  final int age;
  final bool hasBrigade;
  final List<String> tags;
  final List<String> bio;
  final List<String> primaryCategoryIds;
  final List<String> canDoCategoryIds;

  const WorkerModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.specialty,
    required this.price,
    required this.city,
    required this.experience,
    required this.rating,
    required this.completedOrders,
    required this.reviewCount,
    this.age = 25,
    this.hasBrigade = false,
    this.tags = const [],
    this.bio = const [],
    this.primaryCategoryIds = const [],
    this.canDoCategoryIds = const [],
  });

  List<String> get allCategoryIds => <String>{
    ...primaryCategoryIds,
    ...canDoCategoryIds,
  }.toList(growable: false);

  static String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final s = value.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }

  static double _asDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? fallback;
  }

  static bool _asBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    final v = value.toString().toLowerCase();
    if (v == 'true' || v == '1' || v == 'yes') return true;
    if (v == 'false' || v == '0' || v == 'no') return false;
    return fallback;
  }

  static List<String> _asStringList(
    dynamic value, {
    List<String> fallback = const [],
  }) {
    if (value == null) return fallback;
    if (value is List) {
      final list = value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
      return list.isEmpty ? fallback : list;
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return fallback;
      if (trimmed.contains(',')) {
        final list = trimmed
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        return list.isEmpty ? fallback : list;
      }
      return [trimmed];
    }
    return fallback;
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, itemValue) => MapEntry(key.toString(), itemValue));
    }
    return <String, dynamic>{};
  }

  static String _firstNonEmpty(
    Iterable<String?> values, {
    String fallback = '',
  }) {
    for (final raw in values) {
      final value = (raw ?? '').trim();
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }

  // FIREBASE-ТАН КЕЛГЕН "MAP"-ТЫ МОДЕЛЬГЕ АЙНАЛДЫРУ
  factory WorkerModel.fromMap(Map<String, dynamic> data, String docId) {
    final name = _asString(
      data['fullName'] ?? data['firstName'] ?? data['name'],
      fallback: 'Аты жоқ',
    );
    final avatarRaw = _asString(data['avatarUrl']);
    final avatarUrl = avatarRaw.isNotEmpty ? avatarRaw : '';
    final hourlyRate = data['hourlyRate'] ?? data['price'] ?? data['rate'];
    final priceText = _asString(hourlyRate, fallback: 'Келісім');
    final locationMap = _asMap(data['location']);
    final legacyLocation = data['location'] is String
        ? _asString(data['location'])
        : '';
    final locationShort = _firstNonEmpty(<String?>[
      _asString(data['locationShort']),
      _asString(data['locationLabel']),
      _asString(locationMap['shortLabel']),
      legacyLocation,
      _asString(data['city']),
    ], fallback: 'Алматы');

    final primaryCategoryIds = _asStringList(data['primaryCategoryIds']);
    final canDoCategoryIds = _asStringList(
      data['canDoCategoryIds'],
    ).where((id) => !primaryCategoryIds.contains(id)).toList(growable: false);

    return WorkerModel(
      id: docId,
      name: name,
      avatarUrl: avatarUrl,
      specialty: _asString(data['specialty'], fallback: 'Маман'),
      price: "$priceText ₸",
      city: locationShort,
      experience: _asString(data['experience'], fallback: '1 жыл'),
      rating: _asDouble(data['rating'], fallback: 5.0),
      completedOrders: _asInt(data['completedOrders'], fallback: 0),
      reviewCount: _asInt(data['reviewCount'], fallback: 0),
      age: _asInt(data['age'], fallback: 25),
      hasBrigade: _asBool(data['hasBrigade'], fallback: false),
      tags: _asStringList(data['tags'], fallback: const ['Сапалы', 'Жылдам']),
      bio: _asStringList(
        data['about'],
        fallback: const ['Қосымша ақпарат жоқ.'],
      ),
      primaryCategoryIds: primaryCategoryIds,
      canDoCategoryIds: canDoCategoryIds,
    );
  }
}
