import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/category.dart';
import 'package:jne_household_app/models/category_budget_plain.dart';
import 'package:jne_household_app/models/expense.dart';
import 'package:jne_household_app/models/interval.dart';
import 'package:jne_household_app/models/realized_bankaccounts.dart';
import 'package:jne_household_app/models/autoexpenses.dart';
import 'package:jne_household_app/models/bankaccount.dart';
import 'package:jne_household_app/models/realized_category_budgets.dart';
import 'package:jne_household_app/models/reset_principles.dart';

Future<bool> checkNewInterval({DatabaseHelper ?dbHelper, List<AutoExpense> ?autoExpenses, List<BankAccount> ?bankAccounts}) async {
  final logger = Logger();
  logger.debug("Checking if new interval has started", tag: "background jobs");
  dbHelper ??= DatabaseHelper();
  final db = await dbHelper.database;
  DateTime today = DateTime.now();
  bankAccounts ??= await dbHelper.getBankAccounts(autoExpenses);
  autoExpenses ??= await dbHelper.getAutoExpenses(noMoneyFlow: false, dbObj: db);

  for (BankAccount ba in bankAccounts) {
    PBInterval lastInterval;
    try {
      lastInterval = await dbHelper.getIntervals(filter: "accountId = ?", filterArgs: [ba.id], order: "id DESC", onlyFirst: true, dbObj: db);
    } catch (e) {
      logger.warning("Could not load interval for account ${ba.id}, assuming new interval needed: $e", tag: "background jobs");
      return true;
    }
    if (today.isAfter(lastInterval.end)){
      return true;
    }
  }
  return false;
}

Future<bool> backgroundJobs({DatabaseHelper ?dbHelper, List<AutoExpense> ?autoExpenses, dynamic lastAutoExpenseRun, dynamic lastSavingRun, List<BankAccount> ?bankAccounts, dynamic lastCreditCardRefillRun, List<Category> ?categories}) async {
  final logger = Logger();
  logger.debug("Starting background jobs", tag: "background jobs");
  dbHelper ??= DatabaseHelper();
  final db = await dbHelper.database;
  bool didChanges = false;
  categories ??= await dbHelper.getCategories('*');
  autoExpenses ??= await dbHelper.getAutoExpenses(noMoneyFlow: false, dbObj: db);
  
  // check if new interval needs to be created
  DateTime today = DateTime.now();
  bankAccounts ??= await dbHelper.getBankAccounts(autoExpenses);

  final List<CategoryBudgetPlain> rawCategoryBudgets = await dbHelper.getCategoryBudgets(dbObj: db);

  for (BankAccount ba in bankAccounts) {
    PBInterval lastInterval;
    try {
      lastInterval = await dbHelper.getIntervals(filter: "accountId = ?", filterArgs: [ba.id], order: "id DESC", onlyFirst: true, dbObj: db);
    } catch (e) {
      logger.error(e.toString());
      logger.debug("Didn't find interval", tag: "background jobs");

      final today = DateTime.now();
      lastInterval = PBInterval({
        'start': DateTime(today.year, today.month),
        'end': DateTime(today.year, today.month + 1),
        'accountId': ba.id
      });
      await lastInterval.save();
      didChanges = true;
    }

    if (today.isAfter(lastInterval.end)){
      logger.debug("Creating new interval for bankaccount ${ba.id}", tag: "background jobs");
      final rawInterval = getMultipleRanges({'principle': ba.budgetResetPrinciple, 'day': ba.budgetResetDay}, 1, today, ba.id!)[0];
      PBInterval newInterval = PBInterval({
        'accountId': ba.id,
        'start': rawInterval.start,
        'end': rawInterval.end
      });
      await newInterval.save(dbObj: db);

      // process realized bank accounts
      final lastRealizedBankAccount = (await dbHelper.getRealizedBankAccounts(filter: "accountId = ?", filterArgs: [ba.id], order: "intervalId DESC", onlyFirst: true, dbObj: db)) as RealizedBankaccounts;
      double balance;
      List res = await dbHelper.genericSelect("expenses", filter: 'accountId = ? AND date > ? AND date < ?', filterArgs: [ba.id, formatForSqlite(lastInterval.start), formatForSqlite(lastInterval.end)], dbObj: db);
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
        balance = lastRealizedBankAccount.balance + (lastRealizedBankAccount.income - spent);
        await dbHelper.genericUpdate("bankaccounts", {
          "id": ba.id,
          "balance": balance
        }, dbObj: db);
      }

      final newBankAccount = RealizedBankaccounts({
        'intervalId': newInterval.id,
        'accountId': ba.id,
        'income': ba.income,
        'balance': balance
      });
      await newBankAccount.save(dbObj: db);

      Logger().debug("Created new realizedBankAccount with id ${newBankAccount.id}", tag: "background jobs");

      // process realizedCategory budgets for new interval
      for (CategoryBudgetPlain cat in rawCategoryBudgets.where((c) => c.accountId == ba.id)) {
        final newRealizedCategoryBudget = RealizedCategoryBudgets({
          "overrideBankAccount": cat.overrideBankAccount,
          "intervalId": newInterval.id,
          "accountId": ba.id,
          "budget": cat.budget,
          "categoryId": cat.categoryId
        });
        await newRealizedCategoryBudget.save();
      }
      
      // process autoExpenses for new interval
      final List<AutoExpense> autoExpenses = await dbHelper.getAutoExpenses(noMoneyFlow: false, dbObj: db);
      logger.debug("Processing ${autoExpenses.length} autoexpenses", tag: "background jobs");
      for (final AutoExpense ae in autoExpenses) {
        await ae.processUpcomingAE(newInterval, db, true);
      }

      didChanges = true;
    }
  }
  logger.debug("Finished background jobs", tag: "background jobs");
  return didChanges;
}

bool wasToday(String lastRun) {
  if (lastRun == "none") {
    return false;
  }
  DateTime lastRunDate = DateTime.parse(lastRun);
  DateTime now = DateTime.now();
  return lastRunDate.year == now.year && lastRunDate.month == now.month && lastRunDate.day == now.day;
}