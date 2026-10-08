import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/expense_item.dart';
import '../providers/expense_list_provider.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({required this.expenseId, super.key});

  final int expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết chi tiêu')),
      body: expenses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Không tải được chi tiêu: $error')),
        data: (items) {
          final matches = items.where((item) => item.id == expenseId);
          if (matches.isEmpty) {
            return const Center(
              child: Text('Khoản chi tiêu không còn tồn tại.'),
            );
          }
          return _ExpenseDetails(item: matches.first);
        },
      ),
    );
  }
}

class _ExpenseDetails extends StatelessWidget {
  const _ExpenseDetails({required this.item});

  final ExpenseItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final id = item.id;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (item.photoPath case final photoPath?) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(photoPath),
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 24),
        ],
        Center(
          child: Hero(
            tag:
                'expense-category-${id ?? item.createdAt.microsecondsSinceEpoch}',
            child: CircleAvatar(
              radius: 36,
              backgroundColor: item.category.color.withValues(alpha: 0.15),
              child: Icon(
                item.category.icon,
                color: item.category.color,
                size: 34,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          item.merchant,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          formatVND(item.amount),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        _DetailRow(label: 'Danh mục', value: item.category.displayName),
        _DetailRow(label: 'Ngày chi', value: formatDate(item.date)),
        _DetailRow(
          label: 'Xác nhận',
          value: item.isVerified ? 'Đã xác nhận' : 'Chưa xác nhận',
        ),
        if (item.rawOcrText case final rawText? when rawText.trim().isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Văn bản OCR'),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SelectableText(rawText),
              ),
            ],
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Text(value, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}
