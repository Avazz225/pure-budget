import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/models/autoexpenses.dart';
import 'package:jne_household_app/models/booking_principles.dart';
import 'package:jne_household_app/models/expense.dart';
import 'package:jne_household_app/models/reset_principles.dart';
const int futureMonts = 3;
const int futureDays = 90;
const int futureWeeks = 12;
const int futureYears = 2;


Future<bool> processAutoExpenses(String lastAutoExpenseRun, List<AutoExpense> autoExpenses, {bool updateSettings = true}) async {
  if (lastAutoExpenseRun != "none") {
    if (_isLastMonthOrOlder(lastAutoExpenseRun)) {
      _createBookings(autoExpenses, updateSettings);
    } else {
      return false;
    }
  } else {
    _createBookings(autoExpenses, updateSettings);
  }

  return true;
}

Future<void> processDeleteAutoExpenses(AutoExpense autoExpense) async {
  DatabaseHelper db = DatabaseHelper();
  await db.deleteAutoExpRealizations(autoExpense.id!, formatForSqlite(DateTime.now()));
}

Future<void> processUpdateAutoExpenses(AutoExpense autoExpense) async {
  await processDeleteAutoExpenses(autoExpense);
  await _createBookings([autoExpense], false);
}

DateTime bookingDate(int targetYear, int targetMonth, int offset, int day, String principle) {
  targetMonth += offset;
  targetYear += (targetMonth - 1) ~/ 12;
  targetMonth = ((targetMonth - 1) % 12) + 1;

  DateTime result = getDateForPrinciple(principle, day, targetYear, targetMonth).add(const Duration(minutes: 1));
  return result;
}

Future<void> _createBookings(List<AutoExpense> autoExpenses, updateSettings) async {
  DatabaseHelper db = DatabaseHelper();
  final today = DateTime.now();

  for (AutoExpense autoExpense in autoExpenses){
    if (!autoExpense.ratePayment){
      Expense exp = Expense({
        "autoId": autoExpense.id!,
        "auto": 1,
        "description": autoExpense.description,
        "categoryId": autoExpense.categoryId,
        "amount": autoExpense.amount,
        "accountId": autoExpense.accountId
      });

      if (autoExpense.principleMode == "monthly"){
        for (int i = 0; i <= futureMonts; i++) {
          exp.date = bookingDate(today.year, today.month, i, autoExpense.bookingDay, autoExpense.bookingPrinciple);
          if (today.isBefore(exp.date) && !(await db.checkAutoExpense(autoExpense.id!, autoExpense.categoryId, exp.date))){
            await exp.save();
          }
        }
      } else if (autoExpense.principleMode == "daily"){
        for (int i = 0; i <= futureDays; i++) {
          exp.date = today.add(Duration(days: i));
          if (today.isBefore(exp.date) && !(await db.checkAutoExpense(autoExpense.id!, autoExpense.categoryId, exp.date))){
            await exp.save();
          }
        } 
      } else if (autoExpense.principleMode == "weekly"){
        int weekday = today.weekday;
        int diff = availableWeekDays.indexOf(autoExpense.bookingPrinciple) + 1 - weekday;
        for (int i = 0; i <= futureWeeks; i++) {
          exp.date = today.add(Duration(days: diff + (i * 7)));
          if (today.isBefore(exp.date) && !(await db.checkAutoExpense(autoExpense.id!, autoExpense.categoryId, exp.date))){
            await exp.save();
          }
        }
      } else if (autoExpense.principleMode == "yearly"){
        DateTime target = DateTime.parse(autoExpense.bookingPrinciple);
        for (int i = 0; i <= futureYears; i++) {
          exp.date = DateTime(today.year + i, target.month, target.day);
          if (today.isBefore(exp.date) && !(await db.checkAutoExpense(autoExpense.id!, autoExpense.categoryId, exp.date))){
            await exp.save();
          }
        }
      }
    }
  }
  if (updateSettings){
    final settings = await db.getSettings();
    settings.lastAutoExpenseRun = formatForSqlite(today);
    await settings.save();
  }
}

Future<void> processUpdateRates(AutoExpense autoExpense) async {
  await processDeleteAutoExpenses(autoExpense);
  await processCreateRates(autoExpense);
}

Future<void> processCreateRates(AutoExpense autoExpense) async {
  DatabaseHelper db = DatabaseHelper();
  final today = DateTime.now();
  int addition = 0;

  Expense exp = Expense({
    "autoId": autoExpense.id!,
    "auto": 1,
    "description": autoExpense.description,
    "categoryId": autoExpense.categoryId,
    "amount": autoExpense.amount,
    "accountId": autoExpense.accountId
  });

  int weekday = today.weekday;
  int diff = availableWeekDays.indexOf(autoExpense.bookingPrinciple) + 1 - weekday;
  for (int i = 0; i < autoExpense.rateCount!; i++) {

    if (i == 0){
      switch (autoExpense.principleMode) {
        case "monthly":
          exp.date = bookingDate(today.year, today.month, i, autoExpense.bookingDay, autoExpense.bookingPrinciple);
        case "daily":
          exp.date = today.add(Duration(days: i));
        case "weekly":
          exp.date = today.add(Duration(days: diff + (i * 7)));
        case "yearly":
          DateTime target = DateTime.parse(autoExpense.bookingPrinciple);
          exp.date = DateTime(today.year + i, target.month, target.day);
      }

      if (!(today.isBefore(exp.date)) && !(await db.checkAutoExpense(autoExpense.id!, autoExpense.categoryId, exp.date))) {
        addition = 1;
      }
    }

    switch (autoExpense.principleMode) {
      case "monthly":
        exp.date = bookingDate(today.year, today.month, i + addition, autoExpense.bookingDay, autoExpense.bookingPrinciple);
      case "daily":
        exp.date = today.add(Duration(days: i + addition));
      case "weekly":
        exp.date = today.add(Duration(days: diff + ((i + addition) * 7)));
      case "yearly":
        DateTime target = DateTime.parse(autoExpense.bookingPrinciple);
        exp.date = DateTime(today.year + i + addition, target.month, target.day);
    }
    
    if (i == 0 && autoExpense.firstRateAmount != null) {

      Expense newExp = Expense({
        ...exp.toMap(),
        "amount": autoExpense.firstRateAmount
      });
      if (today.isBefore(newExp.date) && !(await db.checkAutoExpense(autoExpense.id!, autoExpense.categoryId, newExp.date))){
        await newExp.save();
      }
    } else if (i == (autoExpense.rateCount! - 1) && autoExpense.lastRateAmount != null) {
      Expense newExp = Expense({
        ...exp.toMap(),
        "amount": autoExpense.lastRateAmount
      });
      
      if (today.isBefore(newExp.date) && !(await db.checkAutoExpense(autoExpense.id!, autoExpense.categoryId, newExp.date))){
        await newExp.save();
      }
    } else {
      if (today.isBefore(exp.date) && !(await db.checkAutoExpense(autoExpense.id!, autoExpense.categoryId, exp.date))){
        await exp.save();
      }
    }
  }
}


bool _isLastMonthOrOlder(String dateString) {
  DateTime parsedDate = DateTime.parse(dateString);
  DateTime now = DateTime.now();
  DateTime firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);

  return parsedDate.isBefore(firstDayOfCurrentMonth);
}