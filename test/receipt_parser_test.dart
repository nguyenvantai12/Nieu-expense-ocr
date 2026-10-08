import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/data/models/expense_category.dart';
import 'package:vku_expense_ocr/data/ocr/receipt_parser.dart';

void main() {
  group('ReceiptParser Tests', () {
    test('1. Parses perfect receipt with all details', () {
      const rawText = '''
Highlands Coffee
ĐC: 123 Nguyễn Văn Linh
Date: 15/10/2023
Thành tiền: 150.000
Cảm ơn quý khách
      ''';

      final result = ReceiptParser.parse(rawText);
      expect(result.merchant, 'Highlands Coffee');
      expect(result.amount, 150000.0);
      expect(result.date, DateTime(2023, 10, 15));
      expect(result.suggestedCategory, ExpenseCategory.food);
      expect(result.confidence, 1.0); // 0.3 + 0.4 + 0.3
    });

    test('2. Missing keywords, uses largest number as fallback', () {
      const rawText = '''
Vinmart
12-09-2023
Bánh mì: 15000
Sữa: 35000
50000
      ''';

      final result = ReceiptParser.parse(rawText);
      expect(result.merchant, 'Vinmart');
      expect(result.amount, 50000.0);
      expect(result.date, DateTime(2023, 9, 12));
      expect(result.suggestedCategory, ExpenseCategory.shopping);
      expect(
        result.confidence,
        0.7,
      ); // 0.3 (merchant) + 0.1 (fallback amount) + 0.3 (date)
    });

    test('3. Suggests transport category for Grab', () {
      const rawText = '''
Grab
01/01/2024
Total: 45,000
      ''';

      final result = ReceiptParser.parse(rawText);
      expect(result.merchant, 'Grab');
      expect(result.amount, 45000.0);
      expect(result.suggestedCategory, ExpenseCategory.transport);
    });

    test('4. Empty text returns null/fallback values', () {
      final result = ReceiptParser.parse('');
      expect(result.merchant, isNull);
      expect(result.amount, isNull);
      expect(result.confidence, 0.0);
      expect(result.suggestedCategory, ExpenseCategory.other);
    });

    test('5. Handles US formatted currency with dots and commas', () {
      const rawText = '''
Nha hang ABC
Total: 1,500,000.00
12/12/2022
      ''';
      final result = ReceiptParser.parse(rawText);
      expect(result.amount, 1500000.0);
    });

    test('6. Skips phone numbers when finding largest number fallback', () {
      const rawText = '''
Cửa hàng tạp hóa
Hotline: 0901234567
Tổng cộng: 120.000
05-05-2023
      ''';
      final result = ReceiptParser.parse(rawText);
      expect(result.amount, 120000.0); // Should not pick 0901234567
    });

    test('7. Handles messy OCR text', () {
      const rawText = '''
*(&^#
@!#
Taxi Vinasun
15/07/2023
T.cong 65.000
      ''';
      final result = ReceiptParser.parse(rawText);
      expect(result.merchant, 'Taxi Vinasun'); // Should skip symbols
      expect(result.amount, 65000.0);
    });

    test('8. Date fallback to today if missing', () {
      const rawText = '''
Tiền điện
Total 500.000
      ''';
      final result = ReceiptParser.parse(rawText);
      expect(result.merchant, 'Tiền điện');
      expect(result.amount, 500000.0);
      // Ensure date is today (same day/month/year)
      final now = DateTime.now();
      expect(result.date?.year, now.year);
      expect(result.date?.month, now.month);
      expect(result.date?.day, now.day);
      expect(result.suggestedCategory, ExpenseCategory.utilities);
    });

    test('9. Uses VND amount instead of a bank account number', () {
      const rawText = '''
Chuyển tiền thành công
50,000 VND
11:58 - 28/01/2025
NGUYEN THI PHUONG
MB Bank (MB)
Chia sẻ
0378465748
NGUYEN VAN TAI
      ''';

      final result = ReceiptParser.parse(rawText);

      expect(result.amount, 50000.0);
      expect(result.date, DateTime(2025, 1, 28));
    });

    test('10. Does not treat a bare long account number as an amount', () {
      const rawText = '''
Chia sẻ
0378465748
      ''';

      final result = ReceiptParser.parse(rawText);

      expect(result.amount, isNull);
    });

    test('11. Uses the transfer recipient as the merchant', () {
      const rawText = '''
Chuyen tien thanh cong
1,929,000 VND
14:01 - 10/09/2026
VU NGOC THONG
Vietcombank (VCB)
0041000310470
TT0926 phong 12
Cam on ban da su dung dich vu cua MBBank
''';

      final result = ReceiptParser.parse(rawText);

      expect(result.merchant, 'VU NGOC THONG');
      expect(result.amount, 1929000);
      expect(result.date, DateTime(2026, 9, 10));
    });
  });
}
