import 'expense_category.dart';

/// Dart Record for holding parsed OCR data before it is converted to an ExpenseItem.
typedef ParsedReceipt = ({
  String? merchant,
  double? amount,
  DateTime? date,
  ExpenseCategory? suggestedCategory,
  double confidence,
});

/// Immutable model representing an expense item.
class ExpenseItem {
  final int? id;
  final String merchant;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? photoPath;
  final String? rawOcrText;
  final bool isVerified;
  final DateTime createdAt;

  const ExpenseItem({
    this.id,
    required this.merchant,
    required this.amount,
    required this.category,
    required this.date,
    this.photoPath,
    this.rawOcrText,
    this.isVerified = false,
    required this.createdAt,
  });

  /// Draft constructor for creating a temporary unverified expense.
  factory ExpenseItem.draft({
    String merchant = '',
    double amount = 0.0,
    ExpenseCategory category = ExpenseCategory.other,
    DateTime? date,
    String? photoPath,
    String? rawOcrText,
  }) {
    return ExpenseItem(
      merchant: merchant,
      amount: amount,
      category: category,
      date: date ?? DateTime.now(),
      photoPath: photoPath,
      rawOcrText: rawOcrText,
      isVerified: false,
      createdAt: DateTime.now(),
    );
  }

  ExpenseItem copyWith({
    int? id,
    String? merchant,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? photoPath,
    String? rawOcrText,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      photoPath: photoPath ?? this.photoPath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts this instance to a map for SQLite storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant': merchant,
      'amount': amount,
      'category': category.name,
      'date': date.toIso8601String(),
      'photoPath': photoPath,
      'rawOcrText': rawOcrText,
      'isVerified': isVerified ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates an ExpenseItem from a SQLite map.
  factory ExpenseItem.fromMap(Map<String, dynamic> map) {
    return ExpenseItem(
      id: map['id'] as int?,
      merchant: map['merchant'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: ExpenseCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ExpenseCategory.other,
      ),
      date: DateTime.parse(map['date'] as String),
      photoPath: map['photoPath'] as String?,
      rawOcrText: map['rawOcrText'] as String?,
      isVerified: (map['isVerified'] as int) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
