class WorkerPublicProfile {
  const WorkerPublicProfile({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.ratingAvg,
    required this.ratingCount,
    required this.location,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final double ratingAvg;
  final int ratingCount;
  final String location;

  factory WorkerPublicProfile.fromMap(Map<String, dynamic> map, String id) {
    final locationMap = _asMap(map['location']);
    final legacyLocation = map['location'] is String
        ? _asString(map['location'])
        : '';

    return WorkerPublicProfile(
      id: id,
      name: _asString(
        map['fullName'] ?? map['name'] ?? map['firstName'],
        fallback: 'Шебер',
      ),
      avatarUrl: _asString(map['avatarUrl']),
      ratingAvg: _asDouble(map['ratingAvg'] ?? map['rating']),
      ratingCount: _asInt(map['ratingCount'] ?? map['reviewCount']),
      location: _firstNonEmpty(<String?>[
        _asString(map['locationShort']),
        _asString(map['locationLabel']),
        _asString(locationMap['shortLabel']),
        legacyLocation,
        [
          map['city'],
          map['district'],
          map['village'],
        ].where((item) => (item ?? '').toString().trim().isNotEmpty).join(', '),
      ], fallback: ''),
    );
  }
}

class ClientPublicProfile {
  const ClientPublicProfile({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });

  final String id;
  final String name;
  final String avatarUrl;

  factory ClientPublicProfile.fromMap(Map<String, dynamic> map, String id) {
    return ClientPublicProfile(
      id: id,
      name: _asString(
        map['displayName'] ??
            map['fullName'] ??
            map['name'] ??
            map['firstName'],
        fallback: 'Клиент',
      ),
      avatarUrl: _asString(map['avatarUrl']),
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

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse((value ?? '').toString()) ?? fallback;
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
