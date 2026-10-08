import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/features/insights_provider.dart';

void main() {
  group('generateInsights', () {
    test('reports a category increase over twenty percent', () {
      final insights = generateInsights(
        {
          'food': {'current': 130000, 'previous': 100000},
        },
        0,
        0,
      );

      expect(insights.any((message) => message.contains('30%')), isTrue);
    });

    test('warns when monthly budget usage reaches ninety percent', () {
      final insights = generateInsights({}, 900000, 1000000);

      expect(insights, hasLength(1));
      expect(insights.single.contains('90%'), isTrue);
    });

    test('returns no more than three insights', () {
      final comparisons = {
        for (final category in ['food', 'transport', 'shopping', 'utilities'])
          category: {'current': 200.0, 'previous': 100.0},
      };

      expect(generateInsights(comparisons, 950, 1000), hasLength(3));
    });
  });
}
