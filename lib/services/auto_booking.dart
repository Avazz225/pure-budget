import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/models/autoexpenses.dart';
import 'package:jne_household_app/models/booking_principles.dart';
import 'package:jne_household_app/models/expense.dart';
import 'package:jne_household_app/models/interval.dart';
import 'package:jne_household_app/models/reset_principles.dart';
import 'package:sqflite/sqflite.dart';

Future<void> createBookings(List<AutoExpense> autoExpenses, bool updateSettings, PBInterval interval, Database dbObj, bool startIsInterval) async {
  DatabaseHelper db = DatabaseHelper();
  DateTime helper;
  if (startIsInterval) {
    helper = interval.start.subtract(const Duration(days: 1));
  } else {
    helper = DateTime.now().subtract(const Duration(days: 1));
  }

  final today = DateTime(helper.year, helper.month, helper.day, 23, 59, 59);

  for (AutoExpense autoExpense in autoExpenses){
    List existentBookings = await db.genericSelect("realizedAutoexpenses", filter: "intervalId = ? AND autoexpenseId = ?", filterArgs: [interval.id, autoExpense.id]);
    if (existentBookings.isEmpty){
      bool didExecute = false;
      Expense exp = Expense({
        "autoId": autoExpense.id!,
        "auto": 1,
        "description": autoExpense.description,
        "categoryId": autoExpense.categoryId,
        "amount": autoExpense.amount,
        "accountId": autoExpense.accountId,
        "date": formatForSqlite(today)
      });

      if (autoExpense.principleMode == "monthly"){
        exp.date = bookingDate(today.year, today.month, autoExpense.bookingDay, autoExpense.bookingPrinciple);
        if (inRange(interval, exp.date) && today.isBefore(exp.date)){
          await exp.save(dbObj: dbObj);
          didExecute = true;
        }
      } else if (autoExpense.principleMode == "daily"){
        for (int i = 0; i <= 31; i++) {
          exp.date = today.add(Duration(days: i));
          if (inRange(interval, exp.date) && today.isBefore(exp.date)){
            await exp.save(dbObj: dbObj);
            didExecute = true;
          }
        } 
      } else if (autoExpense.principleMode == "weekly"){
        int weekday = today.weekday;
        int diff = availableWeekDays.indexOf(autoExpense.bookingPrinciple) + 1 - weekday;
        for (int i = 0; i <= 5; i++) {
          exp.date = today.add(Duration(days: diff + (i * 7)));
          if (inRange(interval, exp.date) && today.isBefore(exp.date)){
            await exp.save(dbObj: dbObj);
            didExecute = true;
          }
        }
      } else if (autoExpense.principleMode == "yearly"){
        DateTime target = DateTime.parse(autoExpense.bookingPrinciple);
        exp.date = DateTime(today.year, target.month, target.day);
        if (inRange(interval, exp.date) && today.isBefore(exp.date)){
          await exp.save(dbObj: dbObj);
          didExecute = true;
        }
      }
      if (didExecute){
        await db.genericInsert("realizedAutoexpenses", {"intervalId": interval.id!, "autoexpenseId": autoExpense.id!, "expenseId": exp.id}, dbObj: dbObj);
      }
    }
  }

  if (updateSettings){
    final settings = await db.getSettings();
    settings.lastAutoExpenseRun = formatForSqlite(today);
    await settings.save();
  }
}

bool inRange(PBInterval interval, DateTime date){
  return date.isAfter(interval.start) && date.isBefore(interval.end);
}

DateTime bookingDate(int targetYear, int targetMonth, int day, String principle) {
  targetYear += (targetMonth - 1) ~/ 12;
  targetMonth = ((targetMonth - 1) % 12) + 1;

  DateTime result = getDateForPrinciple(principle, day, targetYear, targetMonth).add(const Duration(minutes: 1));
  return result;
}