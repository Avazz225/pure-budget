import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:home_widget/home_widget.dart';
import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/keys.dart';
import 'package:jne_household_app/models/interval.dart';
import 'package:jne_household_app/models/settings.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/autoexpenses.dart';
import 'package:jne_household_app/models/bankaccount.dart';
import 'package:jne_household_app/models/category.dart';
import 'package:jne_household_app/models/category_budget.dart';
import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/free_restrictions.dart';
import 'package:jne_household_app/models/mixins/auto_expense_mixin.dart';
import 'package:jne_household_app/models/mixins/bank_account_mixin.dart';
import 'package:jne_household_app/models/mixins/category_mixin.dart';
import 'package:jne_household_app/models/mixins/expense_mixin.dart';
import 'package:jne_household_app/models/mixins/settings_mutations_mixin.dart';
import 'package:jne_household_app/models/mixins/sync_mixin.dart';
import 'package:jne_household_app/shared_database/shared_database.dart';

class BudgetState extends ChangeNotifier
    with SyncMixin, SettingsMutationsMixin, BankAccountMixin, AutoExpenseMixin, CategoryMixin, ExpenseMixin {
  // Fields that satisfy abstract getter contracts declared in the mixins
  @override double totalBudget;
  @override double notAssignedBudget;
  Map<String, dynamic> resetInfo;
  @override List<CategoryBudget> categories;
  @override List<Category> rawCategories;
  @override List<AutoExpense> autoExpenses;
  @override List<AutoExpense> moneyFlows;
  @override List<PBInterval> budgetRanges;
  @override List<BankAccount> bankAccounts;
  @override int range;
  @override Map<String, List<Map<String, dynamic>>> statistics;
  int selectedStatisticIndex;
  bool isSetupComplete;
  @override bool sharedDbConnected;
  @override SharedDatabase sharedDb;
  @override bool syncInProgress;
  @override Settings settings;

  BudgetState._({
    required this.totalBudget,
    required this.rawCategories,
    required this.categories,
    required this.notAssignedBudget,
    required this.autoExpenses,
    required this.budgetRanges,
    required this.range,
    required this.statistics,
    required this.selectedStatisticIndex,
    required this.isSetupComplete,
    required this.bankAccounts,
    required this.moneyFlows,
    required this.sharedDbConnected,
    required this.sharedDb,
    required this.syncInProgress,
    required this.resetInfo,
    required this.settings
  });

  factory BudgetState({
    required double totalBudget,
    required List<Category> rawCategories,
    required Map<String, dynamic> resetInfo,
    required List<AutoExpense> autoExpenses,
    required bool isSetupComplete,
    required List<BankAccount> bankAccounts,
    required List<AutoExpense> moneyFlows,
    required Settings settings
  }) {
    return BudgetState._(
      totalBudget: totalBudget,
      rawCategories: rawCategories,
      categories: [],
      budgetRanges: [],
      range: 0,
      notAssignedBudget: totalBudget,
      autoExpenses: autoExpenses,
      statistics: {},
      selectedStatisticIndex: 0, 
      isSetupComplete: isSetupComplete,
      bankAccounts: bankAccounts,
      moneyFlows: moneyFlows,
      sharedDbConnected: false,
      sharedDb: SharedDatabase(DatabaseHelper()),
      syncInProgress: false,
      resetInfo: resetInfo,
      settings: settings
    );
  }

  static Future<BudgetState> initialize({
    required double totalBudget,
    required List<Category> rawCategories,
    required Map<String, dynamic> resetInfo,
    required List<AutoExpense> autoExpenses,
    required bool isSetupComplete,
    required List<BankAccount> bankAccounts,
    required List<AutoExpense> moneyFlows,
    required Settings settings
  }) async {
    final instance = BudgetState(
      totalBudget: totalBudget,
      rawCategories: rawCategories,
      resetInfo: resetInfo,
      autoExpenses: autoExpenses,
      isSetupComplete: isSetupComplete,
      bankAccounts: bankAccounts,
      moneyFlows: moneyFlows,
      settings: settings
    );

    await instance.sharedDb.initialize();

    instance.saveWidgetData("totalBudget", totalBudget);
    instance.saveWidgetData("currency", settings.currency);
    instance.saveWidgetData("totalConnector", (settings.showAvailableBudget) ? I18n.translate("availableStr") : I18n.translate("spentStr"));
    instance.saveWidgetData("totalFrom", I18n.translate("from"));
    instance.saveWidgetData("language", I18n.language);

    await instance.loadRanges();
    await instance.loadBudgets();
    await instance.getStatistics("month_total");
    return instance;
  }

  // initSharedDb, syncSharedDb, getRegisteredRemoteDevices,
  // updateRemoteDeviceMetadata, changeBlockStatus → SyncMixin

  void setSetupComplete() {
    isSetupComplete = true;
    notifyListeners();
  }

  // state loading
  @override
  Future<void> reloadData() async {
    DatabaseHelper db = DatabaseHelper();
    rawCategories = await db.getCategories(settings.filterBudget);
    Map<String, dynamic> ret = await db.getTotalBudget(settings.filterBudget);
    moneyFlows = await db.getMoneyFlows();
    bankAccounts = await db.getBankAccounts(moneyFlows);
    autoExpenses = await db.getAutoExpenses();
    totalBudget = ret['totalIncome'] + (settings.useBalance ? ret['totalBalance'] : 0);
    settings.currency = settings.currency;
    if (settings.filterBudget == "*") {
      resetInfo = {"principle": bankAccounts[0].budgetResetPrinciple, "day":bankAccounts[0].budgetResetDay};
    } else {
      resetInfo = {"principle": bankAccounts.where((acc) => acc.id == int.tryParse(settings.filterBudget)).first.budgetResetPrinciple, "day": bankAccounts.where((acc) => acc.id == int.tryParse(settings.filterBudget)).first.budgetResetDay};
    }

    await loadMoneyFlows();
    await loadBankAccounts();
    await loadRanges();
    if (budgetRanges.length <= range) {
      range = budgetRanges.length - 1;
    }
    await loadBudgets();

    notifyListeners();
    
    if (kDebugMode) {
      for (final r in budgetRanges) {
        Logger().debug("Rangeid: ${r.id}, start: ${r.start}, end: ${r.end}", tag: "PresentRanges");
      }
    }
    saveWidgetData("totalBudget", totalBudget);
  }

  @override
  Future<void> loadBudgets({int? overrideRange}) async {
    final cats = await DatabaseHelper().getCategories(settings.filterBudget);

    categories = await Future.wait(cats.map((cat) async {
      double spent = await DatabaseHelper().getSpentForCurrentMonth(cat.category.id!, settings.filterBudget, budgetRanges[overrideRange ?? range], settings.includePlanned, bankAccounts);
      double budget = await DatabaseHelper().getBudgetForCurrentInterval(budgetRanges[range].id!, cat.category.id!, settings.filterBudget);

      return CategoryBudget(
        categoryId: cat.category.id!,
        category: cat.category.name,
        budget: budget,
        spent: spent,
        color: colorFromHex(cat.category.color)!,
        position: cat.category.position,
        overrideBankAccount: cat.categoryBudgetsPlain.first.overrideBankAccount,
      );
    }).toList());

    calcNotAssignedBudget();

    if (Platform.isAndroid || Platform.isIOS) {
      List<Map<String, dynamic>> categoryWidgetList = categories.map((c) => c.toWidgetData(notAssignedBudget)).toList();
      saveWidgetData("categoryList", jsonEncode(categoryWidgetList));
    }
  }

  @override
  Future<void> loadRanges() async {
    DateTime firstDate;
    try {
      firstDate = DateTime.parse((await DatabaseHelper().getFirstExpense())['date']);
      if (firstDate.isAfter(DateTime.now())) {
        firstDate = DateTime.now();
      }
    } catch (formatException) {
      firstDate = DateTime.now();
    }

    int maxRange = (proStatusIsSet(simplePro: true, inverted: true)) ? maxFreeRanges : maxProRanges;

    budgetRanges = await DatabaseHelper().getIntervals(limit: maxRange, filter: "accountId = ?", filterArgs: [settings.filterBudget == "*" ? -1 : settings.filterBudget], order: "start DESC");
    if (budgetRanges.length - 1 < range){
      range = budgetRanges.length - 1;
    }

    if (range < 0) {
      range = 0;
    }
  }

  @override
  Future<void> loadBankAccounts() async {
    bankAccounts = await DatabaseHelper().getBankAccounts(moneyFlows, intervalId: budgetRanges[range].id!);
    totalBudget = bankAccounts.fold(0.0, (sum, acc) => sum + acc.income + (settings.useBalance ? acc.balance : 0.0));
  }

  @override
  Future<void> loadMoneyFlows() async {
    moneyFlows = await DatabaseHelper().getMoneyFlows();
  }

  @override
  void calcNotAssignedBudget() {
    notAssignedBudget = totalBudget - categories.fold(0.0, (sum, cat) => sum + cat.budget);
  }

  // updateFrequency … updateSharedDbUrl, getRegisteredRemoteDevices,
  // updateRemoteDeviceMetadata → SettingsMutationsMixin
  // updateRangeSelection, moneyFlowOnce → BankAccountMixin
  // addBankAccount, updateOrDeleteBankAccount, getTransfers → BankAccountMixin

  // addBankAccount … getTransfers → BankAccountMixin
  // addRateAutoExpense … updateOrDeleteAutoExpense → AutoExpenseMixin
  // insertCategory … getCategoryBudget → CategoryMixin
  // saveExpense … moveItem → ExpenseMixin

  void updateTotalSpentWidget(double amount) {
    if(settings.showAvailableBudget) {
      //available
      saveWidgetData("fractionTotalBudget", totalBudget - amount);
    } else {
      //spent
      saveWidgetData("fractionTotalBudget",amount);
    }
  }

  @override
  Future<void> saveWidgetData(String id, dynamic data) async {
    if (Platform.isAndroid || Platform.isIOS){
      if (data is double) {
        data = I18n.normalizeValueString(data);
      }
      if (data is String) {
        HomeWidget.saveWidgetData<String>(id, data);
        Logger().debug("Saved widget data '$data' to '$id'", tag: "widgetData");
      } else if (data is List) {
        HomeWidget.saveWidgetData<List>(id, data);
        Logger().debug("Saved widget data '$data' to '$id'", tag: "widgetData");
      } else {
        Logger().error("Unknown data type for widget", tag: "widgetData");
        return;
      }
      if (Platform.isAndroid) {
        await HomeWidget.updateWidget(
          qualifiedAndroidName:
            '$androidQualifiedName.glance.TotalBudgetReceiver',
        );

        await HomeWidget.updateWidget(
          qualifiedAndroidName:
            '$androidQualifiedName.glance.CategoriesReceiver',
        );
      } else {
        await HomeWidget.updateWidget(
          iOSName: 'TotalBudgetWidget'
        );

        await HomeWidget.updateWidget(
          iOSName: 'CategoriesWidget'
        );
      }
    }
  }

  bool proStatusIsSet({bool desktop=false, bool mobileOnly=false, bool simplePro = false, bool inverted = false, bool ignoreDebugMode = false}) {
    bool result;
    if (!ignoreDebugMode) {
      if (kDebugMode && mobileOnly) {
        result = true && (Platform.isAndroid || Platform.isIOS);
        Logger().debug("Pro status returned $result; DEBUGMODE - MOBILE", tag: "proStatus");
        return result;
      } else if (kDebugMode) {
        result = true;
        Logger().debug("Pro status returned $result; DEBUGMODE", tag: "proStatus");
        return result;
      }
    }

    if (simplePro && !(Platform.isAndroid || Platform.isIOS)) {
      result = (desktopIsDefaultPro || settings.isDesktopPro);
      Logger().debug("Pro status returned $result; SIMPLE - DESKTOP", tag: "proStatus");
      return result;
    }

    if (desktop) {
      result = (desktopIsDefaultPro || settings.isDesktopPro);
      Logger().debug("Pro status returned $result; DESKTOP ONLY", tag: "proStatus");
    } else if (mobileOnly && inverted) {
      result = !settings.isPro && (Platform.isAndroid || Platform.isIOS);
      Logger().debug("Pro status returned $result; MOBILE ONLY - INVERTED", tag: "proStatus");
    } else if (mobileOnly) {
      result = settings.isPro && (Platform.isAndroid || Platform.isIOS);
      Logger().debug("Pro status returned $result; MOBILE ONLY", tag: "proStatus");
    } else if (inverted) {
      result = !settings.isPro;
      Logger().debug("Pro status returned $result; INVERTED", tag: "proStatus");
    } else {
      result = settings.isPro;
      Logger().debug("Pro status returned $result; DEFAULT", tag: "proStatus");
    }

    return result;
  }
}
