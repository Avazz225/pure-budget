import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/autoexpenses.dart';
import 'package:jne_household_app/models/booking_principles.dart';
import 'package:jne_household_app/models/expense.dart';
import 'package:jne_household_app/models/interval.dart';
import 'package:jne_household_app/models/reset_principles.dart';
import 'package:sqflite/sqflite.dart';

Future<void> createBookings(List<AutoExpense> autoExpenses, bool updateSettings, PBInterval interval, Database dbObj, bool startIsInterval) async {
  DatabaseHelper db = DatabaseHelper();
  DateTime helper;
  DateTime today;
  Logger logger = Logger();
  if (startIsInterval) {
    today = interval.start;
  } else {
    helper = DateTime.now();
    today = DateTime(helper.year, helper.month, helper.day, 0, 0, 0);
  }

  logger.debug("Reference day is: $today", tag: "autoBooking");

  for (AutoExpense autoExpense in autoExpenses){
    logger.debug("Processing ae with id ${autoExpense.id}", tag: "autoBooking");
    List existentBookings = await db.genericSelect("realizedAutoexpenses", filter: "intervalId = ? AND autoexpenseId = ?", filterArgs: [interval.id, autoExpense.id]);
    if (existentBookings.isEmpty){
      logger.debug("Found no existing booking. Checking...", tag: "autoBooking");
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
        int i = 0;
        while (exp.date.isBefore(today)) {
          exp.date = bookingDate(today.year, today.month + i, autoExpense.bookingDay, autoExpense.bookingPrinciple);
          i++;
        }

        if (inRange(interval, exp.date) && today.isBefore(exp.date)){
          await exp.save(dbObj: dbObj);
          didExecute = true;
        }
      } else if (autoExpense.principleMode == "daily"){
        for (int i = 0; i <= 33; i++) {
          exp.date = today.add(Duration(days: i));
          if (inRange(interval, exp.date) && today.isBefore(exp.date)){
            await exp.save(dbObj: dbObj);
            didExecute = true;
          }
        } 
      } else if (autoExpense.principleMode == "weekly"){
        int weekday = today.weekday;
        int diff = availableWeekDays.indexOf(autoExpense.bookingPrinciple) + 1 - weekday;
        for (int i = 0; i <= 8; i++) {
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
        logger.debug("Successfully processed autoexpense with id ${autoExpense.id}", tag: "autoBooking");
        logger.debug("Date: ${exp.date}, id: ${exp.id}");
        await db.genericInsert("realizedAutoexpenses", {"intervalId": interval.id!, "autoexpenseId": autoExpense.id!, "expenseId": exp.id}, dbObj: dbObj);
      } else if (kDebugMode) {
        logger.debug("Didn't process autoexpense", tag: "autoBooking");
        logger.debug("Date: ${exp.date}");
        logger.debug("Reference date: $today");
        logger.debug("Interval data: ${interval.toMap()}");
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