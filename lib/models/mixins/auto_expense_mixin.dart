import 'package:flutter/material.dart';
import 'package:jne_household_app/models/autoexpenses.dart';
import 'package:jne_household_app/models/interval.dart';

/// Recurring-expense (autoexpense) CRUD, including rate-payment variants.
mixin AutoExpenseMixin on ChangeNotifier {
  // ── State accessors ───────────────────────────────────────────────────────
  List<PBInterval> get budgetRanges;
  List<AutoExpense> get autoExpenses;
  List<AutoExpense> get moneyFlows;
  bool get sharedDbConnected;
  bool get syncInProgress;

  // ── Methods called on BudgetState / other mixins ──────────────────────────
  Future<void> loadBudgets({int? overrideRange});
  Future<void> loadRanges();
  Future<void> loadBankAccounts();
  Future<void> syncSharedDb({bool manual = false, bool changeKey = false});

  // ── Implementation ────────────────────────────────────────────────────────

  Future<void> addRateAutoExpense(AutoExpense newAE) async {
    if (budgetRanges.isEmpty) return;
    await newAE.save(budgetRanges.first);
    autoExpenses.add(newAE);
    await loadBudgets();
    notifyListeners();
    if (sharedDbConnected && !syncInProgress) syncSharedDb();
  }

  Future<void> updateOrDeleteRateAutoExpense(AutoExpense newAE) async {
    if (newAE.amount == 0.0) {
      newAE.delete();
      autoExpenses.removeWhere((exp) => exp.id == newAE.id);
    } else {
      if (budgetRanges.isEmpty) return;
      newAE.save(budgetRanges.first);
      final index = autoExpenses.indexWhere((exp) => exp.id == newAE.id);
      if (index != -1) autoExpenses[index] = newAE;
    }
    await loadBudgets();
    notifyListeners();
    if (sharedDbConnected && !syncInProgress) syncSharedDb();
  }

  Future<void> addAutoExpense(AutoExpense autoExp) async {
    if (budgetRanges.isEmpty) return;
    await autoExp.save(budgetRanges.first);
    if (!autoExp.moneyFlow) {
      autoExpenses.add(autoExp);
    } else {
      moneyFlows.add(autoExp);
      await loadBankAccounts();
    }
    await loadBudgets();
    notifyListeners();
    if (sharedDbConnected && !syncInProgress) syncSharedDb();
  }

  Future<void> updateOrDeleteAutoExpense(AutoExpense autoExp) async {
    int index = autoExp.moneyFlow
        ? moneyFlows.indexWhere((e) => e.id == autoExp.id)
        : autoExpenses.indexWhere((e) => e.id == autoExp.id);

    if (autoExp.amount == 0.0) {
      await autoExp.delete();
      if (index != -1) {
        if (!autoExp.moneyFlow) {
          autoExpenses.removeAt(index);
        } else {
          moneyFlows.removeAt(index);
          await loadBankAccounts();
        }
      }
    } else {
      if (budgetRanges.isEmpty) return;
      await autoExp.save(budgetRanges.first);
      if (index != -1) {
        if (!autoExp.moneyFlow) {
          autoExpenses[index] = autoExp;
        } else {
          moneyFlows[index] = autoExp;
          await loadBankAccounts();
        }
      }
    }
    await loadRanges();
    await loadBudgets();
    notifyListeners();
    if (sharedDbConnected && !syncInProgress) syncSharedDb();
  }
}
