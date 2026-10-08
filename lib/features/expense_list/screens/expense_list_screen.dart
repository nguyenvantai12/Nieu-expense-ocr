import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/expense_category.dart';
import '../widgets/expense_summary_card.dart';
import '../providers/expense_list_provider.dart';
import '../../reports/providers/report_providers.dart';

class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseListProvider);
    final categoryFilter = ref.watch(categoryFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiêu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Tất cả'),
                    selected: categoryFilter == null,
                    onSelected: (_) => ref
                        .read(categoryFilterProvider.notifier)
                        .setCategory(null),
                  ),
                ),
                ...ExpenseCategory.values.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: Icon(cat.icon, size: 18),
                      label: Text(cat.displayName),
                      selected: categoryFilter == cat,
                      onSelected: (_) => ref
                          .read(categoryFilterProvider.notifier)
                          .setCategory(categoryFilter == cat ? null : cat),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Expense list
          Expanded(
            child: expensesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
              data: (expenses) {
                final filtered = categoryFilter == null
                    ? expenses
                    : expenses
                          .where((e) => e.category == categoryFilter)
                          .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có chi tiêu nào.\nBấm nút "Quét" để bắt đầu!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 640 ? 2 : 1;
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 88),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisExtent: 84,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return Dismissible(
                          key: ValueKey(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.red,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (_) async => showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Xác nhận xóa'),
                              content: const Text(
                                'Bạn có chắc muốn xóa chi tiêu này?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Hủy'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text(
                                    'Xóa',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onDismissed: (_) {
                            ref
                                .read(expenseListProvider.notifier)
                                .deleteExpense(item.id!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã xóa chi tiêu')),
                            );
                          },
                          child: ExpenseSummaryCard(
                            expense: item,
                            onTap: item.id == null
                                ? null
                                : () => context.push('/expenses/${item.id}'),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
