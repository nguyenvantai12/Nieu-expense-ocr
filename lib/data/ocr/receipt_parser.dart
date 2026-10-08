import '../models/expense_item.dart';
import '../models/expense_category.dart';
import 'category_suggester.dart';

/// Pure function to parse raw OCR text into structured receipt data using heuristics.
class ReceiptParser {
  /// Parses raw OCR text and extracts Merchant, Amount, Date, and Category.
  static ParsedReceipt parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return (
        merchant: null,
        amount: null,
        date: DateTime.now(),
        suggestedCategory: ExpenseCategory.other,
        confidence: 0.0,
      );
    }

    final lines = rawText
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      return (
        merchant: null,
        amount: null,
        date: DateTime.now(),
        suggestedCategory: ExpenseCategory.other,
        confidence: 0.0,
      );
    }

    double confidence = 0.0;

    // 1. Parse Merchant
    String? merchant =
        _extractTransferRecipient(lines, rawText) ?? _extractMerchant(lines);
    if (merchant != null) confidence += 0.3;

    // 2. Parse Date
    DateTime? date = _extractDate(rawText);
    if (date != null) {
      confidence += 0.3;
    } else {
      date = DateTime.now(); // Fallback
    }

    // 3. Parse Amount
    final amountResult = _extractAmount(lines);
    double? amount = amountResult.amount;
    if (amountResult.foundViaKeyword) {
      confidence += 0.4;
    } else if (amount != null) {
      // Partial confidence if we just fell back to the largest number
      confidence += 0.1;
    }

    // 4. Suggest Category
    ExpenseCategory suggestedCategory = ExpenseCategory.other;
    if (merchant != null) {
      suggestedCategory = CategorySuggester.suggestCategory(merchant);
    }

    // Cap confidence at 1.0
    if (confidence > 1.0) confidence = 1.0;

    return (
      merchant: merchant,
      amount: amount,
      date: date,
      suggestedCategory: suggestedCategory,
      confidence: confidence,
    );
  }

  /// 1. MERCHANT: First non-empty line without special characters/numbers.
  /// Fallback to second line if first is < 3 chars.
  static String? _extractMerchant(List<String> lines) {
    final validMerchantRegex = RegExp(r'^[\p{L}\s&,\.\-]+$', unicode: true);
    for (int i = 0; i < lines.length && i < 3; i++) {
      // Only check first 3 lines
      final line = lines[i];
      // Strip common prefixes just in case
      final cleanLine = line
          .replaceAll(
            RegExp(r'^(đ/c|đc|chi nhánh|cn):?', caseSensitive: false),
            '',
          )
          .trim();

      if (cleanLine.length >= 3 && validMerchantRegex.hasMatch(cleanLine)) {
        return cleanLine;
      }
    }
    // Fallback: just return the first line if it has enough characters and looks somewhat like a name
    if (lines.isNotEmpty && lines[0].length >= 3) {
      return lines[0];
    }
    return null;
  }

  /// Transfer confirmations usually place the recipient name after the
  /// amount/date and before the bank and account details.
  static String? _extractTransferRecipient(List<String> lines, String text) {
    final isTransferReceipt = RegExp(
      r'chuy.n\s+ti.n\s+th.nh\s+c.ng|successful transfer|transfer successful',
      caseSensitive: false,
    ).hasMatch(text);
    if (!isTransferReceipt) return null;

    final dateOrTimeIndex = lines.indexWhere(
      (line) =>
          RegExp(r'\b\d{1,2}[-/]\d{1,2}[-/]\d{2,4}\b').hasMatch(line) ||
          RegExp(r'\b\d{1,2}:\d{2}\b').hasMatch(line),
    );
    final transferTitleIndex = lines.indexWhere(
      (line) => RegExp(
        r'chuy.n\s+ti.n\s+th.nh\s+c.ng|successful transfer|transfer successful',
        caseSensitive: false,
      ).hasMatch(line),
    );
    final anchorIndex = dateOrTimeIndex >= 0
        ? dateOrTimeIndex
        : transferTitleIndex;

    for (
      var index = anchorIndex + 1;
      index < lines.length && index <= anchorIndex + 8;
      index++
    ) {
      final candidate = _cleanRecipientLabel(lines[index]);
      if (_isLikelyRecipientName(candidate)) return candidate;
    }
    return null;
  }

  static String _cleanRecipientLabel(String line) {
    return line
        .replaceFirst(
          RegExp(
            r'^(nguoi nhan|beneficiary|recipient)\s*[:：-]?\s*',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  static bool _isLikelyRecipientName(String line) {
    if (line.isEmpty || RegExp(r'\d').hasMatch(line)) return false;
    if (!RegExp(
      r'^[\p{L}]+(?:[ .\-][\p{L}]+)*$',
      unicode: true,
    ).hasMatch(line)) {
      return false;
    }

    final words = line.trim().split(RegExp(r'\s+'));
    if (words.length < 2 || words.length > 5) return false;

    final normalized = _normalizeAmountContext(line).replaceAll(' ', '');
    const excludedNames = [
      'chuyentien',
      'thanhcong',
      'camon',
      'dichvu',
      'sudung',
      'taikhoan',
      'nguoinhan',
      'chiase',
      'luuanh',
      'luumau',
      'vietcombank',
      'techcombank',
      'vietinbank',
      'sacombank',
      'agribank',
      'bidv',
      'vpbank',
      'tpbank',
      'mbbank',
      'acb',
    ];
    return !excludedNames.any(normalized.contains);
  }

  /// 2. DATE: Regex for multiple formats (dd/mm/yyyy, dd-mm-yyyy, etc.)
  static DateTime? _extractDate(String text) {
    final dateRegex = RegExp(r'\b(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})\b');
    final match = dateRegex.firstMatch(text);
    if (match != null) {
      try {
        int day = int.parse(match.group(1)!);
        int month = int.parse(match.group(2)!);
        int year = int.parse(match.group(3)!);
        if (year < 100) year += 2000;
        return DateTime(year, month, day);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// 3. AMOUNT: Prefer labeled/currency values, then use a filtered fallback.
  static ({double? amount, bool foundViaKeyword}) _extractAmount(
    List<String> lines,
  ) {
    const amountKeywords = [
      'tong cong',
      'total',
      't.cong',
      'thanh toan',
      'thanh tien',
      'so tien',
      'amount',
      'paid',
    ];
    final amountRegex = RegExp(r'\d+(?:[.,]\d+)*');
    final currencyRegex = RegExp(
      r'(?:\bvnd\b|vnđ|₫|đồng|đ)(?:\s|$)',
      caseSensitive: false,
    );
    final excludedLineRegex = RegExp(
      r'\b(tai khoan|stk|so tk|account|acct|phone|hotline|mobile|sdt|dien thoai|'
      r'ma giao dich|ma gd|transaction|reference|trace|invoice|bill no|order id)\b',
    );

    final candidateLines = lines
        .where((line) {
          final normalized = _normalizeAmountContext(line);
          return !excludedLineRegex.hasMatch(normalized);
        })
        .map((line) {
          return line
              .replaceAll(RegExp(r'\b\d{1,2}[-/]\d{1,2}[-/]\d{2,4}\b'), ' ')
              .replaceAll(RegExp(r'\b\d{1,2}:\d{2}\b'), ' ');
        })
        .where((line) => line.trim().isNotEmpty)
        .toList();

    // Explicit total/payment labels are the strongest signal.
    for (final line in candidateLines) {
      final normalized = _normalizeAmountContext(line);
      if (amountKeywords.any(normalized.contains)) {
        final amount = _largestValidAmount(
          amountRegex,
          line,
          allowLongNumber: true,
        );
        if (amount != null) return (amount: amount, foundViaKeyword: true);
      }
    }

    // Bank transfer slips often show only "50,000 VND" without a total label.
    for (final line in candidateLines) {
      if (currencyRegex.hasMatch(line)) {
        final amount = _largestValidAmount(
          amountRegex,
          line,
          allowLongNumber: true,
        );
        if (amount != null) return (amount: amount, foundViaKeyword: true);
      }
    }

    // Fallback is limited to plausible amount lines; long unformatted identifiers
    // such as bank account and phone numbers are not money values.
    double? maxAmount;
    for (final line in candidateLines) {
      final amount = _largestValidAmount(amountRegex, line);
      if (amount != null && (maxAmount == null || amount > maxAmount)) {
        maxAmount = amount;
      }
    }

    return (amount: maxAmount, foundViaKeyword: false);
  }

  static double? _largestValidAmount(
    RegExp amountRegex,
    String line, {
    bool allowLongNumber = false,
  }) {
    double? largest;
    for (final match in amountRegex.allMatches(line)) {
      final rawAmount = match.group(0)!;
      final digits = rawAmount.replaceAll(RegExp(r'\D'), '');
      final isUngroupedIdentifier =
          !rawAmount.contains(RegExp(r'[.,]')) && digits.length >= 8;
      if (isUngroupedIdentifier && !allowLongNumber) continue;

      final amount = _parseCurrency(rawAmount);
      if (amount != null &&
          amount > 0 &&
          amount < 10000000000 &&
          (largest == null || amount > largest)) {
        largest = amount;
      }
    }
    return largest;
  }

  static String _normalizeAmountContext(String line) {
    return line
        .toLowerCase()
        .replaceAll(RegExp('[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp('[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp('[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp('[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp('[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp('[ỳýỵỷỹ]'), 'y')
        .replaceAll('đ', 'd');
  }

  /// Helper to convert string like 1.000.000,00 or 1,000,000 to double
  static double? _parseCurrency(String amountStr) {
    try {
      // Remove all dots and commas except the last one (if it's a decimal)
      String cleanStr = amountStr.replaceAll(RegExp(r'[^\d.,]'), '');

      // Determine if the string uses comma or dot as decimal separator
      int lastDot = cleanStr.lastIndexOf('.');
      int lastComma = cleanStr.lastIndexOf(',');

      if (lastComma > lastDot && lastComma == cleanStr.length - 3) {
        // European format: 1.000,00 -> 1000.00
        cleanStr = cleanStr.replaceAll('.', '').replaceFirst(',', '.');
      } else if (lastDot > lastComma && lastDot == cleanStr.length - 3) {
        // US format: 1,000.00 -> 1000.00
        cleanStr = cleanStr.replaceAll(',', '');
      } else {
        // No decimals or unrecognized: 1000000, 1.000.000, 1,000,000
        cleanStr = cleanStr.replaceAll('.', '').replaceAll(',', '');
      }

      return double.parse(cleanStr);
    } catch (e) {
      return null;
    }
  }
}
