import 'package:flutter_test/flutter_test.dart';
import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/services/background_jobs.dart';

import 'helpers/test_database.dart';

// Helpers

/// Creates a real bank account and returns its id.
Future<int> _insertBankAccount(String name, {double income = 500.0}) async {
  return DatabaseHelper().genericInsert('bankaccounts', {
    'name': name,
    'description': '',
    'balance': 0.0,
    'income': income,
    'budgetResetPrinciple': 'monthStart',
    'budgetResetDay': 1,
    'lastSavingRun': 'none',
    'isCreditCard': 0,
    'refillsFrom': -1,
    'refillPrincipleMode': 'monthly',
  });
}

/// Inserts a past interval for [accountId] (ended 2026-01-01, well in the past).
Future<int> _insertExpiredInterval(int accountId) async {
  return DatabaseHelper().genericInsert('intervals', {
    'start': '2025-12-01 00:00:00',
    'end': '2026-01-01 00:00:00',
    'accountId': accountId,
  });
}

/// Inserts a realizedBankaccounts entry (required before backgroundJobs can
/// roll over to the next interval).
Future<void> _insertRealizedBankAccount(int intervalId, int accountId, double income) async {
  await DatabaseHelper().genericInsert('realizedBankaccounts', {
    'intervalId': intervalId,
    'accountId': accountId,
    'income': income,
    'balance': 0.0,
  });
}

void main() {
  setUp(setUpTestDatabase);
  tearDown(tearDownTestDatabase);

  group('Background jobs — interval creation', () {
    test('creates a new interval when the current one is expired', () async {
      final db = await DatabaseHelper().database;
      final accountId = await _insertBankAccount('Test Account');
      final intervalId = await _insertExpiredInterval(accountId);
      await _insertRealizedBankAccount(intervalId, accountId, 500.0);

      final intervalsBefore = await db.query(
        'intervals',
        where: 'accountId = ?',
        whereArgs: [accountId],
      );

      final didChange = await backgroundJobs(dbHelper: DatabaseHelper());

      final intervalsAfter = await db.query(
        'intervals',
        where: 'accountId = ?',
        whereArgs: [accountId],
      );

      expect(didChange, isTrue, reason: 'backgroundJobs must report changes when interval rolled over');
      expect(
        intervalsAfter.length,
        greaterThan(intervalsBefore.length),
        reason: 'a new interval must have been created',
      );
    });

    test('new interval starts where the old one ended', () async {
      final db = await DatabaseHelper().database;
      final accountId = await _insertBankAccount('Rollover Test');
      final intervalId = await _insertExpiredInterval(accountId);
      await _insertRealizedBankAccount(intervalId, accountId, 500.0);

      await backgroundJobs(dbHelper: DatabaseHelper());

      final intervals = await db.query(
        'intervals',
        where: 'accountId = ?',
        whereArgs: [accountId],
        orderBy: 'id ASC',
      );

      // The new interval start should be on or after the current month's first day
      final newInterval = intervals.last;
      final newStart = DateTime.parse(newInterval['start'] as String);
      final now = DateTime.now();
      expect(newStart.year, now.year);
      expect(newStart.month, now.month);
    });

    test('does not create a new interval when current one is still valid', () async {
      final db = await DatabaseHelper().database;
      final accountId = await _insertBankAccount('Valid Account');

      // Insert a current (not expired) interval
      final now = DateTime.now();
      final currentIntervalId = await DatabaseHelper().genericInsert('intervals', {
        'start': '${now.year}-${now.month.toString().padLeft(2, '0')}-01 00:00:00',
        'end': '${now.year}-${(now.month % 12 + 1).toString().padLeft(2, '0')}-01 00:00:00',
        'accountId': accountId,
      });
      await _insertRealizedBankAccount(currentIntervalId, accountId, 500.0);

      final intervalsBefore = await db.query(
        'intervals',
        where: 'accountId = ?',
        whereArgs: [accountId],
      );

      await backgroundJobs(dbHelper: DatabaseHelper());

      final intervalsAfter = await db.query(
        'intervals',
        where: 'accountId = ?',
        whereArgs: [accountId],
      );

      expect(
        intervalsAfter.length,
        equals(intervalsBefore.length),
        reason: 'no new interval when current is still valid',
      );
    });

    test('creates realizedBankaccounts for the new interval', () async {
      final db = await DatabaseHelper().database;
      final accountId = await _insertBankAccount('Balance Account', income: 1000.0);
      final intervalId = await _insertExpiredInterval(accountId);
      await _insertRealizedBankAccount(intervalId, accountId, 1000.0);

      await backgroundJobs(dbHelper: DatabaseHelper());

      // Find the new interval
      final intervals = await db.query(
        'intervals',
        where: 'accountId = ?',
        whereArgs: [accountId],
        orderBy: 'id DESC',
      );
      expect(intervals.length, greaterThan(1));
      final newIntervalId = intervals.first['id'];

      final realized = await db.query(
        'realizedBankaccounts',
        where: 'intervalId = ? AND accountId = ?',
        whereArgs: [newIntervalId, accountId],
      );
      expect(realized, hasLength(1), reason: 'realizedBankaccounts must be created for the new interval');
      expect(realized[0]['income'], closeTo(1000.0, 0.01));
    });

    test('auto-expense is booked when new interval is created', () async {
      final db = await DatabaseHelper().database;
      final accountId = await _insertBankAccount('AE Account');
      final intervalId = await _insertExpiredInterval(accountId);
      await _insertRealizedBankAccount(intervalId, accountId, 500.0);

      // Add a monthly auto-expense on day 15 for this account
      final aeId = await DatabaseHelper().genericInsert('autoexpenses', {
        'amount': 75.0,
        'accountId': accountId,
        'categoryId': -1,
        'description': 'Subscription',
        'bookingPrinciple': 'nthDayOfMonth',
        'bookingDay': 15,
        'principleMode': 'monthly',
        'receiverAccountId': -1,
        'moneyFlow': 0,
        'ratePayment': 0,
      });

      await backgroundJobs(dbHelper: DatabaseHelper());

      // The new interval should trigger an auto-expense booking
      final expenses = await db.query(
        'expenses',
        where: 'autoId = ? AND accountId = ?',
        whereArgs: [aeId, accountId],
      );
      expect(expenses, hasLength(1), reason: 'auto-expense must be booked for the new interval');
    });
  });

  group('checkNewInterval', () {
    test('returns true when the current interval is expired', () async {
      final accountId = await _insertBankAccount('Expired');
      await _insertExpiredInterval(accountId);

      final result = await checkNewInterval(dbHelper: DatabaseHelper());
      expect(result, isTrue);
    });

    test('returns false when the current interval is still valid', () async {
      final accountId = await _insertBankAccount('Valid');
      final now = DateTime.now();
      await DatabaseHelper().genericInsert('intervals', {
        'start': '${now.year}-${now.month.toString().padLeft(2, '0')}-01 00:00:00',
        'end': '${now.year}-${(now.month % 12 + 1).toString().padLeft(2, '0')}-01 00:00:00',
        'accountId': accountId,
      });

      final result = await checkNewInterval(dbHelper: DatabaseHelper());
      expect(result, isFalse);
    });
  });
}
