import 'package:flutter_test/flutter_test.dart';
import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/models/autoexpenses.dart';
import 'package:jne_household_app/models/interval.dart';

import 'helpers/test_database.dart';

// Fixed reference date: 2026-01-01 00:00:00
// Interval:             2026-01-01 → 2026-02-01
// Monthly AE day 15:    books on 2026-01-15 (after interval.start, within interval)
// processUpcomingAE with startIsInterval=true uses interval.start as "today"

final _intervalStart = DateTime(2026, 1, 1);
final _intervalEnd = DateTime(2026, 2, 1);

// 'nthDayOfMonth' with bookingDay=15 → books on the 15th of the current interval month.
// With startIsInterval=true "today" = interval.start = 2026-01-01,
// so bookingDate = 2026-01-15, which is strictly inside [2026-01-01, 2026-02-01].
AutoExpense _monthlyAE({int bookingDay = 15}) => AutoExpense(
      categoryId: -1,
      amount: 50.0,
      description: 'Test auto-expense',
      bookingPrinciple: 'nthDayOfMonth',
      bookingDay: bookingDay,
      principleMode: 'monthly',
      accountId: -1,
      moneyFlow: false,
      receiverAccountId: -1,
      ratePayment: false,
    );

Future<PBInterval> _savedInterval() async {
  final interval = PBInterval({
    'start': _intervalStart,
    'end': _intervalEnd,
    'accountId': -1,
  });
  await interval.save();
  return interval;
}

void main() {
  setUp(setUpTestDatabase);
  tearDown(tearDownTestDatabase);

  group('Auto-expense deduplication', () {
    test('monthly auto-expense is booked once when interval is created', () async {
      final db = await DatabaseHelper().database;
      final interval = await _savedInterval();
      final ae = _monthlyAE();
      ae.id = await DatabaseHelper().genericInsert('autoexpenses', ae.toMap());

      await ae.processUpcomingAE(interval, db, true);

      final expenses = await db.query('expenses', where: 'autoId = ?', whereArgs: [ae.id]);
      expect(expenses, hasLength(1), reason: 'exactly one expense expected');
    });

    test('calling processUpcomingAE twice does not create a duplicate', () async {
      final db = await DatabaseHelper().database;
      final interval = await _savedInterval();
      final ae = _monthlyAE();
      ae.id = await DatabaseHelper().genericInsert('autoexpenses', ae.toMap());

      await ae.processUpcomingAE(interval, db, true);
      await ae.processUpcomingAE(interval, db, true); // second call

      final expenses = await db.query('expenses', where: 'autoId = ?', whereArgs: [ae.id]);
      expect(expenses, hasLength(1), reason: 'second call must be a no-op — deduplication via realizedAutoexpenses');

      final realized = await db.query(
        'realizedAutoexpenses',
        where: 'intervalId = ? AND autoexpenseId = ?',
        whereArgs: [interval.id, ae.id],
      );
      expect(realized, hasLength(1), reason: 'realizedAutoexpenses must have exactly one entry');
    });

    test('different intervals each get their own booking', () async {
      final db = await DatabaseHelper().database;
      final ae = _monthlyAE();
      ae.id = await DatabaseHelper().genericInsert('autoexpenses', ae.toMap());

      // First interval: January 2026
      final jan = PBInterval({'start': DateTime(2026, 1, 1), 'end': DateTime(2026, 2, 1), 'accountId': -1});
      await jan.save();
      await ae.processUpcomingAE(jan, db, true);

      // Second interval: February 2026
      final feb = PBInterval({'start': DateTime(2026, 2, 1), 'end': DateTime(2026, 3, 1), 'accountId': -1});
      await feb.save();
      await ae.processUpcomingAE(feb, db, true);

      final expenses = await db.query('expenses', where: 'autoId = ?', whereArgs: [ae.id]);
      expect(expenses, hasLength(2), reason: 'one booking per interval expected');
    });

    test('auto-expense without matching date in interval is not booked', () async {
      final db = await DatabaseHelper().database;
      // Very short interval: only 2026-01-01 to 2026-01-03
      // Monthly AE on day 15 cannot fit in this window
      final shortInterval = PBInterval({
        'start': DateTime(2026, 1, 1),
        'end': DateTime(2026, 1, 3),
        'accountId': -1,
      });
      await shortInterval.save();

      final ae = _monthlyAE(bookingDay: 15);
      ae.id = await DatabaseHelper().genericInsert('autoexpenses', ae.toMap());

      await ae.processUpcomingAE(shortInterval, db, true);

      final expenses = await db.query('expenses', where: 'autoId = ?', whereArgs: [ae.id]);
      expect(expenses, isEmpty, reason: 'booking date outside interval — no expense expected');
    });
  });
}
