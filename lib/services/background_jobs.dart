import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/category.dart';
import 'package:jne_household_app/models/expense.dart';
import 'package:jne_household_app/models/interval.dart';
import 'package:jne_household_app/models/realized_bankaccounts.dart';
import 'package:jne_household_app/models/autoexpenses.dart';
import 'package:jne_household_app/models/bankaccount.dart';
import 'package:jne_household_app/models/reset_principles.dart';

Future<void> backgroundJobs({DatabaseHelper ?dbHelper, List<AutoExpense> ?autoExpenses, dynamic lastAutoExpenseRun, dynamic lastSavingRun, List<BankAccount> ?bankAccounts, dynamic lastCreditCardRefillRun, List<Category> ?categories}) async {
  final logger = Logger();
  logger.debug("Starting background jobs", tag: "background jobs");
  dbHelper ??= DatabaseHelper();
  final db = await dbHelper.database;
  categories ??= await dbHelper.getCategories('*');
  
  // check if new interval needs to be created
  DateTime today = DateTime.now();
  bankAccounts ??= await dbHelper.getBankAccounts(autoExpenses);

  for (BankAccount ba in bankAccounts) {
    final PBInterval lastInterval = dbHelper.getIntervals(filter: "accountId = ?", filterArgs: [ba.id], order: "end DESC", onlyFirst: true, dbObj: db) as PBInterval;
    if (today.isAfter(lastInterval.end)){
      final rawInterval = getMultipleRanges({'principle': ba.budgetResetPrinciple, 'day': ba.budgetResetDay}, 1, today)[0];
      PBInterval newInterval = PBInterval({
        'accountId': ba.id,
        'start': rawInterval['start'],
        'end': rawInterval['end']
      });
      await newInterval.save(dbObj: db);

      // process realized bank accounts
      final lastRealizedBankAccount = dbHelper.getRealizedBankAccounts(filter: "id = ?", filterArgs: [ba.id], order: "intervalId DESC", onlyFirst: true, dbObj: db) as RealizedBankaccounts;
      double balance;
      List res = await dbHelper.genericSelect("expenses", filter: 'accountId = ? AND date > ? and date < ? and categoryId = ?', filterArgs: [ba.id, formatForSqlite(lastInterval.start), formatForSqlite(lastInterval.end), ], dbObj: db);
      List<Expense> expenses = res.map((e) => Expense(e)).toList();
      if (ba.isCreditCard) {
        for (Category cat in categories){
          double spent = expenses.where((e) => e.categoryId == cat.category.id).fold<double>(0.0, (previousValue, e) => previousValue + e.amount);
          if (spent != 0.0) {
            await dbHelper.insertRefill({
              "accountId": ba.refillsFrom,
              "creditAccountId": ba.id,
              "amount": spent,
              "categoryId": cat.category.id,
              "date": formatForSqlite(today)
            });

            await Expense({
              "accountId": ba.refillsFrom,
              "categoryId": cat.category.id,
              "amount": spent,
              "date": formatForSqlite(today),
              "description": I18n.translate("refillAcc", placeholders: {"name": ba.name}),
              "autoId": -2
            }).save();
          }
        }
        balance = 0;
      } else {
        double spent = expenses.fold<double>(0.0, (previousValue, e) => previousValue + e.amount);
        balance = lastRealizedBankAccount.balance + (ba.income - spent);
      }

      final newBankAccount = RealizedBankaccounts({
        'intervalId': newInterval.id,
        'accountId': ba.id,
        'income': ba.income,
        'balance': balance
      });
      await newBankAccount.save(dbObj: db);

      // process realizedCategory budgets for new interval
      
      // process autoExpenses for new interval
    }
  }
  logger.debug("Finished background jobs", tag: "background jobs");
}

bool wasToday(String lastRun) {
  if (lastRun == "none") {
    return false;
  }
  DateTime lastRunDate = DateTime.parse(lastRun);
  DateTime now = DateTime.now();
  return lastRunDate.year == now.year && lastRunDate.month == now.month && lastRunDate.day == now.day;
}