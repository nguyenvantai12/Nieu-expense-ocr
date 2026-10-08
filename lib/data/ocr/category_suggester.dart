import '../models/expense_category.dart';

/// Pure function to suggest a category based on the merchant's name.
/// Completely offline and rule-based (Requirement: Smart Category Suggestion).
class CategorySuggester {
  static ExpenseCategory suggestCategory(String merchantName) {
    final lowerName = merchantName.toLowerCase();

    // Food & Dining
    final foodKeywords = [
      'coffee',
      'cafe',
      'quán',
      'nhà hàng',
      'food',
      'bún',
      'phở',
      'cơm',
      'tea',
      'trà',
      'bánh',
      'restaurant',
      'ăn',
      'uống',
      'highlands',
      'phúc long',
    ];
    for (final kw in foodKeywords) {
      if (lowerName.contains(kw)) return ExpenseCategory.food;
    }

    // Transportation
    final transportKeywords = [
      'grab',
      'taxi',
      'xe',
      'xăng',
      'petrolimex',
      'be',
      'gojek',
      'parking',
      'gửi xe',
      'toll',
      'trạm thu phí',
      'xanh sm',
      'grap',
    ];
    for (final kw in transportKeywords) {
      if (lowerName.contains(kw)) return ExpenseCategory.transport;
    }

    // Shopping
    final shoppingKeywords = [
      'siêu thị',
      'mart',
      'shop',
      'store',
      'cửa hàng',
      'vinmart',
      'winmart',
      'coop',
      'tạp hóa',
      'market',
      'boutique',
      'plaza',
      'pharmacy',
      'nhà thuốc',
    ];
    for (final kw in shoppingKeywords) {
      if (lowerName.contains(kw)) return ExpenseCategory.shopping;
    }

    // Utilities
    final utilitiesKeywords = [
      'điện',
      'nước',
      'internet',
      'wifi',
      'viettel',
      'fpt',
      'vnpt',
      'tiền mạng',
      'cáp',
      'rác',
      'billing',
      'hóa đơn',
    ];
    for (final kw in utilitiesKeywords) {
      if (lowerName.contains(kw)) return ExpenseCategory.utilities;
    }

    // Fallback
    return ExpenseCategory.other;
  }
}
