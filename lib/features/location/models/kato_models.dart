import 'dart:collection';

/// Supported worker order-visibility radius.
enum WorkerCoverageMode { exact, district, region }

extension WorkerCoverageModeX on WorkerCoverageMode {
  String get wire {
    switch (this) {
      case WorkerCoverageMode.exact:
        return 'exact';
      case WorkerCoverageMode.district:
        return 'district';
      case WorkerCoverageMode.region:
        return 'region';
    }
  }

  static WorkerCoverageMode fromWire(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'district':
        return WorkerCoverageMode.district;
      case 'region':
        return WorkerCoverageMode.region;
      case 'exact':
      default:
        return WorkerCoverageMode.exact;
    }
  }

  String get kzLabel {
    switch (this) {
      case WorkerCoverageMode.exact:
        return 'Тек дәл елді мекен';
      case WorkerCoverageMode.district:
        return 'Бүкіл аудан';
      case WorkerCoverageMode.region:
        return 'Бүкіл өңір/қала';
    }
  }
}

class KatoLocalizedName {
  const KatoLocalizedName({
    required this.kz,
    required this.ru,
    required this.en,
  });

  final String kz;
  final String ru;
  final String en;

  String localized(String locale) {
    switch (locale.trim().toLowerCase()) {
      case 'ru':
        return ru.isNotEmpty ? ru : kz;
      case 'en':
        return en.isNotEmpty ? en : kz;
      case 'kz':
      default:
        return kz;
    }
  }

  factory KatoLocalizedName.fromJson(dynamic raw) {
    final map = raw is Map<String, dynamic>
        ? raw
        : (raw is Map
              ? raw.cast<String, dynamic>()
              : const <String, dynamic>{});

    return KatoLocalizedName(
      kz: _asString(map['kz']),
      ru: _asString(map['ru']),
      en: _asString(map['en']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'kz': kz, 'ru': ru, 'en': en};
  }
}

class KatoFlatItem {
  const KatoFlatItem({
    required this.id,
    required this.parentId,
    required this.katoCode,
    required this.kind,
    required this.rootKey,
    required this.name,
    required this.slug,
  });

  final int id;
  final int parentId;
  final String katoCode;
  final String kind;
  final String rootKey;
  final KatoLocalizedName name;
  final String slug;

  factory KatoFlatItem.fromJson(Map<String, dynamic> map) {
    return KatoFlatItem(
      id: _asInt(map['id']),
      parentId: _asInt(map['parentId']),
      katoCode: _asString(map['katoCode']),
      kind: _asString(map['kind']),
      rootKey: _asString(map['rootKey']),
      name: KatoLocalizedName.fromJson(map['name']),
      slug: _asString(map['slug']),
    );
  }
}

class KatoTreeNode {
  const KatoTreeNode({
    required this.id,
    required this.parentId,
    required this.katoCode,
    required this.kind,
    required this.name,
    required this.slug,
    required this.children,
  });

  final int id;
  final int parentId;
  final String katoCode;
  final String kind;
  final KatoLocalizedName name;
  final String slug;
  final List<KatoTreeNode> children;

  String title(String locale) => name.localized(locale);

  factory KatoTreeNode.fromJson(Map<String, dynamic> map) {
    final rawChildren = map['children'];
    final parsedChildren = <KatoTreeNode>[];

    if (rawChildren is List) {
      for (final child in rawChildren) {
        if (child is Map<String, dynamic>) {
          parsedChildren.add(KatoTreeNode.fromJson(child));
        } else if (child is Map) {
          parsedChildren.add(
            KatoTreeNode.fromJson(child.cast<String, dynamic>()),
          );
        }
      }
    }

    return KatoTreeNode(
      id: _asInt(map['id']),
      parentId: _asInt(map['parentId']),
      katoCode: _asString(map['katoCode']),
      kind: _asString(map['kind']),
      name: KatoLocalizedName.fromJson(map['name']),
      slug: _asString(map['slug']),
      children: List<KatoTreeNode>.unmodifiable(parsedChildren),
    );
  }
}

class LocationBreakdown {
  const LocationBreakdown({
    required this.id,
    required this.katoCode,
    required this.kind,
    required this.name,
    required this.regionKatoCode,
    required this.districtKatoCode,
    required this.shortLabel,
    required this.fullLabel,
    required this.regionLabel,
    required this.districtLabel,
    required this.pathIds,
    required this.pathKatoCodes,
    this.localityKatoCode,
    this.settlementKatoCode,
    this.localityLabel,
    this.settlementLabel,
  });

  final int id;
  final String katoCode;
  final String kind;
  final KatoLocalizedName name;

  final String regionKatoCode;
  final String districtKatoCode;
  final String? localityKatoCode;
  final String? settlementKatoCode;

  final String shortLabel;
  final String fullLabel;
  final String regionLabel;
  final String districtLabel;
  final String? localityLabel;
  final String? settlementLabel;

  final List<int> pathIds;
  final List<String> pathKatoCodes;

  factory LocationBreakdown.fromFirestore(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return _fromMap(raw);
    }
    if (raw is Map) {
      return _fromMap(raw.cast<String, dynamic>());
    }
    return const LocationBreakdown(
      id: 0,
      katoCode: '',
      kind: '',
      name: KatoLocalizedName(kz: '', ru: '', en: ''),
      regionKatoCode: '',
      districtKatoCode: '',
      shortLabel: '',
      fullLabel: '',
      regionLabel: '',
      districtLabel: '',
      pathIds: <int>[],
      pathKatoCodes: <String>[],
    );
  }

  static LocationBreakdown? fromDocumentData(Map<String, dynamic> data) {
    final location = data['location'];
    if (location is Map<String, dynamic>) {
      final parsed = _fromMap(location);
      if (parsed.katoCode.isNotEmpty) return parsed;
    } else if (location is Map) {
      final parsed = _fromMap(location.cast<String, dynamic>());
      if (parsed.katoCode.isNotEmpty) return parsed;
    }

    final parsed = _fromMap(data);
    if (parsed.katoCode.isEmpty) {
      return null;
    }
    return parsed;
  }

  static LocationBreakdown _fromMap(Map<String, dynamic> map) {
    final rawName = map['name'];
    final pathIdsRaw = map['pathIds'];
    final pathCodesRaw = map['pathKatoCodes'];

    final pathIds = <int>[];
    if (pathIdsRaw is List) {
      for (final item in pathIdsRaw) {
        pathIds.add(_asInt(item));
      }
    }

    final pathCodes = <String>[];
    if (pathCodesRaw is List) {
      for (final item in pathCodesRaw) {
        final value = _asString(item);
        if (value.isNotEmpty) {
          pathCodes.add(value);
        }
      }
    }

    return LocationBreakdown(
      id: _asInt(map['id']),
      katoCode: _asString(map['katoCode']),
      kind: _asString(map['kind']),
      name: KatoLocalizedName.fromJson(rawName),
      regionKatoCode: _asString(map['regionKatoCode']),
      districtKatoCode: _asString(map['districtKatoCode']),
      localityKatoCode: _asNullableString(map['localityKatoCode']),
      settlementKatoCode: _asNullableString(map['settlementKatoCode']),
      shortLabel: _asString(
        map['shortLabel'] ?? map['locationShort'] ?? map['locationLabel'],
      ),
      fullLabel: _asString(
        map['fullLabel'] ?? map['locationFullLabel'] ?? map['location'],
      ),
      regionLabel: _asString(map['regionLabel']),
      districtLabel: _asString(map['districtLabel']),
      localityLabel: _asNullableString(map['localityLabel']),
      settlementLabel: _asNullableString(map['settlementLabel']),
      pathIds: List<int>.unmodifiable(pathIds),
      pathKatoCodes: List<String>.unmodifiable(pathCodes),
    );
  }

  bool get isValid => katoCode.trim().isNotEmpty;

  Map<String, dynamic> toFirestoreMap({WorkerCoverageMode? coverageMode}) {
    return <String, dynamic>{
      'id': id,
      'katoCode': katoCode,
      'kind': kind,
      'name': name.toMap(),
      'regionKatoCode': regionKatoCode,
      'districtKatoCode': districtKatoCode,
      'localityKatoCode': localityKatoCode,
      'settlementKatoCode': settlementKatoCode,
      'shortLabel': shortLabel,
      'fullLabel': fullLabel,
      'regionLabel': regionLabel,
      'districtLabel': districtLabel,
      'localityLabel': localityLabel,
      'settlementLabel': settlementLabel,
      'pathIds': pathIds,
      'pathKatoCodes': pathKatoCodes,
      if (coverageMode != null) 'coverageMode': coverageMode.wire,
    };
  }

  Map<String, dynamic> toDenormalizedFields({
    WorkerCoverageMode? coverageMode,
  }) {
    return <String, dynamic>{
      'katoCode': katoCode,
      'regionKatoCode': regionKatoCode,
      'districtKatoCode': districtKatoCode,
      'localityKatoCode': localityKatoCode,
      'settlementKatoCode': settlementKatoCode,
      'locationShort': shortLabel,
      'locationLabel': shortLabel,
      'locationFullLabel': fullLabel,
      'locationNameKz': name.kz,
      'locationNameRu': name.ru,
      'locationNameEn': name.en,
      'regionNameKz': regionLabel,
      'districtNameKz': districtLabel,
      'localityNameKz': localityLabel,
      'settlementNameKz': settlementLabel,
      if (coverageMode != null) 'coverageMode': coverageMode.wire,
    };
  }
}

class SelectedLocationResult {
  const SelectedLocationResult({
    required this.topLevel,
    required this.district,
    required this.locality,
    required this.settlement,
    required this.selected,
    required this.path,
    required this.region,
    required this.districtResolved,
  });

  final KatoFlatItem? topLevel;
  final KatoFlatItem? district;
  final KatoFlatItem? locality;
  final KatoFlatItem? settlement;
  final KatoFlatItem? selected;
  final List<KatoFlatItem> path;
  final KatoFlatItem? region;
  final KatoFlatItem? districtResolved;

  bool get isValid => selected != null;

  LocationBreakdown? toBreakdown() {
    final selectedNode = selected;
    final regionNode = region;
    final districtNode = districtResolved;

    if (selectedNode == null || regionNode == null || districtNode == null) {
      return null;
    }

    final pathIds = <int>[];
    final pathKatoCodes = <String>[];

    for (final item in path) {
      pathIds.add(item.id);
      pathKatoCodes.add(item.katoCode);
    }

    final fullParts = path
        .map((item) => item.name.kz.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    return LocationBreakdown(
      id: selectedNode.id,
      katoCode: selectedNode.katoCode,
      kind: selectedNode.kind,
      name: selectedNode.name,
      regionKatoCode: regionNode.katoCode,
      districtKatoCode: districtNode.katoCode,
      localityKatoCode: locality?.katoCode,
      settlementKatoCode: settlement?.katoCode,
      shortLabel: selectedNode.name.kz,
      fullLabel: fullParts.join(' / '),
      regionLabel: regionNode.name.kz,
      districtLabel: districtNode.name.kz,
      localityLabel: locality?.name.kz,
      settlementLabel: settlement?.name.kz,
      pathIds: List<int>.unmodifiable(pathIds),
      pathKatoCodes: List<String>.unmodifiable(pathKatoCodes),
    );
  }
}

class KatoIndexes {
  const KatoIndexes({
    required this.roots,
    required this.flatItems,
    required this.flatById,
    required this.flatByKato,
    required this.flatChildrenByParent,
    required this.treeById,
    required this.treeChildrenByParent,
  });

  final List<KatoTreeNode> roots;
  final List<KatoFlatItem> flatItems;
  final Map<int, KatoFlatItem> flatById;
  final Map<String, KatoFlatItem> flatByKato;
  final Map<int, List<KatoFlatItem>> flatChildrenByParent;
  final Map<int, KatoTreeNode> treeById;
  final Map<int, List<KatoTreeNode>> treeChildrenByParent;

  UnmodifiableListView<KatoTreeNode> get immutableRoots =>
      UnmodifiableListView<KatoTreeNode>(roots);
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value == null) return fallback;
  return int.tryParse(value.toString()) ?? fallback;
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return fallback;
  return text;
}

String? _asNullableString(dynamic value) {
  final text = _asString(value);
  return text.isEmpty ? null : text;
}
