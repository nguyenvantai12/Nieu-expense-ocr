import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/expense_item.dart';

class ExpenseSummaryCard extends StatelessWidget {
  const ExpenseSummaryCard({required this.expense, this.onTap, super.key});

  final ExpenseItem expense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final heroTag =
        'expense-category-${expense.id ?? expense.createdAt.microsecondsSinceEpoch}';
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Hero(
                tag: heroTag,
                child: CircleAvatar(
                  backgroundColor: expense.category.color.withValues(
                    alpha: 0.15,
                  ),
                  child: Icon(
                    expense.category.icon,
                    color: expense.category.color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.merchant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formatDate(expense.date),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatVND(expense.amount),
                textAlign: TextAlign.end,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
