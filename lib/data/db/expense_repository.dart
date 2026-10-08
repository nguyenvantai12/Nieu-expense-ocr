import '../models/expense_item.dart';
import 'app_database.dart';

class ExpenseRepository {
  ExpenseRepository({AppDatabase? database})
    : _db = database ?? AppDatabase.instance;

  final AppDatabase _db;
  static const String table = 'expenses';

  Future<int> insert(ExpenseItem expense, {bool allowDuplicate = false}) async {
    final db = await _db.database;
    return db.transaction((transaction) async {
      if (!allowDuplicate) {
        final matches = await transaction.query(
          table,
          where: 'date >= ? AND date < ?',
          whereArgs: _dayRange(expense.date),
        );
        final duplicate = _matchDuplicate(expense, matches);
        if (duplicate != null) throw DuplicateExpenseException(duplicate);
      }
      return transaction.insert(table, expense.toMap());
    });
  }

  /// Finds a likely duplicate with the same date and amount, plus matching
  /// merchant or OCR text. This is intentionally a warning-level heuristic.
  Future<ExpenseItem?> findPossibleDuplicate(ExpenseItem expense) async {
    final db = await _db.database;
    final matches = await db.query(
      table,
      where: 'date >= ? AND date < ?',
      whereArgs: _dayRange(expense.date),
    );
    return _matchDuplicate(expense, matches);
  }

  List<String> _dayRange(DateTime date) => [
    DateTime(date.year, date.month, date.day).toIso8601String(),
    DateTime(date.year, date.month, date.day + 1).toIso8601String(),
  ];

  ExpenseItem? _matchDuplicate(
    ExpenseItem candidate,
    List<Map<String, Object?>> rows,
  ) {
    final merchant = _normalizeForComparison(candidate.merchant);
    final rawOcr = _normalizeForComparison(candidate.rawOcrText ?? '');
    for (final row in rows) {
      final existing = ExpenseItem.fromMap(row);
      if ((existing.amount * 100).round() != (candidate.amount * 100).round()) {
        continue;
      }
      final sameMerchant =
          merchant.isNotEmpty &&
          merchant == _normalizeForComparison(existing.merchant);
      final sameOcr =
          rawOcr.isNotEmpty &&
          rawOcr == _normalizeForComparison(existing.rawOcrText ?? '');
      if (sameMerchant || sameOcr) return existing;
    }
    return null;
  }

  String _normalizeForComparison(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp('[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp('[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp('[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp('[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp('[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp('[ỳýỵỷỹ]'), 'y')
        .replaceAll('đ', 'd')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Future<int> update(ExpenseItem expense) async {
    final db = await _db.database;
    return await db.update(
      table,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ExpenseItem>> getAllExpenses() async {
    final db = await _db.database;
    final maps = await db.query(table, orderBy: 'date DESC');
    return maps.map((map) => ExpenseItem.fromMap(map)).toList();
  }

  Future<double> getMonthlyTotal(DateTime month) async {
    final db = await _db.database;
    final startDate = DateTime(month.year, month.month, 1).toIso8601String();
    final endDate = DateTime(month.year, month.month + 1).toIso8601String();

    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) as total 
      FROM $table 
      WHERE date >= ? AND date < ?
    ''',
      [startDate, endDate],
    );

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, double>> getCategoryTotals(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _db.database;
    final endExclusive = DateTime(end.year, end.month, end.day + 1);
    final result = await db.rawQuery(
      '''
      SELECT category, SUM(amount) as total 
      FROM $table 
      WHERE date >= ? AND date < ?
      GROUP BY category
    ''',
      [
        DateTime(start.year, start.month, start.day).toIso8601String(),
        endExclusive.toIso8601String(),
      ],
    );

    return {
      for (var row in result)
        row['category'] as String: (row['total'] as num).toDouble(),
    };
  }

  Future<List<Map<String, dynamic>>> getWeeklyTotals(
    DateTime referenceDate,
  ) async {
    final db = await _db.database;
    final monthStart = DateTime(referenceDate.year, referenceDate.month);
    final monthEnd = DateTime(referenceDate.year, referenceDate.month + 1);
    final firstWeekStart = monthStart.subtract(
      Duration(days: monthStart.weekday - 1),
    );

    final result = await db.rawQuery(
      '''
      SELECT date(date) as day, SUM(amount) as total
      FROM $table 
      WHERE date >= ? AND date < ?
      GROUP BY day
      ORDER BY day ASC
    ''',
      [monthStart.toIso8601String(), monthEnd.toIso8601String()],
    );

    final weekCount = (monthEnd.difference(firstWeekStart).inDays / 7).ceil();
    final totalsByWeek = List<double>.filled(weekCount, 0);
    for (final row in result) {
      final day = DateTime.parse(row['day'] as String);
      final weekIndex = day.difference(firstWeekStart).inDays ~/ 7;
      totalsByWeek[weekIndex] += (row['total'] as num).toDouble();
    }

    return [
      for (var index = 0; index < weekCount; index++)
        {
          'day':
              firstWeekStart.add(Duration(days: index * 7)).isBefore(monthStart)
              ? monthStart.toIso8601String()
              : firstWeekStart.add(Duration(days: index * 7)).toIso8601String(),
          'total': totalsByWeek[index],
        },
    ];
  }

  /// Daily totals for the final seven available days of a selected month.
  /// For the current month, the range ends today; for older months, it ends
  /// on the last day of that month.
  Future<List<Map<String, dynamic>>> getLastSevenDailyTotals(
    DateTime referenceDate,
  ) async {
    final db = await _db.database;
    final monthStart = DateTime(referenceDate.year, referenceDate.month);
    final monthEnd = DateTime(referenceDate.year, referenceDate.month + 1);
    final today = DateTime.now();
    final isCurrentMonth =
        referenceDate.year == today.year && referenceDate.month == today.month;
    final endExclusive = isCurrentMonth
        ? DateTime(today.year, today.month, today.day + 1)
        : monthEnd;
    final proposedStart = endExclusive.subtract(const Duration(days: 7));
    final start = proposedStart.isBefore(monthStart)
        ? monthStart
        : proposedStart;

    final rows = await db.rawQuery(
      '''
      SELECT date(date) as day, SUM(amount) as total
      FROM $table
      WHERE date >= ? AND date < ?
      GROUP BY day
      ORDER BY day ASC
      ''',
      [start.toIso8601String(), endExclusive.toIso8601String()],
    );
    final totalsByDay = {
      for (final row in rows)
        row['day'] as String: (row['total'] as num).toDouble(),
    };
    final dayCount = endExclusive.difference(start).inDays;

    return [
      for (var offset = 0; offset < dayCount; offset++)
        {
          'day': start.add(Duration(days: offset)).toIso8601String(),
          'total':
              totalsByDay[start
                  .add(Duration(days: offset))
                  .toIso8601String()
                  .substring(0, 10)] ??
              0.0,
        },
    ];
  }

  /// Returns comparison between this week vs last week per category for the Insights Engine.
  Future<Map<String, Map<String, double>>> getPreviousPeriodComparison([
    DateTime? referenceDate,
  ]) async {
    final db = await _db.database;
    final now = referenceDate ?? DateTime.now();

    // Use calendar week boundaries and a half-open range for both periods.
    final currentWeekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final currentWeekEnd = currentWeekStart.add(const Duration(days: 7));
    final currentWeekStartStr = currentWeekStart.toIso8601String();
    final currentWeekEndStr = currentWeekEnd.toIso8601String();

    // Define previous week boundaries
    final prevWeekStart = currentWeekStart.subtract(const Duration(days: 7));
    final prevWeekStartStr = DateTime(
      prevWeekStart.year,
      prevWeekStart.month,
      prevWeekStart.day,
    ).toIso8601String();

    // Current week totals
    final currentResult = await db.rawQuery(
      '''
      SELECT category, SUM(amount) as total 
      FROM $table 
      WHERE date >= ? AND date < ?
      GROUP BY category
    ''',
      [currentWeekStartStr, currentWeekEndStr],
    );

    // Previous week totals
    final prevResult = await db.rawQuery(
      '''
      SELECT category, SUM(amount) as total 
      FROM $table 
      WHERE date >= ? AND date < ?
      GROUP BY category
    ''',
      [prevWeekStartStr, currentWeekStartStr],
    );

    final Map<String, Map<String, double>> comparison = {};

    for (var row in currentResult) {
      final cat = row['category'] as String;
      comparison[cat] = {
        'current': (row['total'] as num).toDouble(),
        'previous': 0.0,
      };
    }

    for (var row in prevResult) {
      final cat = row['category'] as String;
      if (!comparison.containsKey(cat)) {
        comparison[cat] = {'current': 0.0, 'previous': 0.0};
      }
      comparison[cat]!['previous'] = (row['total'] as num).toDouble();
    }

    return comparison;
  }
}

class DuplicateExpenseException implements Exception {
  const DuplicateExpenseException(this.existingExpense);

  final ExpenseItem existingExpense;
}
