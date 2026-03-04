import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kuryl_kz/features/categories/models/category_match.dart';
import 'package:kuryl_kz/features/categories/models/category_node.dart';
import 'package:kuryl_kz/features/categories/models/category_worker_profile.dart';

const String kCategoryAssetPath = 'assets/data/categories/categories_flat.json';

const List<String> kPopularLeafCategoryIds = <String>[
  'repair.painting',
  'repair.floor_laminate',
  'repair.tile_laying',
  'repair.ceiling_stretch',
  'plumbing.toilet_install',
  'plumbing.sink_install',
  'electric.socket_install',
  'electric.wiring_replace',
  'build.foundation_pour',
  'doors_windows.window_install',
  'roof_facade.roof_repair',
  'landscape.paving_stone',
];

class CategoryRepository {
  CategoryRepository({
    AssetBundle? assetBundle,
    this.assetPath = kCategoryAssetPath,
  }) : _assetBundle = assetBundle ?? rootBundle;

  static final CategoryRepository instance = CategoryRepository();

  final AssetBundle _assetBundle;
  final String assetPath;

  bool _isInitialized = false;
  Future<void>? _initFuture;

  Map<String, CategoryNode> _byId = <String, CategoryNode>{};
  Map<String?, List<CategoryNode>> _childrenByParent =
      <String?, List<CategoryNode>>{};
  Map<String, List<CategoryNode>> _leafByRoot = <String, List<CategoryNode>>{};

  final Map<String, Set<String>> _tokenToLeafIds = <String, Set<String>>{};
  final Map<String, Set<String>> _prefixToLeafIds = <String, Set<String>>{};
  final Map<String, String> _leafSearchBlobById = <String, String>{};

  final Map<String, List<CategoryNode>> _breadcrumbCache =
      <String, List<CategoryNode>>{};
  final Map<String, List<CategoryNode>> _leavesUnderCache =
      <String, List<CategoryNode>>{};
  final Map<String, String> _normalizedCache = <String, String>{};

  Map<String, CategoryNode> get byId => _byId;

  Map<String?, List<CategoryNode>> get childrenByParent => _childrenByParent;

  Map<String, List<CategoryNode>> get leafByRoot => _leafByRoot;

  bool get isInitialized => _isInitialized;

  Future<void> init() {
    if (_isInitialized) return Future<void>.value();
    return _initFuture ??= _initInternal();
  }

  Future<void> _initInternal() async {
    // Shared, cached category tree is loaded once from assets.
    final rawJson = await _assetBundle.loadString(assetPath);
    initFromRawJson(rawJson);
    _isInitialized = true;
  }

  @visibleForTesting
  void initFromRawJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! List) {
      throw const FormatException(
        'Category JSON root must be a list of category nodes.',
      );
    }
    initFromList(decoded);
  }

  @visibleForTesting
  void initFromList(List<dynamic> items) {
    final nodes = items
        .map((item) {
          if (item is! Map) {
            throw FormatException(
              'Category item must be a map, got ${item.runtimeType}.',
            );
          }
          return CategoryNode.fromJson(
            item.map((key, itemValue) => MapEntry(key.toString(), itemValue)),
          );
        })
        .toList(growable: false);

    _buildIndices(nodes);
    _isInitialized = true;
  }

  @visibleForTesting
  void resetForTesting() {
    _isInitialized = false;
    _initFuture = null;
    _byId = <String, CategoryNode>{};
    _childrenByParent = <String?, List<CategoryNode>>{};
    _leafByRoot = <String, List<CategoryNode>>{};
    _tokenToLeafIds.clear();
    _prefixToLeafIds.clear();
    _leafSearchBlobById.clear();
    _breadcrumbCache.clear();
    _leavesUnderCache.clear();
    _normalizedCache.clear();
  }

  List<CategoryNode> getRoots() {
    _ensureInitialized();
    return List<CategoryNode>.unmodifiable(_childrenByParent[null] ?? const []);
  }

  List<CategoryNode> getChildren(String? parentId) {
    _ensureInitialized();
    return List<CategoryNode>.unmodifiable(
      _childrenByParent[parentId] ?? const [],
    );
  }

  List<CategoryNode> getBreadcrumb(String categoryId) {
    _ensureInitialized();
    final cached = _breadcrumbCache[categoryId];
    if (cached != null) {
      return List<CategoryNode>.unmodifiable(cached);
    }

    final node = _byId[categoryId];
    if (node == null || node.pathIds.isEmpty) return const <CategoryNode>[];
    final breadcrumb = node.pathIds
        .map((id) => _byId[id])
        .whereType<CategoryNode>()
        .toList(growable: false);
    _breadcrumbCache[categoryId] = breadcrumb;
    return List<CategoryNode>.unmodifiable(breadcrumb);
  }

  CategoryNode? getLeaf(String categoryId) {
    _ensureInitialized();
    final node = _byId[categoryId];
    if (node == null || !node.isLeaf) return null;
    return node;
  }

  List<CategoryNode> getLeavesUnder(String nodeId) {
    _ensureInitialized();
    final cached = _leavesUnderCache[nodeId];
    if (cached != null) {
      return List<CategoryNode>.unmodifiable(cached);
    }

    final root = _byId[nodeId];
    if (root == null) return const <CategoryNode>[];
    if (root.isLeaf) {
      final single = <CategoryNode>[root];
      _leavesUnderCache[nodeId] = single;
      return List<CategoryNode>.unmodifiable(single);
    }

    final collected = <CategoryNode>[];
    final queue = <CategoryNode>[root];
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final children = _childrenByParent[current.id] ?? const <CategoryNode>[];
      for (final child in children) {
        if (child.isLeaf) {
          collected.add(child);
        } else {
          queue.add(child);
        }
      }
    }

    _leavesUnderCache[nodeId] = collected;
    return List<CategoryNode>.unmodifiable(collected);
  }

  List<CategoryNode> searchLeaves(
    String query,
    String localeCode, {
    int limit = 50,
  }) {
    _ensureInitialized();
    final normalized = normalizeQuery(query);
    if (normalized.isEmpty) {
      return _popularLeaves(limit: limit);
    }

    final tokens = _tokenize(normalized);
    if (tokens.isEmpty) {
      return _popularLeaves(limit: limit);
    }

    Set<String>? candidateIds;
    for (final token in tokens) {
      final ids = <String>{
        ...(_tokenToLeafIds[token] ?? const <String>{}),
        ...(_prefixToLeafIds[token] ?? const <String>{}),
      };
      if (ids.isEmpty) continue;
      candidateIds = candidateIds == null
          ? ids
          : candidateIds.intersection(ids);
    }

    final fallbackIds = candidateIds == null || candidateIds.isEmpty
        ? _leafSearchBlobById.entries
              .where((entry) {
                final text = entry.value;
                for (final token in tokens) {
                  if (!text.contains(token)) return false;
                }
                return true;
              })
              .map((entry) => entry.key)
              .toSet()
        : candidateIds;

    final scored = fallbackIds
        .map((id) => _byId[id])
        .whereType<CategoryNode>()
        .map(
          (leaf) => _ScoredLeaf(leaf: leaf, score: _searchScore(leaf, tokens)),
        )
        .toList();

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      final byOrder = a.leaf.order.compareTo(b.leaf.order);
      if (byOrder != 0) return byOrder;
      return a.leaf
          .localizedName(localeCode)
          .compareTo(b.leaf.localizedName(localeCode));
    });

    return scored.take(limit).map((item) => item.leaf).toList(growable: false);
  }

  bool isPrimaryMatch(CategoryWorkerProfile worker, String orderCategoryId) {
    _ensureInitialized();
    return getLeaf(orderCategoryId) != null &&
        worker.primaryCategoryIds.contains(orderCategoryId);
  }

  bool isCanDoMatch(CategoryWorkerProfile worker, String orderCategoryId) {
    _ensureInitialized();
    return getLeaf(orderCategoryId) != null &&
        worker.canDoCategoryIds.contains(orderCategoryId);
  }

  CategoryMatchType resolveMatchType(
    CategoryWorkerProfile worker,
    String orderCategoryId,
  ) {
    if (isPrimaryMatch(worker, orderCategoryId)) {
      return CategoryMatchType.primary;
    }
    if (isCanDoMatch(worker, orderCategoryId)) {
      return CategoryMatchType.canDo;
    }
    return CategoryMatchType.other;
  }

  Set<String> leafIdsUnderNode(String nodeId) {
    return getLeavesUnder(nodeId).map((node) => node.id).toSet();
  }

  String breadcrumbLabel(
    String categoryId,
    String localeCode, {
    String separator = ' • ',
  }) {
    final breadcrumb = getBreadcrumb(categoryId);
    if (breadcrumb.isEmpty) return '';
    return breadcrumb
        .map((node) => node.localizedName(localeCode))
        .where((item) => item.trim().isNotEmpty)
        .join(separator);
  }

  String normalizeQuery(String raw) {
    final cached = _normalizedCache[raw];
    if (cached != null) return cached;

    final lower = raw.toLowerCase().trim();
    final noPunctuation = lower.replaceAll(_punctuationPattern, ' ');
    final collapsed = noPunctuation.replaceAll(_spacesPattern, ' ').trim();
    _normalizedCache[raw] = collapsed;
    return collapsed;
  }

  void _buildIndices(List<CategoryNode> nodes) {
    final validationErrors = _validateNodes(nodes);
    if (validationErrors.isNotEmpty) {
      throw StateError(
        'Category data validation failed (${validationErrors.length} issue(s)):\n'
        '${validationErrors.map((error) => '- $error').join('\n')}',
      );
    }

    _byId = <String, CategoryNode>{for (final node in nodes) node.id: node};
    _childrenByParent = <String?, List<CategoryNode>>{};
    _leafByRoot = <String, List<CategoryNode>>{};
    _tokenToLeafIds.clear();
    _prefixToLeafIds.clear();
    _leafSearchBlobById.clear();
    _breadcrumbCache.clear();
    _leavesUnderCache.clear();
    _normalizedCache.clear();

    for (final node in nodes) {
      final list = _childrenByParent.putIfAbsent(
        node.parentId,
        () => <CategoryNode>[],
      );
      list.add(node);
    }

    for (final entry in _childrenByParent.entries) {
      entry.value.sort(_sortNodes);
    }

    final leaves = nodes.where((node) => node.isLeaf).toList(growable: false);
    for (final leaf in leaves) {
      final rootId = leaf.pathIds.first;
      final byRoot = _leafByRoot.putIfAbsent(rootId, () => <CategoryNode>[]);
      byRoot.add(leaf);
      _indexLeafForSearch(leaf);
    }

    for (final entry in _leafByRoot.entries) {
      entry.value.sort(_sortNodes);
    }
  }

  List<String> _validateNodes(List<CategoryNode> nodes) {
    final errors = <String>[];
    final seenIds = <String>{};
    final byId = <String, CategoryNode>{};

    for (final node in nodes) {
      if (!seenIds.add(node.id)) {
        errors.add('Duplicate id: "${node.id}".');
        continue;
      }
      byId[node.id] = node;
    }

    for (final node in nodes) {
      final parentId = node.parentId;
      if (parentId != null && !byId.containsKey(parentId)) {
        errors.add(
          'Node "${node.id}" references unknown parentId "$parentId".',
        );
      }

      if (node.isLeaf && node.level < 2) {
        errors.add('Leaf node "${node.id}" has invalid level ${node.level}.');
      }
      if (node.level >= 2 && !node.isLeaf) {
        errors.add(
          'Node "${node.id}" is level ${node.level} but isLeaf is false.',
        );
      }

      if (node.pathIds.isEmpty) {
        errors.add('Node "${node.id}" has empty pathIds.');
      } else if (node.pathIds.last != node.id) {
        errors.add(
          'Node "${node.id}" pathIds must end with self id. '
          'Got "${node.pathIds.last}".',
        );
      }

      final expectedPath = _expectedPath(node, byId, errors);
      if (expectedPath.isEmpty) {
        continue;
      }
      if (!listEquals(expectedPath, node.pathIds)) {
        errors.add(
          'Node "${node.id}" has inconsistent pathIds. '
          'Expected ${expectedPath.join(' > ')}, got ${node.pathIds.join(' > ')}.',
        );
      }
      if (node.level != expectedPath.length - 1) {
        errors.add(
          'Node "${node.id}" level mismatch. '
          'Expected ${expectedPath.length - 1}, got ${node.level}.',
        );
      }
    }

    return errors;
  }

  List<String> _expectedPath(
    CategoryNode node,
    Map<String, CategoryNode> byId,
    List<String> errors,
  ) {
    final path = <String>[];
    final visited = <String>{};
    CategoryNode? current = node;
    while (current != null) {
      if (!visited.add(current.id)) {
        errors.add('Cycle detected while traversing node "${node.id}".');
        return const <String>[];
      }
      path.add(current.id);
      final parentId = current.parentId;
      if (parentId == null) break;
      current = byId[parentId];
      if (current == null) {
        break;
      }
    }
    return path.reversed.toList(growable: false);
  }

  void _indexLeafForSearch(CategoryNode leaf) {
    final sources = leaf.allSearchSourceStrings();
    final tokenSet = <String>{};
    for (final source in sources) {
      final normalized = normalizeQuery(source);
      if (normalized.isEmpty) continue;
      tokenSet.addAll(_tokenize(normalized));
    }
    if (tokenSet.isEmpty) return;

    for (final token in tokenSet) {
      _tokenToLeafIds.putIfAbsent(token, () => <String>{}).add(leaf.id);
      for (final prefix in _prefixes(token)) {
        _prefixToLeafIds.putIfAbsent(prefix, () => <String>{}).add(leaf.id);
      }
    }

    _leafSearchBlobById[leaf.id] = tokenSet.toList(growable: false).join(' ');
  }

  Iterable<String> _prefixes(String token) sync* {
    if (token.length < 2) {
      yield token;
      return;
    }
    final maxLength = token.length > 24 ? 24 : token.length;
    for (var i = 2; i <= maxLength; i++) {
      yield token.substring(0, i);
    }
  }

  List<String> _tokenize(String normalized) {
    return normalized
        .split(' ')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  int _searchScore(CategoryNode leaf, List<String> tokens) {
    final name = normalizeQuery(leaf.name.kk);
    final blob = _leafSearchBlobById[leaf.id] ?? '';
    var score = 0;

    for (final token in tokens) {
      if (name == token) {
        score += 18;
      } else if (name.startsWith(token)) {
        score += 12;
      } else if (name.contains(token)) {
        score += 8;
      }

      if ((_tokenToLeafIds[token] ?? const <String>{}).contains(leaf.id)) {
        score += 6;
      }
      if (blob.contains(token)) {
        score += 4;
      }
    }

    return score;
  }

  List<CategoryNode> _popularLeaves({required int limit}) {
    final popular = <CategoryNode>[
      for (final id in kPopularLeafCategoryIds)
        if (_byId[id]?.isLeaf == true) _byId[id]!,
    ];
    if (popular.length >= limit) {
      return popular.take(limit).toList(growable: false);
    }

    final seen = popular.map((item) => item.id).toSet();
    final extras =
        _byId.values
            .where((node) => node.isLeaf && !seen.contains(node.id))
            .toList()
          ..sort(_sortNodes);

    return <CategoryNode>[...popular, ...extras.take(limit - popular.length)];
  }

  int _sortNodes(CategoryNode a, CategoryNode b) {
    final byOrder = a.order.compareTo(b.order);
    if (byOrder != 0) return byOrder;
    return a.id.compareTo(b.id);
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'CategoryRepository is not initialized. Call await init() first.',
      );
    }
  }
}

class _ScoredLeaf {
  const _ScoredLeaf({required this.leaf, required this.score});

  final CategoryNode leaf;
  final int score;
}

final RegExp _punctuationPattern = RegExp(
  r'[^0-9a-zA-Zа-яА-ЯёЁәіңғүұқөһӘІҢҒҮҰҚӨҺ\s]',
);

final RegExp _spacesPattern = RegExp(r'\s+');
