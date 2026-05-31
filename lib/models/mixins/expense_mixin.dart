import 'package:flutter/material.dart';
import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/models/autoexpenses.dart';
import 'package:jne_household_app/models/expense.dart';
import 'package:jne_household_app/models/interval.dart';
import 'package:jne_household_app/models/settings.dart';
import 'package:jne_household_app/services/statistics_repository.dart';

/// Expense CRUD, statistics queries, and cross-entity item moves.
mixin ExpenseMixin on ChangeNotifier {
  // ── State accessors ────��─────────────────────────────────��────────────────
  Settings get settings;
  List<PBInterval> get budgetRanges;
  int get range;
  Map<String, List<Map<String, dynamic>>> get statistics;
  set statistics(Map<String, List<Map<String, dynamic>>> v);
  List<AutoExpense> get autoExpenses;
  bool get sharedDbConnected;
  bool get syncInProgress;

  // ── Methods called on BudgetState / other mixins ���─────────────────────────
  Future<void> loadBudgets({int? overrideRange});
  Future<void> loadRanges();
  Future<void> syncSharedDb({bool manual = false, bool changeKey = false});

  // ── Implementation ─────────────��──────────────────────────────────────────

  Future<void> saveExpense(Expense expense) async {
    expense.save();
    await loadRanges();
    await loadBudgets();
    notifyListeners();
    if (sharedDbConnected && !syncInProgress) syncSharedDb();
  }

  Future<void> deleteExpense(Expense expense) async {
    expense.delete();
    await loadRanges();
    await loadBudgets();
    notifyListeners();
    if (sharedDbConnected && !syncInProgress) syncSharedDb();
  }

  Future<void> getStatistics(String type) async {
    if (budgetRanges.isEmpty) {
      statistics = {"data": []};
      return;
    }
    final repo = StatisticsRepository();
    final currentRange = budgetRanges[range.clamp(0, budgetRanges.length - 1)];
    switch (type) {
      case "history_months":
        statistics = {
          "data": await repo.lastMonthsTotal(budgetRanges, settings.filterBudget),
          "totalBudget": await repo.lastTotalBudgets(budgetRanges, settings.filterBudget),
        };
      case "month_by_cat":
        statistics = {
          "data": await repo.statisticMonthTotalByCat(currentRange, settings.filterBudget),
        };
      case "history_by_cat":
        statistics = {
          "data": await repo.lastMonthsByCat(budgetRanges, settings.filterBudget),
          "totalBudget": await repo.lastMonthsCatBudget(budgetRanges, settings.filterBudget),
        };
      default: // month_total
        statistics = {
          "data": await repo.statisticMonthTotal(currentRange, settings.filterBudget),
        };
    }
  }

  Future<void> moveItem(
      int id, int newCatId, int newAccountId, bool autoExpense) async {
    if (!autoExpense) {
      await DatabaseHelper().moveExpense(id, newCatId, newAccountId);
    } else {
      await DatabaseHelper().moveAutoExpense(id, newCatId, newAccountId);
      final match = autoExpenses.where((aExp) => aExp.id == id);
      if (match.isNotEmpty) match.first.categoryId = newCatId;
    }
    await loadRanges();
    await loadBudgets();
    notifyListeners();
    if (sharedDbConnected && !syncInProgress) syncSharedDb();
  }
}
