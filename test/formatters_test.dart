import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/core/utils/formatters.dart';

void main() {
  test('formats VND with grouped thousands', () {
    expect(formatVND(1234567), '1.234.567 đ');
  });

  test('formats dates consistently for receipt entry and list', () {
    expect(formatDate(DateTime(2026, 9, 10)), '10/09/2026');
    expect(formatShortDate(DateTime(2026, 9, 10)), '10/09');
  });
}
