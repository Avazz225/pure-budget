import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:home_widget/home_widget.dart';
import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/keys.dart';
import 'package:jne_household_app/models/expense.dart';
import 'package:jne_household_app/models/interval.dart';
import 'package:jne_household_app/models/settings.dart';
import 'package:jne_household_app/services/remote/auth.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/autoexpenses.dart';
import 'package:jne_household_app/models/bankaccount.dart';
import 'package:jne_household_app/models/category.dart';
import 'package:jne_household_app/models/category_budget.dart';
import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/free_restrictions.dart';
import 'package:jne_household_app/shared_database/shared_database.dart';

class BudgetState extends ChangeNotifier {
  double totalBudget;
  double notAssignedBudget;
  Map<String, dynamic> resetInfo;
  List<CategoryBudget> categories;
  List<Category> rawCategories;
  List<AutoExpense> autoExpenses;
  List<AutoExpense> moneyFlows;
  List<PBInterval> budgetRanges;
  List<BankAccount> bankAccounts;
  int range;
  Map<String, List<Map<String, dynamic>>> statistics;
  int selectedStatisticIndex;
  bool isSetupComplete;
  bool sharedDbConnected;
  SharedDatabase sharedDb;
  bool syncInProgress;
  Settings settings;

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

    await instance._loadRanges();
    await instance._loadBudgets();
    await instance.getStatistics("month_total");
    return instance;
  }

  Future<bool> initSharedDb() async {
    bool status = await sharedDb.initSharedDatabase(settings.sharedDbUrl, settings.isPro ,newConnection: true);
    if (status != sharedDbConnected && !status) {
      sharedDbConnected = status;
      notifyListeners();
      return false;
    } else {
      sharedDbConnected = status;
      if (!status) {
        return false;
      }
      syncSharedDb();
      return true;
    }
  }

  Future<void> syncSharedDb({bool manual = false, bool changeKey = false}) async {
    DatabaseHelper db = DatabaseHelper();
    if (settings.syncMode == "frequently" && !manual) {
      DateTime lastSync = await db.getLastSync();
      if (lastSync.add(Duration(seconds: settings.syncFrequency)).isBefore(DateTime.now())) {
        manual = true;
      }
    }

    if (settings.syncMode == "instant" || manual) {
      syncInProgress = true;
      notifyListeners();
      List<bool> result = await sharedDb.syncWithRemote(settings.sharedDbUrl, changeEncryptKey: changeKey, isPro: settings.isPro);
      if (result[0]) {
        sharedDbConnected = true;
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS){
          settings.isPro = result[1];
          await settings.save();
          settings.isPro = result[1];
        }
        await reloadData();
        settings.lastSync = formatForSqlite(DateTime.now());
        await settings.save();
      } else {
        sharedDbConnected = false;
        if (result[2]) {
          Logger().warning("Device has been locked out of shared database", tag: "sharedDatabase");
        }
      }
      syncInProgress = false;
    }
    notifyListeners();
  }

  void setSetupComplete() {
    isSetupComplete = true;
    notifyListeners();
  }

  // state loading
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

    await _loadMoneyFlows();
    await _loadBankAccounts();
    await _loadRanges();
    if (budgetRanges.length <= range) {
      range = budgetRanges.length - 1;
    }
    await _loadBudgets();

    notifyListeners();
    saveWidgetData("totalBudget", totalBudget);
  }

  Future<void> _loadBudgets({int? overrideRange}) async {
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

  Future<void> _loadRanges() async {
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

  Future<void> _loadBankAccounts() async {
    bankAccounts = await DatabaseHelper().getBankAccounts(moneyFlows, intervalId: budgetRanges[range].id!);
    totalBudget = bankAccounts.fold(0.0, (sum, acc) => sum + acc.income + (settings.useBalance ? acc.balance : 0.0));
  }

  Future<void> _loadMoneyFlows() async {
    moneyFlows = await DatabaseHelper().getMoneyFlows();
  }

  void calcNotAssignedBudget() {
    notAssignedBudget = totalBudget - categories.fold(0.0, (sum, cat) => sum + cat.budget);
  }

  // settings

  Future<void> updateFrequency(int value, String mode) async {
    if (mode == "days") {
      value = value * 60 * 60 * 24;
    } else if (mode == "hours") {
      value = value * 60 * 60;
    } else if (mode == "minutes") {
      value = value * 60;
    }

    settings.syncFrequency = value;
    await settings.save();
  }

  Future<void> updateSyncMode(String mode) async {
    settings.syncMode = mode;
    await settings.save();
  }

  Future<void> updateFilter(String filter) async {
    settings.filterBudget = filter;
    await settings.save();
    await reloadData();
  }

  Future<void> updateCurrency(String cur) async {
    settings.currency = cur;
    await settings.save();
    notifyListeners();
    saveWidgetData("settings.currency", settings.currency);
  }

  Future<void> updateInclude(bool include) async {
    settings.includePlanned = include;
    await settings.save();

    await _loadBudgets();
    notifyListeners();
  }

  Future<void> updateIsPro(bool pro) async {
    settings.isPro = pro;
    await settings.save();
    await _loadBudgets();
    notifyListeners();
  }

  Future<void> updateIsDesktopPro(bool pro) async {
    settings.isDesktopPro = pro;
    await settings.save();
    notifyListeners();
  }

  Future<void> updateUseBalance(bool use) async {
    settings.useBalance = use;
    await settings.save();

    Map<String, dynamic> ret = await DatabaseHelper().getTotalBudget(settings.filterBudget);
    totalBudget = ret['totalIncome'] + (settings.useBalance ? ret['totalBalance'] : 0);

    calcNotAssignedBudget();
    notifyListeners();

    saveWidgetData("totalBudget", totalBudget);
  }

  Future<void> updateLockApp(bool use) async {
    settings.lockApp = use;
    await settings.save();
    notifyListeners();
  }

  Future<void> updateAvailableBudget(bool available) async {
    settings.showAvailableBudget = available;
    await settings.save();
    notifyListeners();
    saveWidgetData("settings.showAvailableBudget", (available) ? "true" : "false");
    saveWidgetData("totalConnector", (settings.showAvailableBudget) ? I18n.translate("availableStr") : I18n.translate("spentStr"));
  }

  Future<void> updateLanguage(String code) async {
    settings.language = code;
    await settings.save();
    String langCode = (code != "auto") ? code : PlatformDispatcher.instance.locale.toString();
    await I18n.load(langCode, saveWidgetData: saveWidgetData);
    notifyListeners();
    saveWidgetData("totalConnector", (settings.showAvailableBudget) ? I18n.translate("availableStr") : I18n.translate("spentStr"));
    saveWidgetData("totalFrom", I18n.translate("from"));
  }

  Future<bool> updateSharedDbUrl(String url) async {
    settings.sharedDbUrl = url;
    await settings.save();
    
    if (url != "none") {
      bool result = await initSharedDb();
      if (!result) {
        settings.sharedDbUrl = "none";
        await settings.save();
        return false;
      }
    } else {
      List<String> keys = [
        'encryption_key', // general
        'googleAccessToken', 'googleRefreshToken', 'googleDriveItemId', // google
        'iCloudAccessTokenJson', 'iCloudItemId', // icloud (currently deactivated) 
        'oneDriveAccessTokenJson', 'oneDriveItemId', // oneDrive
        'smbHost', 'smbUname', 'smbPwd', 'smbDom' // samba
      ];

      for (String key in keys) {
        await deleteKey(key);
      }

      sharedDbConnected = false;
      notifyListeners();
    }
    return true;
  }

  Future<List<Map<String, dynamic>>> getRegisteredRemoteDevices() async {
    return await sharedDb.getRegisteredDevices(settings.sharedDbUrl);
  } 

  Future<bool> updateRemoteDeviceMetadata(String uuid, Map<String, dynamic> metadata) async {
    return await sharedDb.updateRegisteredDeviceMetadata(settings.sharedDbUrl, uuid, metadata);
  } 

  // range
  Future<void> updateRangeSelection(index) async {
    range = index;
    await _loadBankAccounts();
    await _loadBudgets(overrideRange: index);
    notifyListeners();
  }

  Future<void> moneyFlowOnce(spenderId, spenderName, receiverId, receiverName, amount) async {
    String description = "$spenderName ${I18n.translate("to")} $receiverName";
    String date = formatForSqlite(DateTime.now());

    Map<String, dynamic> exp1 = {"description": description, "categoryId": -1, "amount": amount, "accountId": spenderId, "date": date};
    Expense expense1 = Expense(exp1);
    await expense1.save();

    Map<String, dynamic> exp2 = {"description": description, "categoryId": -1, "amount": -amount, "accountId": receiverId, "date": date};
    Expense expense2 = Expense(exp2);
    await expense2.save();

    await _loadBudgets();
    notifyListeners();

    if (sharedDbConnected && !syncInProgress) {
      syncSharedDb();
    } 
  }

  // bankAccounts
  void addBankAccount(Map<String, dynamic> acc) async {
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
      refillPrincipleMode: acc['refillPrincipleMode']
    );

    await newAcc.save();
    bankAccounts.add(newAcc);

    Map<String, dynamic> ret = await DatabaseHelper().getTotalBudget(settings.filterBudget);
    totalBudget = ret['totalIncome'] + (settings.useBalance ? ret['totalBalance'] : 0);

    await _loadRanges();
    await _loadBudgets();
    notifyListeners();

    saveWidgetData("totalBudget", totalBudget);

    if (sharedDbConnected && !syncInProgress) {
      syncSharedDb();
    } 
  }

  void updateOrDeleteBankAccount(Map<String, dynamic> acc, int id, bool delete) async {
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
      refillPrincipleMode: acc['refillPrincipleMode']
    );

    final index = bankAccounts.indexWhere((account) => account.id == targetAccount.id);
    if (delete && targetAccount.id != -1) {
      await DatabaseHelper().deleteBankAccount(targetAccount.id!);
      bankAccounts.removeAt(index);
      
      if (settings.filterBudget == targetAccount.id.toString()) {
        settings.filterBudget = "*";
      }
      targetAccount.delete();
    } else {
      await targetAccount.save();
      bankAccounts[index] = targetAccount;
    }

    Map<String, dynamic> ret = await DatabaseHelper().getTotalBudget(settings.filterBudget);
    totalBudget = ret['totalIncome'] + (settings.useBalance ? ret['totalBalance'] : 0);

    await _loadMoneyFlows();
    await _loadBankAccounts();
    await _loadRanges();
    await _loadBudgets();
    notifyListeners();

    saveWidgetData("totalBudget", totalBudget);

    if (sharedDbConnected && !syncInProgress) {
      syncSharedDb();
    }
  }

  double getTransfers(int accountId) {
    return moneyFlows.where((mf) => mf.receiverAccountId == accountId).fold(0, (sum, mf) => sum + mf.amount);
  }

  // ratePayments
  Future<void> addRateAutoExpense(AutoExpense newAE) async {
    await newAE.save(budgetRanges.first);
    autoExpenses.add(newAE);
    await _loadBudgets();
    notifyListeners();

    if (sharedDbConnected && !syncInProgress) {
      syncSharedDb();
    }
  }

  Future<void> updateOrDeleteRateAutoExpense(AutoExpense newAE) async {
    if (newAE.amount == 0.0) {
      newAE.delete();
      autoExpenses.removeWhere((exp) => exp.id == newAE.id);
    } else {
      newAE.save(budgetRanges.first);
      int index = autoExpenses.indexWhere((exp) => exp.id == newAE.id);
      autoExpenses[index] = newAE;
    }

    await _loadBudgets();
    notifyListeners();

    if (sharedDbConnected && !syncInProgress) {
      syncSharedDb();
    }
  }

  // autoExpenses
  Future<void> addAutoExpense(AutoExpense autoExp) async {
    await autoExp.save(budgetRanges.first);
    if (!autoExp.moneyFlow) {
      autoExpenses.add(autoExp);
    } else {
      moneyFlows.add(autoExp);
      await _loadBankAccounts();
    }
    
    await _loadBudgets();
    notifyListeners();

    if (sharedDbConnected && !syncInProgress) {
      syncSharedDb();
    }
  }

  Future<void> updateOrDeleteAutoExpense(AutoExpense autoExp) async {
    int index;

    if (!autoExp.moneyFlow) {
      index = autoExpenses.indexWhere((expense) => expense.id == autoExp.id);
    } else {
      index = moneyFlows.indexWhere((expense) => expense.id == autoExp.id);
    }
    if (autoExp.amount == 0.0) {
      await autoExp.delete();
      if (index != -1) {
        if (!autoExp.moneyFlow) {
          autoExpenses.removeAt(index);
        } else {
          moneyFlows.removeAt(index);
          await _loadBankAccounts();
        }
      }
    } else {
      await autoExp.save(budgetRanges.first);
      if (index != -1) {
        if (!autoExp.moneyFlow) {
          autoExpenses[index] = autoExp;
        } else {
          moneyFlows[index] = autoExp;
          await _loadBankAccounts();
        }
      }
    }
    await _loadRanges();
    await _loadBudgets();
    notifyListeners();

    if (sharedDbConnected && !syncInProgress) {
      syncSharedDb();
    } 
  }

  // categories (shared)
  Future<int> insertCategory(Category category) async {
    final newPos = rawCategories.length;
    category.save();
    rawCategories.add(category);
    categories.add(CategoryBudget(categoryId: category.category.id!, category: category.category.name, budget: category.budget, spent: 0.0, color: colorFromHex(category.category.color)!, position: newPos, overrideBankAccount: category.categoryBudgetsPlain.first.overrideBankAccount));
    sortRawCategories();
    sortCategories();
    calcNotAssignedBudget();
    notifyListeners();

    if (sharedDbConnected && !syncInProgress) {
      syncSharedDb();
    }

    if (Platform.isAndroid || Platform.isIOS) {
      List<Map<String, dynamic>> categoryWidgetList = categories.map((c) => c.toWidgetData(notAssignedBudget)).toList();
      saveWidgetData("categoryList", jsonEncode(categoryWidgetList));
    }

    return category.category.id!;
  }

  // categories
  void updateCategory(CategoryBudget oldCategory, CategoryBudget newCategory) {
    final index = categories.indexOf(oldCategory);
    if (index != -1) {
      categories[index] = newCategory;
      notifyListeners();
    }
    if (Platform.isAndroid || Platform.isIOS) {
      List<Map<String, dynamic>> categoryWidgetList = categories.map((c) => c.toWidgetData(notAssignedBudget)).toList();
      saveWidgetData("categoryList", jsonEncode(categoryWidgetList));
    }
  }

  void sortCategories(){
    categories.sort((a, b) {
      return b.position.compareTo(a.position);
    });

    if (Platform.isAndroid || Platform.isIOS) {
      List<Map<String, dynamic>> categoryWidgetList = categories.map((c) => c.toWidgetData(notAssignedBudget)).toList();
      saveWidgetData("categoryList", jsonEncode(categoryWidgetList));
    }
  }

  // raw categories
  void sortRawCategories(){
    rawCategories.sort((a, b) {
      return b.category.position.compareTo(a.category.position);
    });
  }

  Future<void> updateRawCategory(Category updatedCategory) async {
    await updatedCategory.save();

    rawCategories = await DatabaseHelper().getCategories(settings.filterBudget);
    await _loadBudgets();
    calcNotAssignedBudget();
    notifyListeners();

    if (sharedDbConnected && !syncInProgress) {
      syncSharedDb();
    } 

    if (Platform.isAndroid || Platform.isIOS) {
      List<Map<String, dynamic>> categoryWidgetList = categories.map((c) => c.toWidgetData(notAssignedBudget)).toList();
      saveWidgetData("categoryList", jsonEncode(categoryWidgetList));
    }
  }

  Future<void> saveCategoryOrder() async {
    List<Map<String, int>> positions = [];
    for (Category cat in rawCategories) {
      positions.add({"id": cat.category.id!, "pos": cat.category.position}) ;
      final category = categories.firstWhere((category) => category.categoryId == cat.category.id);
      category.position = cat.category.position;
    }

    await DatabaseHelper().updatePositions(positions);
    sortRawCategories();
    sortCategories();
    notifyListeners();

    if (sharedDbConnected && !syncInProgress) {
      syncSharedDb();
    }
  }

  // expenses
  Future<void> saveExpense(Expense expense) async {
    expense.save();
    await _loadRanges();
    await _loadBudgets();
    notifyListeners();

    if (sharedDbConnected && !syncInProgress) {
      syncSharedDb();
    }
  }

  Future<void> deleteExpense(Expense expense) async {
    expense.delete();

    await _loadRanges();
    await _loadBudgets();
    notifyListeners();

    if (sharedDbConnected && !syncInProgress) {
      syncSharedDb();
    }
  }

  Future<void> getStatistics(String type) async {
    switch (type) {
      case "history_months":
        statistics = {
          "data": await DatabaseHelper().lastMonthsTotal(budgetRanges, settings.filterBudget),
          "totalBudget": await DatabaseHelper().lastTotalBudgets(budgetRanges, settings.filterBudget)
        };
      case "month_by_cat":
        statistics = {
          "data": await DatabaseHelper().statisticMonthTotalByCat(budgetRanges[range], settings.filterBudget)
        };
      case "history_by_cat":
        statistics = {
          "data": await DatabaseHelper().lastMonthsByCat(budgetRanges, settings.filterBudget),
          "totalBudget": await DatabaseHelper().lastMonthsCatBudget(budgetRanges, settings.filterBudget)
        };
      // month_total
      default:
        statistics = {
          "data": (await DatabaseHelper().statisticMonthTotal(budgetRanges[range], settings.filterBudget))
        };
    }
  }

  double getCategoryBudget(String category) {
    if (category == "__undefined_category_name__"){
      return notAssignedBudget;
    }

    try {
      final categoryBudget = categories.firstWhere(
        (item) => item.category == category,
        orElse: () => throw Exception('Category not found'),
      );
      return categoryBudget.budget;
    } catch (e) {
      return notAssignedBudget;
    }
  }

  Future<void> moveItem(int id, int newCatId, int newAccountId, bool autoExpense) async {
    if (!autoExpense) {
      await DatabaseHelper().moveExpense(id, newCatId, newAccountId);
    } else {
      await DatabaseHelper().moveAutoExpense(id, newCatId, newAccountId);
      autoExpenses.where((aExp) => aExp.id == id).first.categoryId = newCatId;
    }

    await _loadRanges();
    await _loadBudgets();
    notifyListeners();

    if (sharedDbConnected && !syncInProgress) {
      syncSharedDb();
    }
  }

  Future<bool> changeBlockStatus(int newStatus, String uuid) async {
    return (await sharedDb.changeBlockStatus(settings.sharedDbUrl, newStatus, uuid));
  }

  void updateTotalSpentWidget(double amount) {
    if(settings.showAvailableBudget) {
      //available
      saveWidgetData("fractionTotalBudget", totalBudget - amount);
    } else {
      //spent
      saveWidgetData("fractionTotalBudget",amount);
    }
  }

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
