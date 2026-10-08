import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vku_expense_ocr/core/theme/app_theme.dart';
import 'package:vku_expense_ocr/data/models/expense_category.dart';
import 'package:vku_expense_ocr/data/models/expense_item.dart';
import 'package:vku_expense_ocr/features/expense_list/widgets/expense_summary_card.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('expense summary renders in $brightness mode', (tester) async {
      final theme = brightness == Brightness.dark
          ? AppTheme.dark()
          : AppTheme.light();
      final expense = ExpenseItem.draft(
        merchant: 'VU NGOC THONG',
        amount: 1929000,
        category: ExpenseCategory.other,
        date: DateTime(2026, 9, 10),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(body: ExpenseSummaryCard(expense: expense)),
        ),
      );

      expect(find.text('VU NGOC THONG'), findsOneWidget);
      expect(find.text('10/09/2026'), findsOneWidget);
      expect(find.byType(ExpenseSummaryCard), findsOneWidget);
    });
  }
}
