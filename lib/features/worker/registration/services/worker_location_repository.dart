import 'dart:convert';

import 'package:flutter/services.dart';

class WorkerLocationRepository {
  WorkerLocationRepository._();

  static final WorkerLocationRepository instance = WorkerLocationRepository._();

  // TODO(dataset): Expand this dataset with complete district/village coverage per city.
  static const String _assetPath = 'assets/locations/kz_locations.json';

  Map<String, Map<String, List<String>>>? _cache;

  Future<void> warmUp() async {
    await _ensureLoaded();
  }

  Future<List<String>> cities({String query = ''}) async {
    final data = await _ensureLoaded();
    final list = data.keys.toList()..sort();
    return _filter(list, query);
  }

  Future<List<String>> districts({
    required String city,
    String query = '',
  }) async {
    final data = await _ensureLoaded();
    final cityMap = data[city];
    if (cityMap == null) return <String>[];
    final list = cityMap.keys.toList()..sort();
    return _filter(list, query);
  }

  Future<List<String>> villages({
    required String city,
    required String district,
    String query = '',
  }) async {
    final data = await _ensureLoaded();
    final districtMap = data[city]?[district];
    if (districtMap == null) return <String>[];
    final list = List<String>.from(districtMap)..sort();
    return _filter(list, query);
  }

  Future<Map<String, Map<String, List<String>>>> _ensureLoaded() async {
    if (_cache != null) {
      return _cache!;
    }

    final rawJson = await rootBundle.loadString(_assetPath);
    final dynamic decoded = jsonDecode(rawJson);

    if (decoded is! Map<String, dynamic>) {
      _cache = <String, Map<String, List<String>>>{};
      return _cache!;
    }

    final parsed = <String, Map<String, List<String>>>{};
    for (final cityEntry in decoded.entries) {
      final districtRaw = cityEntry.value;
      if (districtRaw is! Map<String, dynamic>) {
        continue;
      }

      final districts = <String, List<String>>{};
      for (final districtEntry in districtRaw.entries) {
        final villagesRaw = districtEntry.value;
        if (villagesRaw is! List) {
          continue;
        }

        districts[districtEntry.key] = villagesRaw
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }

      parsed[cityEntry.key] = districts;
    }

    _cache = parsed;
    return _cache!;
  }

  List<String> _filter(List<String> source, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return source;

    return source.where((item) => item.toLowerCase().contains(q)).toList();
  }
}
