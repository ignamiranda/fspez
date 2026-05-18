import 'package:flutter_test/flutter_test.dart';
import 'package:fspez/src/data/save_repository.dart';

void main() {
  group('SaveException', () {
    test('has correct fields', () {
      final e = SaveException(statusCode: 403, body: 'Forbidden');
      expect(e.statusCode, 403);
      expect(e.body, 'Forbidden');
    });
  });
}
