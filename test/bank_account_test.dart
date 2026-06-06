import 'package:flutter_test/flutter_test.dart';
import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/logger.dart';

import 'helpers/test_database.dart';

Map<String, dynamic> _accountData({
  String name = 'Test Account',
  double balance = 0.0,
  double income = 500.0,
}) =>
    {
      'name': name,
      'description': '',
      'balance': balance,
      'income': income,
      'budgetResetPrinciple': 'monthStart',
      'budgetResetDay': 1,
      'lastSavingRun': 'none',
      'isCreditCard': 0,
      'refillsFrom': -1,
      'refillPrincipleMode': 'monthly',
    };

void main() {
  setUp(setUpTestDatabase);
  tearDown(tearDownTestDatabase);

  group('Bank account CRUD', () {
    test('insert bank account persists all fields', () async {
      final db = await DatabaseHelper().database;
      final id = await DatabaseHelper().genericInsert('bankaccounts', _accountData(name: 'Savings', income: 800.0));

      final rows = await db.query('bankaccounts', where: 'id = ?', whereArgs: [id]);
      expect(rows, hasLength(1));
      expect(rows[0]['name'], 'Savings');
      expect(rows[0]['income'], 800.0);
      expect(rows[0]['balance'], 0.0);
    });

    test('update bank account name changes it in DB', () async {
      final db = await DatabaseHelper().database;
      final id = await DatabaseHelper().genericInsert('bankaccounts', _accountData(name: 'Old Name'));

      await DatabaseHelper().genericUpdate('bankaccounts', {'id': id, 'name': 'New Name'});

      final rows = await db.query('bankaccounts', where: 'id = ?', whereArgs: [id]);
      expect(rows[0]['name'], 'New Name');
    });

    test('update after sync creates an editLog entry', () async {
      // insert+update in the same sync cycle → single insert entry (by design).
      // After a sync clears the editLog, an update produces its own entry.
      final db = await DatabaseHelper().database;
      final id = await DatabaseHelper().genericInsert('bankaccounts', _accountData());

      // Simulate completed sync: remove the insert entry
      await db.delete('editLog',
          where: "affectedTable = 'bankaccounts' AND affectedId = ?",
          whereArgs: [id]);

      await DatabaseHelper().genericUpdate('bankaccounts', {'id': id, 'income': 1200.0});

      final logRows = await db.query(
        'editLog',
        where: "affectedTable = 'bankaccounts' AND affectedId = ? AND type = 'update'",
        whereArgs: [id],
      );
      expect(logRows, hasLength(1), reason: 'update after sync must create an editLog entry');
    });

    test('delete bank account removes it from DB', () async {
      final db = await DatabaseHelper().database;
      final id = await DatabaseHelper().genericInsert('bankaccounts', _accountData());

      await DatabaseHelper().genericDelete('bankaccounts', id);

      final rows = await db.query('bankaccounts', where: 'id = ?', whereArgs: [id]);
      expect(rows, isEmpty);
    });

    test('processSavings increases balance when income exceeds spending', () async {
      final db = await DatabaseHelper().database;
      final id = await DatabaseHelper().genericInsert(
        'bankaccounts',
        _accountData(income: 1000.0, balance: 0.0),
      );

      // Insert expense of 300€ within the test range
      final rangeStart = DateTime(2026, 1, 1);
      final rangeEnd = DateTime(2026, 2, 1);
      await db.insert('expenses', {
        'accountId': id,
        'categoryId': -1,
        'description': 'Rent',
        'date': '2026-01-15 00:00:00',
        'amount': 300.0,
        'auto': 0,
        'autoId': -1,
      });

      await DatabaseHelper().processSavings(
        id,
        {'start': rangeStart, 'end': rangeEnd},
        Logger(),
      );

      final rows = await db.query('bankaccounts', where: 'id = ?', whereArgs: [id]);
      // balance = 0 + (1000 - 300) = 700
      expect(rows[0]['balance'], closeTo(700.0, 0.01));
    });

    test('processSavings decreases balance when spending exceeds income', () async {
      final db = await DatabaseHelper().database;
      final id = await DatabaseHelper().genericInsert(
        'bankaccounts',
        _accountData(income: 200.0, balance: 500.0),
      );

      final rangeStart = DateTime(2026, 3, 1);
      final rangeEnd = DateTime(2026, 4, 1);
      await db.insert('expenses', {
        'accountId': id,
        'categoryId': -1,
        'description': 'Overspend',
        'date': '2026-03-15 00:00:00',
        'amount': 400.0,
        'auto': 0,
        'autoId': -1,
      });

      await DatabaseHelper().processSavings(
        id,
        {'start': rangeStart, 'end': rangeEnd},
        Logger(),
      );

      final rows = await db.query('bankaccounts', where: 'id = ?', whereArgs: [id]);
      // balance = 500 + (200 - 400) = 300
      expect(rows[0]['balance'], closeTo(300.0, 0.01));
    });

    test('multiple accounts are isolated — balance update only affects target', () async {
      final db = await DatabaseHelper().database;
      final idA = await DatabaseHelper().genericInsert(
        'bankaccounts',
        _accountData(name: 'Account A', income: 1000.0, balance: 0.0),
      );
      final idB = await DatabaseHelper().genericInsert(
        'bankaccounts',
        _accountData(name: 'Account B', income: 500.0, balance: 200.0),
      );

      await DatabaseHelper().processSavings(
        idA,
        {'start': DateTime(2026, 5, 1), 'end': DateTime(2026, 6, 1)},
        Logger(),
      );

      // Account B should be untouched
      final rowsB = await db.query('bankaccounts', where: 'id = ?', whereArgs: [idB]);
      expect(rowsB[0]['balance'], 200.0, reason: 'Account B balance must not change');
    });
  });
}
