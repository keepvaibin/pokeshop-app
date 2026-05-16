import 'package:flutter_test/flutter_test.dart';
import 'package:pokeshop_app/core/network/json_helpers.dart';

void main() {
  group('json helpers', () {
    test('coerces common primitive values', () {
      expect(asInt('12'), 12);
      expect(asDouble('12.50'), 12.5);
      expect(asBool('true'), isTrue);
      expect(asBool('0'), isFalse);
      expect(asString(null, fallback: 'x'), 'x');
    });

    test('unwraps paginated results lists', () {
      final values = asMapList({
        'results': [
          {'id': 1},
          {'id': 2},
        ],
      });
      expect(values.length, 2);
      expect(values.first['id'], 1);
    });
  });
}
