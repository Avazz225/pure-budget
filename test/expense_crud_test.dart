import 'package:flutter_test/flutter_test.dart';
import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/models/expense.dart';

import 'helpers/test_database.dart';

void main() {
  setUp(setUpTestDatabase);
  tearDown(tearDownTestDatabase);

  group('Expense CRUD', () {
    test('create expense assigns an id and persists all fields', () async {
      final now = DateTime(2026, 5, 15);
      final expense = Expense({
        'accountId': -1,
        'categoryId': -1,
        'description': 'Groceries',
        'date': formatForSqlite(now),
        'amount': 42.50,
        'auto': 0,
        'autoId': -1,
      });

      await expense.save();

      expect(expense.id, isNotNull, reason: 'save() must assign an id');

      final db = await DatabaseHelper().database;
      final rows = await db.query('expenses', where: 'id = ?', whereArgs: [expense.id]);
      expect(rows, hasLength(1));
      expect(rows[0]['description'], 'Groceries');
      expect(rows[0]['amount'], 42.50);
      expect(rows[0]['accountId'], -1);
    });

    test('save() on existing expense updates the record', () async {
      final expense = Expense({
        'accountId': -1,
        'categoryId': -1,
        'description': 'Coffee',
        'date': formatForSqlite(DateTime(2026, 5, 10)),
        'amount': 3.50,
        'auto': 0,
        'autoId': -1,
      });
      await expense.save();
      final originalId = expense.id!;

      expense.amount = 4.00;
      expense.description = 'Coffee (updated)';
      await expense.save();

      final db = await DatabaseHelper().database;
      final rows = await db.query('expenses', where: 'id = ?', whereArgs: [originalId]);
      expect(rows, hasLength(1));
      expect(rows[0]['amount'], 4.00);
      expect(rows[0]['description'], 'Coffee (updated)');
    });

    test('delete expense removes it from the database', () async {
      final expense = Expense({
        'accountId': -1,
        'categoryId': -1,
        'description': 'To delete',
        'date': formatForSqlite(DateTime(2026, 5, 1)),
        'amount': 10.0,
        'auto': 0,
        'autoId': -1,
      });
      await expense.save();
      final id = expense.id!;

      await expense.delete();

      final db = await DatabaseHelper().database;
      final rows = await db.query('expenses', where: 'id = ?', whereArgs: [id]);
      expect(rows, isEmpty, reason: 'deleted expense must not appear in DB');
    });

    test('create expense writes an editLog entry', () async {
      final db = await DatabaseHelper().database;
      final before = await db.query('editLog', where: "affectedTable = 'expenses'");

      final expense = Expense({
        'accountId': -1,
        'categoryId': -1,
        'description': 'Log test',
        'date': formatForSqlite(DateTime(2026, 5, 20)),
        'amount': 5.0,
        'auto': 0,
        'autoId': -1,
      });
      await expense.save();

      final after = await db.query(
        'editLog',
        where: "affectedTable = 'expenses' AND type = 'insert'",
      );
      expect(after.length, greaterThan(before.length));
    });

    test('delete expense removes or replaces its editLog entry', () async {
      final expense = Expense({
        'accountId': -1,
        'categoryId': -1,
        'description': 'Ephemeral',
        'date': formatForSqlite(DateTime(2026, 5, 5)),
        'amount': 1.0,
        'auto': 0,
        'autoId': -1,
      });
      await expense.save();
      final id = expense.id!;
      await expense.delete();

      // After insert+delete the editLog entry for this record should
      // be gone (DatabaseHelper cancels insert/delete pairs).
      final db = await DatabaseHelper().database;
      final logRows = await db.query(
        'editLog',
        where: "affectedTable = 'expenses' AND affectedId = ?",
        whereArgs: [id],
      );
      expect(logRows, isEmpty, reason: 'insert+delete pair should cancel in editLog');
    });

    test('creating multiple expenses gives each a unique id', () async {
      final ids = <int>{};
      for (int i = 0; i < 5; i++) {
        final e = Expense({
          'accountId': -1,
          'categoryId': -1,
          'description': 'Item $i',
          'date': formatForSqlite(DateTime(2026, 5, i + 1)),
          'amount': i * 10.0,
          'auto': 0,
          'autoId': -1,
        });
        await e.save();
        ids.add(e.id!);
      }
      expect(ids.length, 5, reason: 'each expense must have a distinct id');
    });

    test('future-dated expense is stored with correct date', () async {
      final future = DateTime(2030, 12, 31);
      final expense = Expense({
        'accountId': -1,
        'categoryId': -1,
        'description': 'Future booking',
        'date': formatForSqlite(future),
        'amount': 99.0,
        'auto': 0,
        'autoId': -1,
      });
      await expense.save();

      final db = await DatabaseHelper().database;
      final rows = await db.query('expenses', where: 'id = ?', whereArgs: [expense.id]);
      expect(rows[0]['date'].toString(), startsWith('2030-12-31'));
    });
  });
}
