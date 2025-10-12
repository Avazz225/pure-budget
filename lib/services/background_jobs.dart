import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/category.dart';
import 'package:jne_household_app/services/auto_booking.dart';
import 'package:jne_household_app/models/autoexpenses.dart';
import 'package:jne_household_app/models/bankaccount.dart';
import 'package:jne_household_app/models/reset_principles.dart';

Future<void> backgroundJobs({DatabaseHelper ?dbHelper, List<AutoExpense> ?autoExpenses, dynamic lastAutoExpenseRun, dynamic lastSavingRun, List<BankAccount> ?bankAccounts, dynamic lastCreditCardRefillRun, List<Category> ?categories}) async {
  final logger = Logger();
  logger.debug("Starting background jobs", tag: "background jobs");
  dbHelper ??= DatabaseHelper();
  autoExpenses ??= await dbHelper.getAutoExpenses(noMoneyFlow: false);
  
  if (lastAutoExpenseRun == null || lastCreditCardRefillRun == null || lastSavingRun == null) {
    final settings = await dbHelper.getSettings();

    lastAutoExpenseRun ??= settings['lastAutoExpenseRun'];
    lastCreditCardRefillRun ??= settings['lastCreditCardRefillRun'];
    lastSavingRun ??= settings['lastSavingRun'];
  }

  if (!wasToday(lastAutoExpenseRun)) {
    await processAutoExpenses(lastAutoExpenseRun, autoExpenses);
    await dbHelper.updateSettings("lastAutoExpenseRun", formatForSqlite(DateTime.now()));
  } else {
    logger.debug("Skipping auto expense processing, already done today", tag: "background jobs");
  }

  if(!wasToday(lastCreditCardRefillRun)) {
    bankAccounts ??= await dbHelper.getBankAccounts(autoExpenses);
    categories ??= await dbHelper.getCategories("*");
    await processCreditCardRefills(dbHelper, bankAccounts, categories, lastCreditCardRefillRun);
    await dbHelper.updateSettings("lastCreditCardRefillRun", formatForSqlite(DateTime.now()));
  } else {
    logger.debug("Skipping credit card refill processing, already done today", tag: "background jobs");
  }

  if (!wasToday(lastSavingRun)) {
    await processBalanceCalculation(dbHelper, lastSavingRun, logger);
    await dbHelper.updateSettings("lastSavingRun", formatForSqlite(DateTime.now()));
  } else {
    logger.debug("Skipping balance calculation, already done today", tag: "background jobs");
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

Future<void> processBalanceCalculation(DatabaseHelper dbHelper, String lastSavingRun, Logger logger) async {
  List<BankAccount> accounts = await dbHelper.getBankAccounts(await dbHelper.getAutoExpenses());

  for (BankAccount account in accounts) {
    if (!account.isCreditCard) {
      logger.debug("Processing balance calculation for ${account.name}", tag: "balance calculation");
      List<Map<String, DateTime>> ranges = getMultipleRanges({"principle": account.budgetResetPrinciple, "day": account.budgetResetDay}, 2, DateTime(2000));
      if (lastSavingRun != "none") {
        if (!dateBeforeRange(DateTime.parse(lastSavingRun), ranges[0]['start']!)) {
          return;
        }
      }
      await dbHelper.processSavings(account.id, ranges[1], logger);
    }
  }
} 

Future<void> processCreditCardRefills(DatabaseHelper dbHelper, List<BankAccount> bankAccounts, List<Category> categories, dynamic lastCreditCardRefillRun) async {
  final logger = Logger();
  for (BankAccount account in bankAccounts) {
    if (account.isCreditCard) {
      logger.debug("Processing credit card refills for account ${account.name}", tag: "refill job");
      for (Category cat in categories) {
        Map<String, dynamic> lastRefill = await dbHelper.getLastRefill(account.id, cat.id);
        Map<String, dynamic> result = await dbHelper.getSpentForLastMonth(account.id.toString(), account, cat.id);
        double spent = result['result'] as double;
        Map<String, DateTime> range = result['range'] as Map<String, DateTime>;

        if (lastRefill.isNotEmpty) {
          DateTime lastRefillDate = DateTime.parse(lastRefill['date']);
          if (!dateBeforeRange(lastRefillDate, range['start']!)) {
            logger.debug("Skipping refill", tag: "refill job");
            continue;
          }
        }

        if (spent != 0.0) {
          await dbHelper.insertRefill({
            "accountId": account.refillsFrom,
            "creditAccountId": account.id,
            "amount": spent,
            "categoryId": cat.id,
            "date": formatForSqlite(DateTime.now())
          });
          await dbHelper.insertExpense({
            "accountId": account.refillsFrom,
            "categoryId": cat.id,
            "amount": spent,
            "date": formatForSqlite(DateTime.now()),
            "description": I18n.translate("refillAcc", placeholders: {"name": account.name}),
            "autoId": -2
          });

          logger.debug("Executed refill for account ${account.name} -> ${cat.name}, value $spent", tag: "refill job");
        } else {
          logger.debug("No refill needed for cat ${cat.name}", tag: "refill job");
        }
      }
    }
  }
}