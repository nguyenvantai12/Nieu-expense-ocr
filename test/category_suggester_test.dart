import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/data/models/expense_category.dart';
import 'package:vku_expense_ocr/data/ocr/category_suggester.dart';

void main() {
  group('CategorySuggester', () {
    test('recognizes a cafe as food', () {
      expect(
        CategorySuggester.suggestCategory('Blue Cafe'),
        ExpenseCategory.food,
      );
    });

    test('recognizes ride services as transport', () {
      expect(
        CategorySuggester.suggestCategory('Grab'),
        ExpenseCategory.transport,
      );
    });

    test('recognizes supermarkets as shopping', () {
      expect(
        CategorySuggester.suggestCategory('WinMart'),
        ExpenseCategory.shopping,
      );
    });

    test('recognizes telecom providers as utilities', () {
      expect(
        CategorySuggester.suggestCategory('Viettel'),
        ExpenseCategory.utilities,
      );
    });

    test('uses other when no keyword matches', () {
      expect(
        CategorySuggester.suggestCategory('ABC XYZ'),
        ExpenseCategory.other,
      );
    });
  });
}
