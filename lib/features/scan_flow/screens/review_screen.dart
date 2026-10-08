import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/expense_category.dart';
import '../../../data/models/expense_item.dart';
import '../providers/scan_flow_provider.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  late ExpenseCategory _selectedCategory;
  late DateTime _selectedDate;
  String _imagePath = '';
  String _rawOcrText = '';
  double _confidence = 0.0;
  bool _hasSuggestedCategory = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController();
    _amountController = TextEditingController();
    _dateController = TextEditingController();
    _selectedCategory = ExpenseCategory.other;
    _selectedDate = DateTime.now();

    final state = ref.read(scanFlowProvider);
    if (state is ScanReviewing) {
      final parsed = state.parsedReceipt;
      _merchantController.text = parsed.merchant ?? '';
      _amountController.text = parsed.amount?.toStringAsFixed(0) ?? '';
      _selectedDate = parsed.date ?? DateTime.now();
      _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
      _hasSuggestedCategory = parsed.suggestedCategory != null;
      _selectedCategory = parsed.suggestedCategory ?? ExpenseCategory.other;
      _imagePath = state.imagePath;
      _rawOcrText = state.rawOcrText;
      _confidence = parsed.confidence;
    }
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận hóa đơn'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _onCancel,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image thumbnail
              if (_imagePath.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_imagePath),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120,
                      color: theme.colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Confidence indicator
              if (_confidence < 0.5)
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Độ tin cậy thấp (${(_confidence * 100).round()}%). '
                            'Vui lòng kiểm tra và sửa lại thông tin.',
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Merchant field
              TextFormField(
                controller: _merchantController,
                decoration: const InputDecoration(
                  labelText: 'Ng\u01b0\u1eddi nh\u1eadn / c\u1eeda h\u00e0ng',
                  prefixIcon: Icon(Icons.store),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Không được để trống'
                    : null,
              ),
              const SizedBox(height: 16),

              // Amount field
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Số tiền (VNĐ)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Không được để trống';
                  }
                  final amount = _parseAmount(v);
                  if (amount == null || !amount.isFinite || amount <= 0) {
                    return 'Số tiền phải lớn hơn 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date field
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Ngày',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _clampDate(_selectedDate),
                    firstDate: _firstAllowedDate,
                    lastDate: _lastAllowedDate,
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                      _dateController.text = DateFormat('dd/MM/yyyy')
                          .format(picked);
                    });
                  }
                },
                validator: _validateDate,
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<ExpenseCategory>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Danh mục',
                  prefixIcon: Icon(_selectedCategory.icon),
                  border: const OutlineInputBorder(),
                  helperText: _hasSuggestedCategory
                      ? 'Gợi ý tự động · Bạn có thể chỉnh sửa'
                      : 'Chọn danh mục phù hợp',
                  helperStyle: TextStyle(
                    color: theme.colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                items: ExpenseCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Icon(cat.icon, color: cat.color, size: 20),
                        const SizedBox(width: 8),
                        Text(cat.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 24),

              // Save button
              FilledButton.icon(
                onPressed: _isSaving ? null : _onSave,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Đang lưu...' : 'Lưu chi tiêu'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
              const SizedBox(height: 8),

              // Cancel button
              OutlinedButton(
                onPressed: _isSaving ? null : _onCancel,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Hủy'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    final amount = _parseAmount(_amountController.text)!;

    final expense = ExpenseItem(
      merchant: _merchantController.text.trim(),
      amount: amount,
      category: _selectedCategory,
      date: _selectedDate,
      photoPath: _imagePath,
      rawOcrText: _rawOcrText,
      isVerified: true,
      createdAt: DateTime.now(),
    );

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(scanFlowProvider.notifier);
      final duplicate = await notifier.saveExpense(expense);
      if (!mounted) return;

      if (duplicate != null) {
        final saveAnyway = await _confirmPossibleDuplicate(duplicate);
        if (saveAnyway != true || !mounted) return;
        await notifier.saveExpense(expense, allowDuplicate: true);
        if (!mounted) return;
      }

      ref.read(scanFlowProvider.notifier).reset();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Đã lưu chi tiêu thành công!')),
      );
      context.go('/expenses');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể lưu chi tiêu: $error')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool?> _confirmPossibleDuplicate(ExpenseItem existing) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.content_copy_outlined),
        title: const Text('Có thể là hóa đơn trùng'),
        content: Text(
          'Đã có khoản chi “${existing.merchant}” với cùng số tiền '
          '${formatVND(existing.amount)} trong ngày '
          '${DateFormat('dd/MM/yyyy').format(existing.date)}.\n\n'
          'Bạn có muốn lưu khoản này thêm lần nữa không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Vẫn lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _onCancel() async {
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy bỏ?'),
        content: const Text('Dữ liệu quét sẽ bị mất. Bạn có chắc không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Tiếp tục sửa'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hủy', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDiscard == true && mounted) {
      ref.read(scanFlowProvider.notifier).reset();
      context.go('/expenses');
    }
  }

  static final DateTime _firstAllowedDate = DateTime(2000);
  static DateTime get _lastAllowedDate =>
      DateTime.now().add(const Duration(days: 365));

  static DateTime _clampDate(DateTime date) {
    if (date.isBefore(_firstAllowedDate)) return _firstAllowedDate;
    if (date.isAfter(_lastAllowedDate)) return _lastAllowedDate;
    return date;
  }

  String? _validateDate(String? value) {
    if (value == null || value.trim().isEmpty) return 'Chọn ngày';
    if (_selectedDate.isBefore(_firstAllowedDate) ||
        _selectedDate.isAfter(_lastAllowedDate)) {
      return 'Ngày hóa đơn phải từ năm 2000 đến tối đa một năm tới';
    }
    return null;
  }

  double? _parseAmount(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? null : double.tryParse(digits);
  }
}
