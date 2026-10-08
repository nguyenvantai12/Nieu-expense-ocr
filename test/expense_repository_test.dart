import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vku_expense_ocr/data/db/app_database.dart';
import 'package:vku_expense_ocr/data/db/expense_repository.dart';
import 'package:vku_expense_ocr/data/models/expense_category.dart';
import 'package:vku_expense_ocr/data/models/expense_item.dart';

void main() {
  late AppDatabase appDatabase;
  late ExpenseRepository repository;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    final database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
    );
    appDatabase = AppDatabase.forTesting(database);
    await appDatabase.createSchemaForTesting(database, version: 2);
    repository = ExpenseRepository(database: appDatabase);
  });

  tearDown(() async => appDatabase.closeForTesting());

  test('inserts, reads, updates and deletes an expense', () async {
    final id = await repository.insert(_expense('Coffee', 45000));
    expect((await repository.getAllExpenses()).single.merchant, 'Coffee');

    await repository.update(
      _expense('Cafe', 50000).copyWith(id: id, isVerified: true),
    );
    final updated = (await repository.getAllExpenses()).single;
    expect(updated.merchant, 'Cafe');
    expect(updated.isVerified, isTrue);

    expect(await repository.delete(id), 1);
    expect(await repository.getAllExpenses(), isEmpty);
  });

  test(
    'rejects a likely same-day duplicate unless explicitly allowed',
    () async {
      final expense = _expense('Coffee Shop', 45000);
      final id = await repository.insert(expense);

      await expectLater(
        repository.insert(expense.copyWith(id: null)),
        throwsA(isA<DuplicateExpenseException>()),
      );
      expect(
        await repository.insert(
          expense.copyWith(id: null),
          allowDuplicate: true,
        ),
        isNot(id),
      );
    },
  );

  test('sums a month and groups category totals', () async {
    await repository.insert(_expense('Food A', 10000, DateTime(2026, 9, 2)));
    await repository.insert(_expense('Food B', 25000, DateTime(2026, 9, 8)));
    await repository.insert(
      _expense('Ride', 40000, DateTime(2026, 9, 12), ExpenseCategory.transport),
    );
    await repository.insert(_expense('October', 90000, DateTime(2026, 10, 1)));

    expect(await repository.getMonthlyTotal(DateTime(2026, 9)), 75000);
    final totals = await repository.getCategoryTotals(
      DateTime(2026, 9),
      DateTime(2026, 9, 30, 23, 59, 59),
    );
    expect(totals[ExpenseCategory.food.name], 35000);
    expect(totals[ExpenseCategory.transport.name], 40000);
  });

  test('creates seven daily totals including zero-spend days', () async {
    final reference = DateTime.now();
    await repository.insert(_expense('Today', 12000, reference));

    final totals = await repository.getLastSevenDailyTotals(reference);

    expect(totals, hasLength(7));
    expect(totals.last['total'], 12000);
    expect(totals.where((day) => day['total'] == 0), hasLength(6));
  });

  test('compares calendar week totals by category for a fixed date', () async {
    await repository.insert(_expense('This week', 20000, DateTime(2026, 9, 7)));
    await repository.insert(
      _expense('Last week', 10000, DateTime(2026, 8, 31)),
    );

    final comparison = await repository.getPreviousPeriodComparison(
      DateTime(2026, 9, 9),
    );

    expect(comparison[ExpenseCategory.food.name], {
      'current': 20000.0,
      'previous': 10000.0,
    });
  });

  test(
    'upgrading v1 database adds indexes and preserves expense rows',
    () async {
      await appDatabase.closeForTesting();
      final database = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
      );
      appDatabase = AppDatabase.forTesting(database);
      await appDatabase.createSchemaForTesting(database, version: 1);
      final id = await database.insert(
        'expenses',
        _expense('Legacy', 12345).toMap(),
      );

      await appDatabase.upgradeForTesting(database, 1, 2);

      final rows = await database.query('expenses');
      final indexes = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'idx_expenses_%'",
      );
      expect(rows.single['id'], id);
      expect(
        indexes.map((row) => row['name']),
        containsAll(['idx_expenses_date', 'idx_expenses_category_date']),
      );
    },
  );
}

ExpenseItem _expense(
  String merchant,
  double amount, [
  DateTime? date,
  ExpenseCategory category = ExpenseCategory.food,
]) => ExpenseItem.draft(
  merchant: merchant,
  amount: amount,
  category: category,
  date: date ?? DateTime(2026, 9, 8),
  rawOcrText: 'receipt $merchant $amount',
);
