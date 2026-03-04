import 'package:flutter_test/flutter_test.dart';
import 'package:kuryl_kz/features/categories/data/category_repository.dart';
import 'package:kuryl_kz/features/categories/models/category_worker_profile.dart';

void main() {
  group('CategoryRepository', () {
    late CategoryRepository repository;

    setUp(() {
      repository = CategoryRepository();
      repository.initFromList(_validCategoryFixture());
    });

    test('builds indices and breadcrumb from valid data', () {
      final roots = repository.getRoots();
      expect(roots.length, 1);
      expect(roots.first.id, 'root');

      final children = repository.getChildren('root');
      expect(children.length, 1);
      expect(children.first.id, 'sub');

      final breadcrumb = repository.getBreadcrumb('leaf_socket');
      expect(
        breadcrumb.map((item) => item.id),
        equals(<String>['root', 'sub', 'leaf_socket']),
      );
    });

    test('detects cycle on load', () {
      final invalid = <Map<String, dynamic>>[
        ..._validCategoryFixture(),
        <String, dynamic>{
          'id': 'cycle_a',
          'parentId': 'cycle_b',
          'level': 0,
          'isLeaf': false,
          'order': 10,
          'name': _name('A', 'A', 'A'),
          'aliases': _listMap(),
          'keywords': _listMap(),
          'pathIds': <String>['cycle_a'],
        },
        <String, dynamic>{
          'id': 'cycle_b',
          'parentId': 'cycle_a',
          'level': 1,
          'isLeaf': false,
          'order': 20,
          'name': _name('B', 'B', 'B'),
          'aliases': _listMap(),
          'keywords': _listMap(),
          'pathIds': <String>['cycle_a', 'cycle_b'],
        },
      ];

      final repo = CategoryRepository();
      expect(() => repo.initFromList(invalid), throwsStateError);
    });

    test('enforces leaf-only retrieval', () {
      expect(repository.getLeaf('root'), isNull);
      expect(repository.getLeaf('sub'), isNull);
      expect(repository.getLeaf('leaf_socket')?.id, 'leaf_socket');
    });

    test('search normalization and multilingual matching', () {
      final byEnglish = repository.searchLeaves('socket!!!', 'en');
      expect(byEnglish.first.id, 'leaf_socket');

      final byRussianAlias = repository.searchLeaves('розетка', 'ru');
      expect(byRussianAlias.first.id, 'leaf_socket');

      final byKazakhKeyword = repository.searchLeaves('құбыр', 'kk');
      expect(byKazakhKeyword.first.id, 'leaf_pipe');
    });

    test('returns leaves under node', () {
      final leavesUnderRoot = repository.getLeavesUnder('root');
      expect(
        leavesUnderRoot.map((item) => item.id).toSet(),
        equals(<String>{'leaf_socket', 'leaf_pipe'}),
      );

      final leavesUnderLeaf = repository.getLeavesUnder('leaf_socket');
      expect(
        leavesUnderLeaf.map((item) => item.id),
        equals(<String>['leaf_socket']),
      );
    });
  });

  group('CategoryWorkerProfile', () {
    test('normalizes duplicates and prevents overlaps', () {
      final normalized = CategoryWorkerProfile(
        primaryCategoryIds: const <String>[
          'leaf_socket',
          'leaf_socket',
          'leaf_pipe',
        ],
        canDoCategoryIds: const <String>[
          'leaf_pipe',
          'leaf_extra',
          'leaf_extra',
        ],
      ).normalized(primaryLimit: 3, canDoLimit: 20);

      expect(
        normalized.primaryCategoryIds.toSet(),
        equals(<String>{'leaf_socket', 'leaf_pipe'}),
      );
      expect(
        normalized.canDoCategoryIds.toSet(),
        equals(<String>{'leaf_extra'}),
      );
    });
  });
}

List<Map<String, dynamic>> _validCategoryFixture() {
  return <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'root',
      'parentId': null,
      'level': 0,
      'isLeaf': false,
      'order': 10,
      'name': _name('Түбір', 'Корень', 'Root'),
      'aliases': _listMap(),
      'keywords': _listMap(kk: <String>['құрылыс']),
      'pathIds': <String>['root'],
    },
    <String, dynamic>{
      'id': 'sub',
      'parentId': 'root',
      'level': 1,
      'isLeaf': false,
      'order': 20,
      'name': _name('Электр', 'Электро', 'Electrical'),
      'aliases': _listMap(),
      'keywords': _listMap(),
      'pathIds': <String>['root', 'sub'],
    },
    <String, dynamic>{
      'id': 'leaf_socket',
      'parentId': 'sub',
      'level': 2,
      'isLeaf': true,
      'order': 30,
      'name': _name('Розетка орнату', 'Установка розеток', 'Socket install'),
      'aliases': _listMap(ru: <String>['розетка'], en: <String>['outlet']),
      'keywords': _listMap(kk: <String>['ток'], en: <String>['socket']),
      'pathIds': <String>['root', 'sub', 'leaf_socket'],
    },
    <String, dynamic>{
      'id': 'leaf_pipe',
      'parentId': 'sub',
      'level': 2,
      'isLeaf': true,
      'order': 40,
      'name': _name('Құбыр жөндеу', 'Ремонт труб', 'Pipe repair'),
      'aliases': _listMap(kk: <String>['су құбыры']),
      'keywords': _listMap(kk: <String>['құбыр'], ru: <String>['труба']),
      'pathIds': <String>['root', 'sub', 'leaf_pipe'],
    },
  ];
}

Map<String, dynamic> _name(String kk, String ru, String en) {
  return <String, dynamic>{'kk': kk, 'ru': ru, 'en': en};
}

Map<String, dynamic> _listMap({
  List<String> kk = const <String>[],
  List<String> ru = const <String>[],
  List<String> en = const <String>[],
}) {
  return <String, dynamic>{'kk': kk, 'ru': ru, 'en': en};
}
