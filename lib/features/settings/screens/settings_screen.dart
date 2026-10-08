import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_mode_provider.dart';
import '../../../data/models/budget_settings.dart';
import '../providers/budget_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final budgetAsync = ref.watch(budgetSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/expenses'),
        ),
      ),
      body: ListView(
        children: [
          // Theme section
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Chế độ giao diện'),
            subtitle: Text(switch (themeMode) {
              ThemeMode.light => 'Sáng',
              ThemeMode.dark => 'Tối',
              ThemeMode.system => 'Theo hệ thống',
            }),
            onTap: () {
              ref.read(themeModeProvider.notifier).toggle();
            },
          ),
          const Divider(),

          // Budget section
          budgetAsync.when(
            loading: () => const ListTile(
              leading: Icon(Icons.account_balance_wallet),
              title: Text('Ngân sách tháng'),
              subtitle: LinearProgressIndicator(),
            ),
            error: (e, _) => ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Ngân sách tháng'),
              subtitle: Text('Lỗi: $e'),
            ),
            data: (budget) => ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Ngân sách tháng'),
              subtitle: Text('${_formatBudget(budget.monthlyLimit)} VNĐ'),
              trailing: const Icon(Icons.edit),
              onTap: () => _showBudgetDialog(context, ref, budget),
            ),
          ),
          const Divider(),

          // App info
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Chi Tiêu Thông Minh'),
            subtitle: Text('Phiên bản 1.0.0\nVKU Expense OCR'),
          ),
        ],
      ),
    );
  }

  String _formatBudget(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}tr';
    }
    return amount.toStringAsFixed(0);
  }

  Future<void> _showBudgetDialog(
    BuildContext context,
    WidgetRef ref,
    BudgetSettings current,
  ) async {
    final controller = TextEditingController(
      text: current.monthlyLimit.toStringAsFixed(0),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ngân sách tháng'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Số tiền (VNĐ)',
            border: OutlineInputBorder(),
            hintText: 'Ví dụ: 5000000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                Navigator.of(ctx).pop(val);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result != null) {
      final repo = await ref.read(budgetSettingsRepoProvider.future);
      await repo.saveSettings(BudgetSettings(monthlyLimit: result));
      ref.invalidate(budgetSettingsProvider);
    }
  }
}
