import 'package:flutter/material.dart';
import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/autoexpenses.dart';
import 'package:jne_household_app/models/bankaccount.dart';
import 'package:jne_household_app/models/expense.dart';
import 'package:jne_household_app/models/settings.dart';

/// Bank account CRUD, money-flow-once, and range selection.
mixin BankAccountMixin on ChangeNotifier {
  // ── State accessors ───────────────────────────────────────────────────────
  Settings get settings;
  double get totalBudget;
  set totalBudget(double v);
  List<BankAccount> get bankAccounts;
  List<AutoExpense> get moneyFlows;
  int get range;
  set range(int v);
  bool get sharedDbConnected;
  bool get syncInProgress;

  // ── Methods called on BudgetState / other mixins ──────────────────────────
  Future<void> loadBudgets({int? overrideRange});
  Future<void> loadRanges();
  Future<void> loadBankAccounts();
  Future<void> loadMoneyFlows();
  Future<void> saveWidgetData(String id, dynamic data);
  Future<void> syncSharedDb({bool manual = false, bool changeKey = false});

  // ── Implementation ────────────────────────────────────────────────────────

  Future<void> updateRangeSelection(int index) async {
    range = index;
    await loadBankAccounts();
    await loadBudgets(overrideRange: index);
    notifyListeners();
  }

  Future<void> moneyFlowOnce(
    int spenderId,
    String spenderName,
    int receiverId,
    String receiverName,
    double amount,
  ) async {
    final description = "$spenderName ${I18n.translate("to")} $receiverName";
    final date = formatForSqlite(DateTime.now());

    await Expense({"description": description, "categoryId": -1, "amount": amount, "accountId": spenderId, "date": date}).save();
    await Expense({"description": description, "categoryId": -1, "amount": -amount, "accountId": receiverId, "date": date}).save();

    await loadBudgets();
    notifyListeners();
    if (sharedDbConnected && !syncInProgress) syncSharedDb();
  }

  Future<void> addBankAccount(Map<String, dynamic> acc) async {
    acc['id'] = await DatabaseHelper().insertBankAccount(acc);
    final newAcc = BankAccount(
      id: acc['id'],
      name: acc['name'],
      description: acc['description'],
      balance: acc['balance'],
      income: acc['income'],
      budgetResetPrinciple: acc['budgetResetPrinciple'],
      budgetResetDay: acc['budgetResetDay'],
      lastSavingRun: "none",
      transfers: 0,
      isCreditCard: acc['isCreditCard'] == 1,
      refillsFrom: acc['refillsFrom'],
      refillPrincipleMode: acc['refillPrincipleMode'],
    );
    await newAcc.save();
    bankAccounts.add(newAcc);

    final ret = await DatabaseHelper().getTotalBudget(settings.filterBudget);
    totalBudget = ((ret['totalIncome'] as num? ?? 0) + (settings.useBalance ? (ret['totalBalance'] as num? ?? 0) : 0)).toDouble();

    await loadRanges();
    await loadBankAccounts();
    await loadBudgets();
    notifyListeners();
    saveWidgetData("totalBudget", totalBudget);
    if (sharedDbConnected && !syncInProgress) syncSharedDb();
  }

  Future<void> updateOrDeleteBankAccount(
      Map<String, dynamic> acc, int id, bool delete) async {
    final targetAccount = BankAccount(
      id: id,
      name: acc['name'],
      description: acc['description'],
      balance: acc['balance'],
      income: acc['income'],
      budgetResetPrinciple: acc['budgetResetPrinciple'],
      budgetResetDay: acc['budgetResetDay'],
      lastSavingRun: acc['lastSavingRun'],
      transfers: getTransfers(id),
      isCreditCard: acc['isCreditCard'] == 1,
      refillsFrom: acc['refillsFrom'],
      refillPrincipleMode: acc['refillPrincipleMode'],
    );

    final index = bankAccounts.indexWhere((a) => a.id == targetAccount.id);
    if (delete && targetAccount.id != -1) {
      await DatabaseHelper().deleteBankAccount(targetAccount.id!);
      if (index != -1) bankAccounts.removeAt(index);
      if (settings.filterBudget == targetAccount.id.toString()) settings.filterBudget = "*";
      targetAccount.delete();
    } else {
      await targetAccount.save();
      if (index != -1) bankAccounts[index] = targetAccount;
    }

    final ret = await DatabaseHelper().getTotalBudget(settings.filterBudget);
    totalBudget = ((ret['totalIncome'] as num? ?? 0) + (settings.useBalance ? (ret['totalBalance'] as num? ?? 0) : 0)).toDouble();

    await loadMoneyFlows();
    await loadRanges();        // must come before loadBankAccounts (which needs budgetRanges)
    await loadBankAccounts();
    await loadBudgets();
    notifyListeners();
    saveWidgetData("totalBudget", totalBudget);
    if (sharedDbConnected && !syncInProgress) syncSharedDb();
  }

  double getTransfers(int accountId) {
    return moneyFlows
        .where((mf) => mf.receiverAccountId == accountId)
        .fold(0, (sum, mf) => sum + mf.amount);
  }
}
