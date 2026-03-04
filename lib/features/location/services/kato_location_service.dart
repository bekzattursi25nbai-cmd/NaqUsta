import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kuryl_kz/features/location/models/kato_models.dart';

class KatoLocationService {
  KatoLocationService._();

  static final KatoLocationService instance = KatoLocationService._();

  static const String flatAssetPath =
      'assets/data/kato/naqusta_kato_selected_multilang_flat.json';
  static const String treeAssetPath =
      'assets/data/kato/naqusta_kato_selected_multilang_tree.json';

  static const Set<String> _districtKinds = <String>{'district', 'city_admin'};

  static const Set<String> _localityKinds = <String>{
    'rural_okrug',
    'village_admin',
    'village',
    'city',
    'settlement_other',
  };

  static const Set<String> _settlementKinds = <String>{'settlement_other'};

  KatoIndexes? _indexes;
  Future<void>? _warmUpFuture;

  bool get isReady => _indexes != null;

  Future<void> warmUp() {
    if (_indexes != null) {
      return Future<void>.value();
    }
    _warmUpFuture ??= _load();
    return _warmUpFuture!;
  }

  Future<void> _load() async {
    final results = await Future.wait<String>(<Future<String>>[
      rootBundle.loadString(flatAssetPath),
      rootBundle.loadString(treeAssetPath),
    ]);

    final rawIndexes = await compute<Map<String, String>, Map<String, Object?>>(
      _buildKatoRawIndexesInIsolate,
      <String, String>{'flatJson': results[0], 'treeJson': results[1]},
    );

    final treeRowsById = _asIntMapOfMap(rawIndexes['treeRowsById']);
    final treeChildrenByParentRaw = _asIntMapOfIntList(
      rawIndexes['treeChildrenByParent'],
    );
    final rootIds = _asIntList(rawIndexes['treeRootIds']);

    final treeById = <int, KatoTreeNode>{};
    KatoTreeNode buildTreeNode(int id) {
      final existing = treeById[id];
      if (existing != null) return existing;

      final row = treeRowsById[id];
      if (row == null) {
        throw FormatException('Missing tree node row for id=$id');
      }

      final childIds = _asIntList(row['childIds']);
      final children = childIds.map(buildTreeNode).toList(growable: false);
      final node = KatoTreeNode(
        id: _asInt(row['id']),
        parentId: _asInt(row['parentId']),
        katoCode: _asString(row['katoCode']),
        kind: _asString(row['kind']),
        name: KatoLocalizedName(
          kz: _asString(row['nameKz']),
          ru: _asString(row['nameRu']),
          en: _asString(row['nameEn']),
        ),
        slug: _asString(row['slug']),
        children: List<KatoTreeNode>.unmodifiable(children),
      );
      treeById[id] = node;
      return node;
    }

    final treeRoots = rootIds.map(buildTreeNode).toList(growable: false);
    final treeChildrenByParent = <int, List<KatoTreeNode>>{};
    for (final entry in treeChildrenByParentRaw.entries) {
      final children = entry.value.map(buildTreeNode).toList(growable: false);
      treeChildrenByParent[entry.key] = List<KatoTreeNode>.unmodifiable(
        children,
      );
    }

    final flatRows = _asListOfMap(rawIndexes['flatRows']);
    final flatItems = <KatoFlatItem>[];
    final flatById = <int, KatoFlatItem>{};

    for (final row in flatRows) {
      final item = KatoFlatItem(
        id: _asInt(row['id']),
        parentId: _asInt(row['parentId']),
        katoCode: _asString(row['katoCode']),
        kind: _asString(row['kind']),
        rootKey: _asString(row['rootKey']),
        name: KatoLocalizedName(
          kz: _asString(row['nameKz']),
          ru: _asString(row['nameRu']),
          en: _asString(row['nameEn']),
        ),
        slug: _asString(row['slug']),
      );
      flatItems.add(item);
      flatById[item.id] = item;
    }

    final flatByKato = <String, KatoFlatItem>{};
    final flatByKatoRaw = _asStringIntMap(rawIndexes['flatByKato']);
    for (final entry in flatByKatoRaw.entries) {
      final item = flatById[entry.value];
      if (item != null) {
        flatByKato[entry.key] = item;
      }
    }

    // Defensive fallback if raw index from isolate is unexpectedly empty.
    if (flatByKato.isEmpty) {
      for (final item in flatItems) {
        if (item.katoCode.isNotEmpty) {
          flatByKato[item.katoCode] = item;
        }
      }
    }

    final flatChildrenByParentRaw = _asIntMapOfIntList(
      rawIndexes['flatChildrenByParent'],
    );
    final flatChildrenByParent = <int, List<KatoFlatItem>>{};
    for (final entry in flatChildrenByParentRaw.entries) {
      final children = <KatoFlatItem>[];
      for (final childId in entry.value) {
        final item = flatById[childId];
        if (item != null) {
          children.add(item);
        }
      }
      flatChildrenByParent[entry.key] = List<KatoFlatItem>.unmodifiable(
        children,
      );
    }

    _indexes = KatoIndexes(
      roots: List<KatoTreeNode>.unmodifiable(treeRoots),
      flatItems: List<KatoFlatItem>.unmodifiable(flatItems),
      flatById: UnmodifiableMapView<int, KatoFlatItem>(flatById),
      flatByKato: UnmodifiableMapView<String, KatoFlatItem>(flatByKato),
      flatChildrenByParent: UnmodifiableMapView<int, List<KatoFlatItem>>(
        flatChildrenByParent,
      ),
      treeById: UnmodifiableMapView<int, KatoTreeNode>(treeById),
      treeChildrenByParent: UnmodifiableMapView<int, List<KatoTreeNode>>(
        treeChildrenByParent,
      ),
    );
  }

  KatoIndexes _requireIndexes() {
    final indexes = _indexes;
    if (indexes == null) {
      throw StateError('KATO data is not loaded yet. Call warmUp() first.');
    }
    return indexes;
  }

  List<KatoTreeNode> getTopLevelOptions({String locale = 'kz'}) {
    final indexes = _requireIndexes();
    return _sortTreeNodes(indexes.roots, locale: locale);
  }

  List<KatoTreeNode> getChildren(int parentId, {String locale = 'kz'}) {
    final indexes = _requireIndexes();
    final children =
        indexes.treeChildrenByParent[parentId] ?? const <KatoTreeNode>[];
    return _sortTreeNodes(children, locale: locale);
  }

  List<KatoTreeNode> getDistrictOptions(
    int topLevelId, {
    String locale = 'kz',
  }) {
    return _collectFirstMatchingNodes(
      parentId: topLevelId,
      targetKinds: _districtKinds,
      locale: locale,
    );
  }

  List<KatoTreeNode> getLocalityOptions(
    int districtId, {
    String locale = 'kz',
  }) {
    return _collectFirstMatchingNodes(
      parentId: districtId,
      targetKinds: _localityKinds,
      locale: locale,
    );
  }

  List<KatoTreeNode> getSettlementOptions(
    int localityId, {
    String locale = 'kz',
  }) {
    final result = <KatoTreeNode>[];
    final queue = Queue<KatoTreeNode>()
      ..addAll(getChildren(localityId, locale: locale));
    final visited = <int>{};

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (!visited.add(current.id)) {
        continue;
      }

      if (_settlementKinds.contains(current.kind)) {
        result.add(current);
        continue;
      }

      queue.addAll(getChildren(current.id, locale: locale));
    }

    return _sortTreeNodes(_uniqueTreeNodes(result), locale: locale);
  }

  List<KatoTreeNode> filterNodesByQuery(
    Iterable<KatoTreeNode> nodes,
    String query, {
    String locale = 'kz',
  }) {
    final normalized = query.trim().toLowerCase();
    final list = nodes.toList();
    if (normalized.isEmpty) {
      return _sortTreeNodes(list, locale: locale);
    }

    final filtered = list.where((node) {
      final text = node.title(locale).toLowerCase();
      if (text.contains(normalized)) return true;

      return node.name.kz.toLowerCase().contains(normalized) ||
          node.name.ru.toLowerCase().contains(normalized) ||
          node.name.en.toLowerCase().contains(normalized);
    }).toList();

    return _sortTreeNodes(filtered, locale: locale);
  }

  String optionLabel(
    KatoTreeNode node,
    List<KatoTreeNode> options, {
    String locale = 'kz',
  }) {
    final base = node.title(locale);
    if (base.isEmpty) return node.katoCode;

    var duplicateCount = 0;
    for (final other in options) {
      if (other.title(locale) == base) {
        duplicateCount++;
      }
    }

    if (duplicateCount <= 1) {
      return base;
    }

    final parentName = parentTitleById(node.id, locale: locale);
    if (parentName.isEmpty) {
      return '$base (${node.katoCode})';
    }

    return '$base ($parentName)';
  }

  String parentTitleById(int id, {String locale = 'kz'}) {
    final indexes = _requireIndexes();
    final current = indexes.flatById[id];
    if (current == null) return '';

    final parent = indexes.flatById[current.parentId];
    if (parent == null) return '';

    return parent.name.localized(locale);
  }

  KatoTreeNode? findTreeNodeById(int id) {
    final indexes = _requireIndexes();
    return indexes.treeById[id];
  }

  KatoFlatItem? findFlatById(int id) {
    final indexes = _requireIndexes();
    return indexes.flatById[id];
  }

  KatoFlatItem? findByKatoCode(String katoCode) {
    final indexes = _requireIndexes();
    return indexes.flatByKato[katoCode.trim()];
  }

  bool isAncestor({required int ancestorId, required int descendantId}) {
    if (ancestorId == descendantId) return true;

    final indexes = _requireIndexes();
    var cursor = indexes.flatById[descendantId];

    while (cursor != null && cursor.parentId != 0) {
      if (cursor.parentId == ancestorId) {
        return true;
      }
      cursor = indexes.flatById[cursor.parentId];
    }

    return false;
  }

  SelectedLocationResult resolveSelection({
    int? topLevelId,
    int? districtId,
    int? localityId,
    int? settlementId,
  }) {
    final indexes = _requireIndexes();

    final selectedId = settlementId ?? localityId ?? districtId ?? topLevelId;
    if (selectedId == null) {
      return const SelectedLocationResult(
        topLevel: null,
        district: null,
        locality: null,
        settlement: null,
        selected: null,
        path: <KatoFlatItem>[],
        region: null,
        districtResolved: null,
      );
    }

    final selected = indexes.flatById[selectedId];
    if (selected == null) {
      return const SelectedLocationResult(
        topLevel: null,
        district: null,
        locality: null,
        settlement: null,
        selected: null,
        path: <KatoFlatItem>[],
        region: null,
        districtResolved: null,
      );
    }

    final path = _buildPath(selected.id);
    final top = path.isNotEmpty ? path.first : null;

    KatoFlatItem? districtResolved;
    for (final item in path) {
      if (_districtKinds.contains(item.kind)) {
        districtResolved = item;
        break;
      }
    }

    districtResolved ??= top;

    KatoFlatItem? settlement;
    if (settlementId != null) {
      settlement = indexes.flatById[settlementId];
    } else {
      settlement = _firstFromEnd(
        path,
        (item) => _settlementKinds.contains(item.kind),
      );
    }

    KatoFlatItem? locality;
    if (localityId != null) {
      locality = indexes.flatById[localityId];
    } else if (settlement != null) {
      final settlementParent = indexes.flatById[settlement.parentId];
      if (settlementParent != null &&
          settlementParent.id != districtResolved?.id) {
        locality = settlementParent;
      }
    }

    locality ??= _firstFromEnd(
      path,
      (item) =>
          _localityKinds.contains(item.kind) &&
          item.id != districtResolved?.id &&
          item.id != settlement?.id,
    );

    return SelectedLocationResult(
      topLevel: top,
      district: indexes.flatById[districtId ?? -1],
      locality: locality,
      settlement: settlement,
      selected: selected,
      path: List<KatoFlatItem>.unmodifiable(path),
      region: top,
      districtResolved: districtResolved,
    );
  }

  List<KatoFlatItem> _buildPath(int id) {
    final indexes = _requireIndexes();
    final path = <KatoFlatItem>[];

    var cursor = indexes.flatById[id];
    while (cursor != null) {
      path.add(cursor);
      if (cursor.parentId == 0) {
        break;
      }
      cursor = indexes.flatById[cursor.parentId];
    }

    return path.reversed.toList(growable: false);
  }

  List<KatoTreeNode> _collectFirstMatchingNodes({
    required int parentId,
    required Set<String> targetKinds,
    required String locale,
    int maxDepth = 5,
  }) {
    final firstChildren = getChildren(parentId, locale: locale);
    if (firstChildren.isEmpty) return const <KatoTreeNode>[];

    var frontier = firstChildren;
    for (var depth = 0; depth < maxDepth; depth++) {
      if (frontier.isEmpty) {
        break;
      }

      final matched = frontier
          .where((node) => targetKinds.contains(node.kind))
          .toList(growable: false);

      if (matched.isNotEmpty) {
        return _sortTreeNodes(_uniqueTreeNodes(matched), locale: locale);
      }

      final next = <KatoTreeNode>[];
      for (final node in frontier) {
        next.addAll(getChildren(node.id, locale: locale));
      }

      frontier = _uniqueTreeNodes(next);
    }

    return _sortTreeNodes(_uniqueTreeNodes(firstChildren), locale: locale);
  }

  List<KatoTreeNode> _uniqueTreeNodes(List<KatoTreeNode> source) {
    final seen = <int>{};
    final result = <KatoTreeNode>[];

    for (final node in source) {
      if (seen.add(node.id)) {
        result.add(node);
      }
    }

    return result;
  }

  List<KatoTreeNode> _sortTreeNodes(
    List<KatoTreeNode> source, {
    required String locale,
  }) {
    final result = List<KatoTreeNode>.from(source);
    result.sort(
      (a, b) => a
          .title(locale)
          .toLowerCase()
          .compareTo(b.title(locale).toLowerCase()),
    );
    return result;
  }

  KatoFlatItem? _firstFromEnd(
    List<KatoFlatItem> list,
    bool Function(KatoFlatItem item) predicate,
  ) {
    for (var i = list.length - 1; i >= 0; i--) {
      if (predicate(list[i])) {
        return list[i];
      }
    }
    return null;
  }
}

Map<String, Object?> _buildKatoRawIndexesInIsolate(
  Map<String, String> payload,
) {
  final flatJson = payload['flatJson'] ?? '';
  final treeJson = payload['treeJson'] ?? '';

  final flatRaw = jsonDecode(flatJson);
  final treeRaw = jsonDecode(treeJson);

  if (flatRaw is! Map) {
    throw const FormatException('Invalid flat KATO JSON format.');
  }
  if (treeRaw is! Map) {
    throw const FormatException('Invalid tree KATO JSON format.');
  }

  final treeRowsById = <int, Map<String, Object?>>{};
  final treeChildrenByParent = <int, List<int>>{};
  final treeRootIds = <int>[];

  final rawRoots = treeRaw['roots'];
  if (rawRoots is Map) {
    for (final rawRoot in rawRoots.values) {
      final rootId = _flattenTreeNodeForIsolate(
        rawRoot,
        rowsById: treeRowsById,
        childrenByParent: treeChildrenByParent,
      );
      if (rootId != null) {
        treeRootIds.add(rootId);
      }
    }
  }

  final flatRows = <Map<String, Object?>>[];
  final flatChildrenByParent = <int, List<int>>{};
  final flatByKato = <String, int>{};

  final rawItems = flatRaw['items'];
  if (rawItems is List) {
    for (final raw in rawItems) {
      final row = _normalizeFlatRowForIsolate(raw);
      if (row == null) continue;

      final id = _asInt(row['id']);
      final parentId = _asInt(row['parentId']);
      final katoCode = _asString(row['katoCode']);

      flatRows.add(row);
      flatChildrenByParent.putIfAbsent(parentId, () => <int>[]).add(id);
      if (katoCode.isNotEmpty) {
        flatByKato[katoCode] = id;
      }
    }
  }

  return <String, Object?>{
    'treeRowsById': treeRowsById,
    'treeChildrenByParent': treeChildrenByParent,
    'treeRootIds': treeRootIds,
    'flatRows': flatRows,
    'flatChildrenByParent': flatChildrenByParent,
    'flatByKato': flatByKato,
  };
}

int? _flattenTreeNodeForIsolate(
  dynamic rawNode, {
  required Map<int, Map<String, Object?>> rowsById,
  required Map<int, List<int>> childrenByParent,
}) {
  if (rawNode is! Map) return null;

  final id = _asInt(rawNode['id']);
  if (id == 0) return null;

  final parentId = _asInt(rawNode['parentId']);
  final rawName = rawNode['name'];
  final nameMap = rawName is Map ? rawName : const <Object?, Object?>{};

  final childIds = <int>[];
  final rawChildren = rawNode['children'];
  if (rawChildren is List) {
    for (final childRaw in rawChildren) {
      final childId = _flattenTreeNodeForIsolate(
        childRaw,
        rowsById: rowsById,
        childrenByParent: childrenByParent,
      );
      if (childId != null) {
        childIds.add(childId);
      }
    }
  }

  rowsById[id] = <String, Object?>{
    'id': id,
    'parentId': parentId,
    'katoCode': _asString(rawNode['katoCode']),
    'kind': _asString(rawNode['kind']),
    'slug': _asString(rawNode['slug']),
    'nameKz': _asString(nameMap['kz']),
    'nameRu': _asString(nameMap['ru']),
    'nameEn': _asString(nameMap['en']),
    'childIds': childIds,
  };

  childrenByParent.putIfAbsent(parentId, () => <int>[]).add(id);

  return id;
}

Map<String, Object?>? _normalizeFlatRowForIsolate(dynamic raw) {
  if (raw is! Map) return null;
  final id = _asInt(raw['id']);
  if (id == 0) return null;

  final rawName = raw['name'];
  final nameMap = rawName is Map ? rawName : const <Object?, Object?>{};

  return <String, Object?>{
    'id': id,
    'parentId': _asInt(raw['parentId']),
    'katoCode': _asString(raw['katoCode']),
    'kind': _asString(raw['kind']),
    'rootKey': _asString(raw['rootKey']),
    'slug': _asString(raw['slug']),
    'nameKz': _asString(nameMap['kz']),
    'nameRu': _asString(nameMap['ru']),
    'nameEn': _asString(nameMap['en']),
  };
}

List<int> _asIntList(dynamic raw) {
  if (raw is! List) return const <int>[];
  final result = <int>[];
  for (final item in raw) {
    result.add(_asInt(item));
  }
  return result;
}

List<Map<String, Object?>> _asListOfMap(dynamic raw) {
  if (raw is! List) return const <Map<String, Object?>>[];
  final result = <Map<String, Object?>>[];
  for (final item in raw) {
    if (item is Map<String, Object?>) {
      result.add(item);
    } else if (item is Map) {
      result.add(item.map((key, value) => MapEntry(key.toString(), value)));
    }
  }
  return result;
}

Map<int, Map<String, Object?>> _asIntMapOfMap(dynamic raw) {
  if (raw is! Map) return const <int, Map<String, Object?>>{};
  final result = <int, Map<String, Object?>>{};
  for (final entry in raw.entries) {
    final key = _asInt(entry.key);
    if (entry.value is Map<String, Object?>) {
      result[key] = entry.value as Map<String, Object?>;
    } else if (entry.value is Map) {
      result[key] = (entry.value as Map).map(
        (k, v) => MapEntry(k.toString(), v),
      );
    }
  }
  return result;
}

Map<int, List<int>> _asIntMapOfIntList(dynamic raw) {
  if (raw is! Map) return const <int, List<int>>{};
  final result = <int, List<int>>{};
  for (final entry in raw.entries) {
    result[_asInt(entry.key)] = _asIntList(entry.value);
  }
  return result;
}

Map<String, int> _asStringIntMap(dynamic raw) {
  if (raw is! Map) return const <String, int>{};
  final result = <String, int>{};
  for (final entry in raw.entries) {
    final key = entry.key.toString().trim();
    if (key.isEmpty) continue;
    result[key] = _asInt(entry.value);
  }
  return result;
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
