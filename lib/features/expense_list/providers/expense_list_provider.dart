import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/expense_repository.dart';
import '../../../data/models/expense_item.dart';

/// Provider for the ExpenseRepository singleton.
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

/// AsyncNotifierProvider for the list of all expenses.
final expenseListProvider =
    AsyncNotifierProvider<ExpenseListNotifier, List<ExpenseItem>>(
      ExpenseListNotifier.new,
    );

class ExpenseListNotifier extends AsyncNotifier<List<ExpenseItem>> {
  @override
  Future<List<ExpenseItem>> build() async {
    final repo = ref.watch(expenseRepositoryProvider);
    return repo.getAllExpenses();
  }

  Future<void> addExpense(ExpenseItem expense) async {
    final repo = ref.read(expenseRepositoryProvider);
    await repo.insert(expense);
    ref.invalidateSelf();
  }

  Future<void> updateExpense(ExpenseItem expense) async {
    final repo = ref.read(expenseRepositoryProvider);
    await repo.update(expense);
    ref.invalidateSelf();
  }

  Future<void> deleteExpense(int id) async {
    final repo = ref.read(expenseRepositoryProvider);
    await repo.delete(id);
    ref.invalidateSelf();
  }
}
