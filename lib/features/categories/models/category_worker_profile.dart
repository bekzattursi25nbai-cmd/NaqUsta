class CategoryWorkerProfile {
  const CategoryWorkerProfile({
    required this.primaryCategoryIds,
    required this.canDoCategoryIds,
  });

  final List<String> primaryCategoryIds;
  final List<String> canDoCategoryIds;

  factory CategoryWorkerProfile.fromMap(Map<String, dynamic> map) {
    final primary = _asStringList(map['primaryCategoryIds']);
    final canDo = _asStringList(
      map['canDoCategoryIds'],
    ).where((id) => !primary.contains(id)).toList();
    return CategoryWorkerProfile(
      primaryCategoryIds: primary,
      canDoCategoryIds: canDo,
    );
  }

  CategoryWorkerProfile normalized({
    int primaryLimit = 3,
    int canDoLimit = 20,
  }) {
    final primary = _dedupe(primaryCategoryIds).take(primaryLimit).toList();
    final canDo = _dedupe(
      canDoCategoryIds,
    ).where((id) => !primary.contains(id)).take(canDoLimit).toList();
    return CategoryWorkerProfile(
      primaryCategoryIds: primary,
      canDoCategoryIds: canDo,
    );
  }

  static List<String> _asStringList(dynamic value) {
    if (value is! List) return const <String>[];
    return _dedupe(
      value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(),
    );
  }

  static List<String> _dedupe(List<String> values) {
    return values.toSet().toList(growable: false);
  }
}
