import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/expense_category.dart';
import '../providers/report_providers.dart';
import '../widgets/budget_gauge.dart';
import '../widgets/category_donut_chart.dart';
import '../widgets/insights_card.dart';
import '../widgets/weekly_spending_chart.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekly = ref.watch(weeklyTotalsProvider);
    final daily = ref.watch(lastSevenDailyTotalsProvider);
    final categories = ref.watch(categoryTotalsProvider);
    final monthlyTotal = ref.watch(monthlyTotalProvider);
    final monthlyBudget = ref.watch(monthlyBudgetProvider);
    final reportMonth = ref.watch(selectedReportMonthProvider);
    final currentMonth = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Báo cáo')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final categoryCard = _sectionCard(
            context,
            title: 'Chi tiêu theo danh mục',
            icon: Icons.donut_large,
            child: categories.when(
              loading: _loading,
              error: (error, _) => _error(error),
              data: (totals) {
                final items = [
                  for (final category in ExpenseCategory.values)
                    if ((totals[category.name] ?? 0) > 0)
                      (category: category, amount: totals[category.name]!),
                ];
                if (items.isEmpty) {
                  return _empty('Chưa có chi tiêu trong tháng này.');
                }
                return CategoryDonutChart(items: items);
              },
            ),
          );
          final budgetCard = _sectionCard(
            context,
            title: 'Ngân sách tháng',
            icon: Icons.speed,
            child: _combineTotalsAndBudget(monthlyTotal, monthlyBudget),
          );
          final dailyCard = _sectionCard(
            context,
            title: '\u0043hi ti\u00eau 7 ng\u00e0y',
            icon: Icons.calendar_view_day,
            child: daily.when(
              loading: _loading,
              error: (error, _) => _error(error),
              data: (days) {
                if (days.every((day) => day.total <= 0)) {
                  return _empty(
                    'Ch\u01b0a c\u00f3 chi ti\u00eau trong 7 ng\u00e0y n\u00e0y.',
                  );
                }
                return SpendingBarChart(
                  days: days,
                  semanticLabel: '\u0042i\u1ec3u \u0111\u1ed3 chi ti\u00eau theo ng\u00e0y trong 7 ng\u00e0y.',
                );
              },
            ),
          );
          final weeklyCard = _sectionCard(
            context,
            title: 'Chi tiêu 7 ngày trong tuần',
            icon: Icons.bar_chart,
            child: weekly.when(
              loading: _loading,
              error: (error, _) => _error(error),
              data: (days) {
                if (days.every((day) => day.total <= 0)) {
                  return _empty('Chưa có chi tiêu trong tuần này.');
                }
                return SpendingBarChart(
                  days: days,
                  semanticLabel: '\u0042i\u1ec3u \u0111\u1ed3 chi ti\u00eau theo tu\u1ea7n trong th\u00e1ng.',
                );
              },
            ),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _monthSelector(
                  context,
                  reportMonth: reportMonth,
                  canMoveForward: reportMonth.isBefore(
                    DateTime(currentMonth.year, currentMonth.month),
                  ),
                  onMove: (months) => ref
                      .read(selectedReportMonthProvider.notifier)
                      .move(months),
                ),
                const SizedBox(height: 12),
                if (reportMonth.year == currentMonth.year &&
                    reportMonth.month == currentMonth.month)
                  const InsightsCard()
                else
                  const SizedBox.shrink(),
                const SizedBox(height: 12),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: categoryCard),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: budgetCard),
                    ],
                  )
                else ...[
                  categoryCard,
                  const SizedBox(height: 12),
                  budgetCard,
                ],
                const SizedBox(height: 12),
                dailyCard,
                const SizedBox(height: 12),
                weeklyCard,
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _monthSelector(
    BuildContext context, {
    required DateTime reportMonth,
    required bool canMoveForward,
    required ValueChanged<int> onMove,
  }) {
    return Card(
      child: Row(
        children: [
          IconButton(
            tooltip: 'Tháng trước',
            onPressed: () => onMove(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Tháng báo cáo',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  DateFormat('MM/yyyy').format(reportMonth),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Tháng sau',
            onPressed: canMoveForward ? () => onMove(1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _combineTotalsAndBudget(
    AsyncValue<double> total,
    AsyncValue<double> budget,
  ) {
    if (total.isLoading || budget.isLoading) return _loading();
    if (total.hasError) return _error(total.error!);
    if (budget.hasError) return _error(budget.error!);
    return BudgetGauge(spent: total.value ?? 0, budget: budget.value ?? 0);
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final displayTitle = icon == Icons.bar_chart
        ? '\u0043hi ti\u00eau theo tu\u1ea7n trong th\u00e1ng'
        : title;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _loading() => const SizedBox(
    height: 180,
    child: Center(child: CircularProgressIndicator()),
  );

  Widget _error(Object error) => SizedBox(
    height: 140,
    child: Center(child: Text('Không tải được dữ liệu: $error')),
  );

  Widget _empty(String message) => SizedBox(
    height: 160,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: 40,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
