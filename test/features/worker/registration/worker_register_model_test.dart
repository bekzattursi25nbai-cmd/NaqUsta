import 'package:flutter_test/flutter_test.dart';
import 'package:kuryl_kz/features/worker/registration/models/worker_register_model.dart';

void main() {
  group('WorkerRegisterModel category payload', () {
    test('deduplicates and enforces primary/canDo limits with no overlaps', () {
      final model = WorkerRegisterModel(
        fullName: 'Worker',
        primaryCategoryIds: const <String>[
          'a',
          'a',
          'b',
          'c',
          'd',
        ],
        canDoCategoryIds: List<String>.generate(30, (index) => 'id_$index')
          ..add('a')
          ..add('b'),
        primaryCategoryLabels: const <String>[
          'A',
          'A',
          'B',
          'C',
          'D',
        ],
        canDoCategoryLabels: List<String>.generate(30, (index) => 'ID $index'),
      );

      final payload = model.toFirestorePayload(
        phone: '+77000000000',
        avatarUrl: '',
      );

      final primaryIds = (payload['primaryCategoryIds'] as List).cast<String>();
      final canDoIds = (payload['canDoCategoryIds'] as List).cast<String>();

      expect(primaryIds.length, 3);
      expect(canDoIds.length, 20);
      expect(primaryIds.contains('a'), isTrue);
      expect(canDoIds.contains('a'), isFalse);
      expect(canDoIds.contains('b'), isFalse);
    });
  });
}
