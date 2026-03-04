class CategoryNode {
  const CategoryNode({
    required this.id,
    required this.parentId,
    required this.level,
    required this.isLeaf,
    required this.order,
    required this.name,
    required this.aliases,
    required this.keywords,
    required this.pathIds,
  });

  final String id;
  final String? parentId;
  final int level;
  final bool isLeaf;
  final int order;
  final CategoryLocalizedText name;
  final CategoryLocalizedList aliases;
  final CategoryLocalizedList keywords;
  final List<String> pathIds;

  factory CategoryNode.fromJson(Map<String, dynamic> json) {
    final id = _readString(json['id']);
    if (id.isEmpty) {
      throw const FormatException('Category node id is required.');
    }

    final parentRaw = json['parentId'];
    final parent = parentRaw == null ? null : _readString(parentRaw);
    final parentId = parent != null && parent.isEmpty ? null : parent;

    final level = _readInt(json['level']);
    final isLeaf = json['isLeaf'] == true;
    final order = _readInt(json['order']);
    final name = CategoryLocalizedText.fromJson(json['name']);
    final aliases = CategoryLocalizedList.fromJson(json['aliases']);
    final keywords = CategoryLocalizedList.fromJson(json['keywords']);
    final pathIds = _readStringList(json['pathIds']);

    return CategoryNode(
      id: id,
      parentId: parentId,
      level: level,
      isLeaf: isLeaf,
      order: order,
      name: name,
      aliases: aliases,
      keywords: keywords,
      pathIds: pathIds,
    );
  }

  String localizedName(String localeCode) {
    return name.resolve(localeCode: localeCode);
  }

  List<String> allSearchSourceStrings() {
    return <String>[
      ...name.allValues,
      ...aliases.allValues,
      ...keywords.allValues,
    ];
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _readString(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}

class CategoryLocalizedText {
  const CategoryLocalizedText({
    required this.kk,
    required this.ru,
    required this.en,
  });

  final String kk;
  final String ru;
  final String en;

  factory CategoryLocalizedText.fromJson(dynamic value) {
    final map = _asMap(value);
    return CategoryLocalizedText(
      kk: _readString(map['kk']),
      ru: _readString(map['ru']),
      en: _readString(map['en']),
    );
  }

  List<String> get allValues => <String>[
    kk,
    ru,
    en,
  ].where((item) => item.trim().isNotEmpty).toList(growable: false);

  String resolve({required String localeCode}) {
    final normalized = localeCode.trim().toLowerCase();
    final preferred = switch (normalized) {
      'ru' => ru,
      'en' => en,
      _ => kk,
    };

    if (preferred.trim().isNotEmpty) {
      return preferred.trim();
    }
    if (kk.trim().isNotEmpty) return kk.trim();
    if (ru.trim().isNotEmpty) return ru.trim();
    if (en.trim().isNotEmpty) return en.trim();
    return '';
  }

  static String _readString(dynamic value) {
    return value?.toString().trim() ?? '';
  }
}

class CategoryLocalizedList {
  const CategoryLocalizedList({
    required this.kk,
    required this.ru,
    required this.en,
  });

  final List<String> kk;
  final List<String> ru;
  final List<String> en;

  factory CategoryLocalizedList.fromJson(dynamic value) {
    final map = _asMap(value);
    return CategoryLocalizedList(
      kk: _readStringList(map['kk']),
      ru: _readStringList(map['ru']),
      en: _readStringList(map['en']),
    );
  }

  List<String> get allValues => <String>[
    ...kk,
    ...ru,
    ...en,
  ].where((item) => item.trim().isNotEmpty).toSet().toList(growable: false);

  static List<String> _readStringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, itemValue) => MapEntry(key.toString(), itemValue));
  }
  return const <String, dynamic>{};
}
