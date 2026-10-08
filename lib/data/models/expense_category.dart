import 'package:flutter/material.dart';

enum ExpenseCategory {
  food,
  transport,
  shopping,
  utilities,
  other;

  /// Returns the corresponding icon for this category.
  IconData get icon => switch (this) {
    ExpenseCategory.food => Icons.restaurant,
    ExpenseCategory.transport => Icons.directions_car,
    ExpenseCategory.shopping => Icons.shopping_bag,
    ExpenseCategory.utilities => Icons.bolt,
    ExpenseCategory.other => Icons.category,
  };

  /// Returns the corresponding color for this category.
  Color get color => switch (this) {
    ExpenseCategory.food => Colors.orange,
    ExpenseCategory.transport => Colors.blue,
    ExpenseCategory.shopping => Colors.purple,
    ExpenseCategory.utilities => Colors.teal,
    ExpenseCategory.other => Colors.grey,
  };

  /// Returns localized/friendly name (Vietnamese).
  String get displayName => switch (this) {
    ExpenseCategory.food => 'Ăn uống',
    ExpenseCategory.transport => 'Đi lại',
    ExpenseCategory.shopping => 'Mua sắm',
    ExpenseCategory.utilities => 'Hóa đơn & Tiện ích',
    ExpenseCategory.other => 'Khác',
  };
}
