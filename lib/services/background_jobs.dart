import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/helper/auto_booking.dart';
import 'package:jne_household_app/models/autoexpenses.dart';
import 'package:jne_household_app/models/bankaccount.dart';
import 'package:jne_household_app/models/reset_principles.dart';

Future<void> backgroundJobs({DatabaseHelper ?dbHelper, List<AutoExpense> ?autoExpenses, dynamic lastAutoExpenseRun, dynamic lastSavingRun}) async {
  dbHelper ??= DatabaseHelper();
  autoExpenses ??= await dbHelper.getAutoExpenses(noMoneyFlow: false);
  
  if (lastAutoExpenseRun == null) {
    final settings = await dbHelper.getSettings();
    lastAutoExpenseRun = settings['lastAutoExpenseRun'];
  }
  await processAutoExpenses(lastAutoExpenseRun, autoExpenses);

  if (lastSavingRun == null) {
    final settings = await dbHelper.getSettings();
    lastSavingRun = settings['lastSavingRun'];
    lastSavingRun ??= DateTime.now().toString();
  }

  await processBalanceCalculation(dbHelper, lastSavingRun);
}

Future<void> processBalanceCalculation(DatabaseHelper dbHelper, String lastSavingRun) async {
  List<BankAccount> accounts = await dbHelper.getBankAccounts(await dbHelper.getAutoExpenses());

  for (BankAccount account in accounts) {
    List<Map<String, DateTime>> ranges = getMultipleRanges({"principle": account.budgetResetPrinciple, "day": account.budgetResetDay}, 2, DateTime(2000));
    if (lastSavingRun != "none") {
      if (!dateBeforRange(DateTime.parse(lastSavingRun), ranges[0]['start']!)) {
        return;
      }
    }
    await dbHelper.processSavings(account.id, ranges[1]);
  }
  dbHelper.updateSettings("lastSavingRun", formatForSqlite(DateTime.now()));
} 