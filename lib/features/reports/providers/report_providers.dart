import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/expense_category.dart';
import '../../settings/providers/budget_provider.dart';
import '../../expense_list/providers/expense_list_provider.dart';

/// Provider for category filter (null = show all).
final categoryFilterProvider =
    NotifierProvider<CategoryFilterNotifier, ExpenseCategory?>(
      CategoryFilterNotifier.new,
    );

class CategoryFilterNotifier extends Notifier<ExpenseCategory?> {
  @override
  ExpenseCategory? build() => null;

  void setCategory(ExpenseCategory? category) => state = category;
}

/// Month currently displayed by the reports screen.
final selectedReportMonthProvider =
    NotifierProvider<ReportMonthNotifier, DateTime>(ReportMonthNotifier.new);

class ReportMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void select(DateTime month) => state = DateTime(month.year, month.month);

  void move(int months) => select(DateTime(state.year, state.month + months));
}

/// Weekly spending totals within the selected calendar month.
final weeklyTotalsProvider =
    FutureProvider<List<({DateTime date, double total})>>((ref) async {
      ref.watch(expenseListProvider);
      final month = ref.watch(selectedReportMonthProvider);
      final repo = ref.read(expenseRepositoryProvider);
      final rows = await repo.getWeeklyTotals(month);
      return [
        for (final row in rows)
          (
            date: DateTime.parse(row['day'] as String),
            total: (row['total'] as num).toDouble(),
          ),
      ];
    });

/// Daily spending for the last seven available days in the selected month.
final lastSevenDailyTotalsProvider =
    FutureProvider<List<({DateTime date, double total})>>((ref) async {
      ref.watch(expenseListProvider);
      final month = ref.watch(selectedReportMonthProvider);
      final repo = ref.read(expenseRepositoryProvider);
      final rows = await repo.getLastSevenDailyTotals(month);
      return [
        for (final row in rows)
          (
            date: DateTime.parse(row['day'] as String),
            total: (row['total'] as num).toDouble(),
          ),
      ];
    });

/// Provider for category totals of the selected month.
final categoryTotalsProvider = FutureProvider<Map<String, double>>((ref) async {
  ref.watch(expenseListProvider);
  final month = ref.watch(selectedReportMonthProvider);
  final repo = ref.read(expenseRepositoryProvider);
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
  return repo.getCategoryTotals(start, end);
});

/// Provider for selected-month spending (for Budget Gauge).
final monthlyTotalProvider = FutureProvider<double>((ref) async {
  ref.watch(expenseListProvider);
  final month = ref.watch(selectedReportMonthProvider);
  final repo = ref.read(expenseRepositoryProvider);
  return repo.getMonthlyTotal(month);
});

/// Monthly budget configuration used by Reports and the budget gauge.
final monthlyBudgetProvider = FutureProvider<double>((ref) async {
  final budget = await ref.watch(budgetSettingsProvider.future);
  return budget.monthlyLimit;
});
