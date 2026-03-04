class WorkerModel {
  final String id;
  final String name;
  final String city;
  final int experienceYears;
  final bool hasBrigade;
  final int? brigadeSize;
  final List<String> specs;
  final List<String> categories; // IDs
  final List<String> primaryCategoryIds;
  final List<String> canDoCategoryIds;
  final double rating;
  final int completedJobs;
  final int minPrice;
  final int maxPrice;
  final String avatarUrl; // For now using Icon
  final String bio;

  const WorkerModel({
    required this.id,
    required this.name,
    required this.city,
    required this.experienceYears,
    required this.hasBrigade,
    this.brigadeSize,
    required this.specs,
    required this.categories,
    this.primaryCategoryIds = const <String>[],
    this.canDoCategoryIds = const <String>[],
    this.rating = 5.0,
    this.completedJobs = 0,
    this.minPrice = 5000,
    this.maxPrice = 15000,
    this.avatarUrl = '',
    this.bio = '',
  });

  factory WorkerModel.fromMap(Map<String, dynamic> map, String id) {
    final specialties = _asStringList(
      map['specialties'] ?? map['services'] ?? map['skills'],
    );
    final locationMap = _asMap(map['location']);
    final city = _asString(map['city']);
    final district = _asString(map['district']);
    final village = _asString(map['village']);
    final legacyLocation = map['location'] is String
        ? _asString(map['location'])
        : '';

    final primaryCategoryIds = _asStringList(map['primaryCategoryIds']);
    final canDoCategoryIds = _asStringList(
      map['canDoCategoryIds'],
    ).where((id) => !primaryCategoryIds.contains(id)).toList();

    final effectiveCity = _firstNonEmpty(<String?>[
      city,
      _asString(map['locationShort']),
      _asString(map['locationLabel']),
      _asString(locationMap['shortLabel']),
      legacyLocation,
      [district, village].where((item) => item.trim().isNotEmpty).join(', '),
    ]);

    return WorkerModel(
      id: id,
      name: _asString(
        map['fullName'] ?? map['firstName'] ?? map['name'],
        fallback: 'Шебер',
      ),
      city: effectiveCity.isEmpty ? 'Белгісіз қала' : effectiveCity,
      experienceYears: _asInt(
        map['experienceYears'] ??
            map['experienceYearsInt'] ??
            map['experience'],
      ),
      hasBrigade: _asBool(map['hasBrigade']),
      brigadeSize: _asNullableInt(map['brigadeSize']),
      specs: specialties,
      categories: _asStringList(map['categories']),
      primaryCategoryIds: primaryCategoryIds,
      canDoCategoryIds: canDoCategoryIds,
      rating: _asDouble(map['ratingAvg'] ?? map['rating'], fallback: 0),
      completedJobs: _asInt(
        map['completedOrders'] ?? map['completedJobs'],
        fallback: 0,
      ),
      minPrice: _asInt(map['minPrice'], fallback: 0),
      maxPrice: _asInt(map['maxPrice'], fallback: 0),
      avatarUrl: _asString(map['avatarUrl']),
      bio: _asString(map['bio']),
    );
  }
}

String _asString(dynamic value, {String fallback = ''}) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return fallback;
  return text;
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString()) ?? fallback;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  final parsed = _asInt(value, fallback: -1);
  return parsed >= 0 ? parsed : null;
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse((value ?? '').toString()) ?? fallback;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  final text = (value ?? '').toString().toLowerCase();
  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;
  return fallback;
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return <String>[];
  return value
      .map((item) => (item ?? '').toString().trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, itemValue) => MapEntry(key.toString(), itemValue));
  }
  return <String, dynamic>{};
}

String _firstNonEmpty(Iterable<String?> values, {String fallback = ''}) {
  for (final raw in values) {
    final value = (raw ?? '').trim();
    if (value.isNotEmpty) return value;
  }
  return fallback;
}
