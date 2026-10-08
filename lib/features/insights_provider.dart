import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/expense_category.dart';
import 'expense_list/providers/expense_list_provider.dart';
import 'reports/providers/report_providers.dart';

/// Provider for insights (rule-based, offline).
final insightsProvider = FutureProvider<List<String>>((ref) async {
  ref.watch(expenseListProvider);
  final repo = ref.read(expenseRepositoryProvider);
  final comparison = await repo.getPreviousPeriodComparison();
  final monthlyTotal = await repo.getMonthlyTotal(DateTime.now());
  final budgetLimit = await ref.watch(monthlyBudgetProvider.future);
  return generateInsights(comparison, monthlyTotal, budgetLimit);
});

/// Pure function to generate insights text — easy to unit test.
List<String> generateInsights(
  Map<String, Map<String, double>> comparison,
  double monthlyTotal,
  double budgetLimit,
) {
  final insights = <String>[];

  // Insight 1: Compare categories week-over-week
  for (final entry in comparison.entries) {
    final category = entry.key;
    final current = entry.value['current'] ?? 0;
    final previous = entry.value['previous'] ?? 0;

    if (previous > 0 && current > 0) {
      final change = ((current - previous) / previous * 100).round();
      final categoryName = _categoryDisplayName(category);

      if (change > 20) {
        insights.add(
          'Chi tiêu $categoryName tuần này tăng $change% so với tuần trước.',
        );
      } else if (change < -20) {
        insights.add(
          'Chi tiêu $categoryName tuần này giảm ${change.abs()}% so với tuần trước. Tốt lắm! 👍',
        );
      }
    } else if (current > 0 && previous == 0) {
      final categoryName = _categoryDisplayName(category);
      insights.add(
        'Tuần này bạn bắt đầu chi cho $categoryName (tuần trước chưa có).',
      );
    }
  }

  // Insight 2: Budget usage percentage
  if (budgetLimit > 0) {
    final usage = (monthlyTotal / budgetLimit * 100).round();
    if (usage >= 90) {
      insights.add(
        '⚠️ Bạn đã dùng $usage% ngân sách tháng. Hãy cân nhắc chi tiêu!',
      );
    } else if (usage >= 70) {
      insights.add(
        'Bạn đã dùng $usage% ngân sách tháng. Vẫn còn kiểm soát tốt.',
      );
    }
  }

  // Insight 3: Top spending category
  if (comparison.isNotEmpty) {
    String? topCat;
    double topAmount = 0;
    for (final entry in comparison.entries) {
      final current = entry.value['current'] ?? 0;
      if (current > topAmount) {
        topAmount = current;
        topCat = entry.key;
      }
    }
    if (topCat != null && topAmount > 0) {
      insights.add(
        'Danh mục chi nhiều nhất tuần này: ${_categoryDisplayName(topCat)}.',
      );
    }
  }

  // Limit to 3 insights max
  if (insights.length > 3) return insights.sublist(0, 3);
  return insights;
}

String _categoryDisplayName(String categoryName) {
  for (final category in ExpenseCategory.values) {
    if (category.name == categoryName) return category.displayName;
  }
  return 'Khác';
}
