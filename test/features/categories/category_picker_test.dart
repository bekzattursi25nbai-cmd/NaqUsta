import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kuryl_kz/features/categories/data/category_repository.dart';
import 'package:kuryl_kz/features/categories/ui/category_picker.dart';

void main() {
  group('CategoryPicker', () {
    late CategoryRepository repository;

    setUp(() {
      repository = CategoryRepository();
      repository.initFromList(_fixture());
    });

    testWidgets('single select picks a leaf and closes', (tester) async {
      String? selectedLeafId;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  selectedLeafId = await CategoryPicker.pickSingleLeaf(
                    context: context,
                    title: 'Select',
                    role: CategoryPickerRole.client,
                    repository: repository,
                  );
                },
                child: const Text('Open picker'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open picker'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Түбір'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Электр'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Розетка орнату'));
      await tester.pumpAndSettle();

      expect(selectedLeafId, 'leaf_socket');
    });

    testWidgets('multi select respects limit and shows counter', (
      tester,
    ) async {
      List<String>? selectedLeafIds;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  selectedLeafIds = await CategoryPicker.pickMultiLeaf(
                    context: context,
                    title: 'Select multiple',
                    role: CategoryPickerRole.worker,
                    selectionLimit: 1,
                    repository: repository,
                  );
                },
                child: const Text('Open picker'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open picker'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Түбір'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Электр'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Розетка орнату'));
      await tester.pumpAndSettle();
      expect(find.text('1/1 таңдалды'), findsOneWidget);

      await tester.tap(find.text('Құбыр'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Лимитке жетті'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      final doneButton = find.widgetWithText(FilledButton, 'Дайын');
      await tester.ensureVisible(doneButton);
      await tester.tap(doneButton);
      await tester.pumpAndSettle();

      expect(selectedLeafIds, isNotNull);
      expect(selectedLeafIds, contains('leaf_socket'));
      expect(selectedLeafIds, isNot(contains('leaf_pipe')));
    });

    testWidgets('renders breadcrumb in browse mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  CategoryPicker.pickSingleLeaf(
                    context: context,
                    title: 'Select',
                    role: CategoryPickerRole.client,
                    repository: repository,
                  );
                },
                child: const Text('Open picker'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open picker'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Түбір'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Электр'));
      await tester.pumpAndSettle();

      expect(find.text('Түбір > Электр'), findsOneWidget);
    });
  });
}

List<Map<String, dynamic>> _fixture() {
  return <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'root',
      'parentId': null,
      'level': 0,
      'isLeaf': false,
      'order': 10,
      'name': _name('Түбір', 'Корень', 'Root'),
      'aliases': _listMap(),
      'keywords': _listMap(),
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
      'aliases': _listMap(),
      'keywords': _listMap(),
      'pathIds': <String>['root', 'sub', 'leaf_socket'],
    },
    <String, dynamic>{
      'id': 'leaf_pipe',
      'parentId': 'sub',
      'level': 2,
      'isLeaf': true,
      'order': 40,
      'name': _name('Құбыр', 'Труба', 'Pipe repair'),
      'aliases': _listMap(),
      'keywords': _listMap(),
      'pathIds': <String>['root', 'sub', 'leaf_pipe'],
    },
  ];
}

Map<String, dynamic> _name(String kk, String ru, String en) {
  return <String, dynamic>{'kk': kk, 'ru': ru, 'en': en};
}

Map<String, dynamic> _listMap() {
  return <String, dynamic>{
    'kk': const <String>[],
    'ru': const <String>[],
    'en': const <String>[],
  };
}
