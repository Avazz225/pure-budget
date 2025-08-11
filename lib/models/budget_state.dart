import 'dart:io';
import 'dart:ui';

import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/helper/auto_booking.dart';
import 'package:jne_household_app/helper/remote/auth.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/autoexpenses.dart';
import 'package:jne_household_app/models/bankaccount.dart';
import 'package:jne_household_app/models/category.dart';
import 'package:jne_household_app/models/category_budget.dart';
import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/free_restrictions.dart';
import 'package:jne_household_app/models/reset_principles.dart';
import 'package:jne_household_app/shared_database/shared_database.dart';

class BudgetState extends ChangeNotifier {
  double totalBudget;
  double notAssignedBudget;
  String currency;
  String language;
  bool includePlanned;
  bool showAvailableBudget;
  Map<String, dynamic> resetInfo;
  List<CategoryBudget> categories;
  List<Category> rawCategories;
  List<AutoExpense> autoExpenses;
  List<AutoExpense> moneyFlows;
  List<Map<String, DateTime>> budgetRanges;
  List<BankAccount> bankAccounts;
  int range;
  List<Map<String, dynamic>> statistics;
  int selectedStatisticIndex;
  bool isPro;
  bool isDesktopPro;
  bool isSetupComplete;
  bool useBalance;
  String filterBudget;
  String sharedDbUrl;
  bool sharedDbConnected;
  SharedDatabase sharedDb;
  bool syncInProgress;
  String syncMode;
  int syncFrequency;
  bool lockApp;

  BudgetState._({
    required this.totalBudget,
    required this.rawCategories,
    required this.currency,
    required this.resetInfo,
    required this.language,
    required this.categories,
    required this.notAssignedBudget,
    required this.includePlanned,
    required this.autoExpenses,
    required this.budgetRanges,
    required this.range,
    required this.statistics,
    required this.selectedStatisticIndex,
    required this.showAvailableBudget,
    required this.isPro,
    required this.isSetupComplete,
    required this.useBalance,
    required this.filterBudget,
    required this.bankAccounts,
    required this.moneyFlows,
    required this.sharedDbUrl,
    required this.sharedDbConnected,
    required this.sharedDb,
    required this.syncInProgress,
    required this.syncMode,
    required this.syncFrequency,
    required this.lockApp,
    required this.isDesktopPro
  });

  factory BudgetState({
    required double totalBudget,
    required List<Category> rawCategories,
    required String currency,
    required Map<String, dynamic> resetInfo,
    required String language,
    required bool includePlanned,
    required List<AutoExpense> autoExpenses,
    required bool showAvailableBudget,
    required bool isPro,
    required bool isSetupComplete,
    required bool useBalance,
    required String filterBudget,
    required List<BankAccount> bankAccounts,
    required List<AutoExpense> moneyFlows,
    required String sharedDbUrl,
    required String syncMode,
    required int syncFrequency,
    required bool lockApp,
    required bool isDesktopPro
  }) {
    return BudgetState._(
      totalBudget: totalBudget,
      rawCategories: rawCategories,
      currency: currency,
      resetInfo: resetInfo,
      language: language,
      categories: [],
      budgetRanges: [],
      range: 0,
      notAssignedBudget: totalBudget,
      includePlanned: includePlanned,
      autoExpenses: autoExpenses,
      statistics: [],
      selectedStatisticIndex: 0,
      showAvailableBudget: showAvailableBudget,
      isPro: isPro,
      isSetupComplete: isSetupComplete,
      useBalance: useBalance,
      filterBudget: filterBudget,
      bankAccounts: bankAccounts,
      moneyFlows: moneyFlows,
      sharedDbUrl: sharedDbUrl,
      sharedDbConnected: false,
      sharedDb: SharedDatabase(DatabaseHelper()),
      syncInProgress: false,
      syncMode: syncMode,
      syncFrequency: syncFrequency,
      lockApp: lockApp,
      isDesktopPro: isDesktopPro
    );
  }

  static Future<BudgetState> initialize({
    required double totalBudget,
    required List<Category> rawCategories,
    required String currency,
    required Map<String, dynamic> resetInfo,
    required String language,
    required bool includePlanned,
    required List<AutoExpense> autoExpenses,
    required bool showAvailableBudget,
    required bool isPro,
    required bool isSetupComplete,
    required bool useBalance,
    required String filterBudget,
    required List<BankAccount> bankAccounts,
    required List<AutoExpense> moneyFlows,
    required String sharedDbUrl,
    required String syncMode,
    required int syncFrequency,
    required bool lockApp,
    required bool isDesktopPro
  }) async {
    final instance = BudgetState(
      totalBudget: totalBudget,
      rawCategories: rawCategories,
      currency: currency,
      resetInfo: resetInfo,
      language: language,
      includePlanned: includePlanned,
      autoExpenses: autoExpenses,
      showAvailableBudget: showAvailableBudget,
      isPro: isPro,
      isSetupComplete: isSetupComplete,
      useBalance: useBalance,
      filterBudget: filterBudget,
      bankAccounts: bankAccounts,
      moneyFlows: moneyFlows,
      sharedDbUrl: sharedDbUrl,
      syncMode: syncMode,
      syncFrequency: syncFrequency,
      lockApp: lockApp,
      isDesktopPro: isDesktopPro
    );

    await instance.sharedDb.initialize();

    if (instance.sharedDbUrl != "none") {
      instance.syncSharedDb();
    }

    await instance._loadRanges();
    await instance._loadBudgets();
    await instance.getStatistics("month_total");
    return instance;
  }

  Future<bool> initSharedDb() async {
    bool status = await sharedDb.initSharedDatabase(sharedDbUrl, isPro ,newConnection: true);
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
    if (syncMode == "frequently" && !manual) {
      DateTime lastSync = await db.getLastSync();
      if (lastSync.add(Duration(seconds: syncFrequency)).isBefore(DateTime.now())) {
        manual = true;
      }
    }

    if (syncMode == "instant" || manual) {
      syncInProgress = true;
      notifyListeners();
      List<bool> result = await sharedDb.syncWithRemote(sharedDbUrl, changeEncryptKey: changeKey, isPro: isPro);
      if (result[0]) {
        sharedDbConnected = true;
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS){
          await db.updateSettings("isPro", result[1] ? 1 : 0);
          isPro = result[1];
        }
        await reloadData();
        db.updateSettings("lastSync", formatForSqlite(DateTime.now()));
      } else {
        sharedDbConnected = false;
        if (result[2]) {
          Logger().warning("Device has been locked out of shared database", tag: "sharedDatabase");
        }
      }
      syncInProgress = false;
      notifyListeners();
    }
  }

  void setSetupComplete() {
    isSetupComplete = true;
    notifyListeners();
  }

  // state loading
  Future<void> reloadData() async {
    DatabaseHelper db = DatabaseHelper();
    rawCategories = await db.getCategories(filterBudget);
    Map<String, dynamic> settings = await db.getSettings();
    Map<String, dynamic> ret = await db.getTotalBudget(filterBudget);
    moneyFlows = await db.getMoneyFlows();
    bankAccounts = await db.getBankAccounts(moneyFlows);
    autoExpenses = await db.getAutoExpenses();
    totalBudget = ret['totalIncome'] + (useBalance ? ret['totalBalance'] : 0);
    includePlanned = settings['includePlanned'] == 1;
    currency = settings['currency'] ?? "€";
    if (filterBudget == "*") {
      resetInfo = {"principle": bankAccounts[0].budgetResetPrinciple, "day":bankAccounts[0].budgetResetDay};
    } else {
      resetInfo = {"principle": bankAccounts.where((acc) => acc.id == int.tryParse(filterBudget)).first.budgetResetPrinciple, "day": bankAccounts.where((acc) => acc.id == int.tryParse(filterBudget)).first.budgetResetDay};
    }

    await _loadMoneyFlows();
    await _loadBankAccounts();
    await _loadRanges();
    if (budgetRanges.length <= range) {
      range = budgetRanges.length - 1;
    }
    await _loadBudgets();

    notifyListeners();
  }

  Future<void> _loadBudgets({int? overrideRange}) async {
    final cats = await DatabaseHelper().getCategories(filterBudget);

    categories = await Future.wait(cats.map((cat) async {
      double spent = await DatabaseHelper().getSpentForCurrentMonth(cat.id, filterBudget, budgetRanges[overrideRange ?? range], includePlanned);
      return CategoryBudget(
        categoryId: cat.id,
        category: cat.name,
        budget: cat.budget,
        spent: spent,
        color: cat.color,
        position: cat.position
      );
    }).toList());

    calcNotAssignedBudget();
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

    int maxRange = (!getProStatus(isPro)) ? maxFreeRanges : maxProRanges;

    budgetRanges = getMultipleRanges(resetInfo, maxRange, firstDate);
    if (budgetRanges.length - 1 < range){
      range = budgetRanges.length - 1;
    }

    if (range < 0) {
      range = 0;
    }
  }

  Future<void> _loadBankAccounts() async {
    bankAccounts = await DatabaseHelper().getBankAccounts(moneyFlows);
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
    await DatabaseHelper().updateSettings("syncFrequency", value);
    syncFrequency = value;
  }

  Future<void> updateSyncMode(String mode) async {
    await DatabaseHelper().updateSettings("syncMode", mode);
    syncMode = mode;
  }

  Future<void> updateFilter(String filter) async {
    await DatabaseHelper().updateSettings("filterBudget", filter);
    filterBudget = filter;
    await reloadData();
  }

  Future<void> updateCurrency(String cur) async {
    await DatabaseHelper().updateSettings("currency", cur);
    currency = cur;
    notifyListeners();
  }

  Future<void> updateResetInfo(Map<String, dynamic> info) async {
    await DatabaseHelper().updateSettings("budgetResetPrinciple", info['principle']);
    await DatabaseHelper().updateSettings("budgetResetDay", info['day']);
    resetInfo = info;
    
    await _loadRanges();
    await _loadBudgets();
    notifyListeners();
    
    if (sharedDbConnected && !syncInProgress) {
      syncSharedDb();
    }
  }

  Future<void> updateInclude(bool include) async {
    await DatabaseHelper().updateSettings("includePlanned", (include) ? 1 : 0);
    includePlanned = include;
    await _loadBudgets();
    notifyListeners();
  }

  Future<void> updateIsPro(bool pro) async {
    await DatabaseHelper().updateSettings("isPro", (pro) ? 1 : 0);
    isPro = pro;
    await _loadBudgets();
    notifyListeners();
  }

  Future<void> updateIsDesktopPro(bool pro) async {
    await DatabaseHelper().updateSettings("isDesktopPro", (pro) ? 1 : 0);
    isDesktopPro = pro;
    notifyListeners();
  }

  Future<void> updateUseBalance(bool use) async {
    await DatabaseHelper().updateSettings("useBalance", (use) ? 1 : 0);
    useBalance = use;

    Map<String, dynamic> ret = await DatabaseHelper().getTotalBudget(filterBudget);
    totalBudget = ret['totalIncome'] + (useBalance ? ret['totalBalance'] : 0);

    calcNotAssignedBudget();
    notifyListeners();
  }

  Future<void> updateLockApp(bool use) async {
    await DatabaseHelper().updateSettings("lockApp", (use) ? 1 : 0);
    lockApp = use;
    notifyListeners();
  }

  Future<void> updateAvailableBudget(bool available) async {
    await DatabaseHelper().updateSettings("showAvailableBudget", (available) ? 1 : 0);
    showAvailableBudget = available;
    notifyListeners();
  }

  Future<void> updateLanguage(String code) async {
    await DatabaseHelper().updateSettings("language", code);
    language = code;
    I18n.load((code != "auto") ? code : PlatformDispatcher.instance.locale.toString());
    notifyListeners();
  }

  Future<bool> updateSharedDbUrl(String url) async {
    await DatabaseHelper().updateSettings("sharedDbUrl", url);
    sharedDbUrl = url;
    
    if (url != "none") {
      bool result = await initSharedDb();
      if (!result) {
        await DatabaseHelper().updateSettings("sharedDbUrl", "none");
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
    return await sharedDb.getRegisteredDevices(sharedDbUrl);
  } 

  Future<bool> updateRemoteDeviceMetadata(String uuid, Map<String, dynamic> metadata) async {
    return await sharedDb.updateRegisteredDeviceMetadata(sharedDbUrl, uuid, metadata);
  } 

  // range
  Future<void> updateRangeSelection(index) async {
    range = index;
    await _loadBudgets(overrideRange: index);
    notifyListeners();
  }

  Future<void> moneyFlowOnce(spenderId, spenderName, receiverId, receiverName, amount) async {
    String description = "$spenderName ${I18n.translate("to")} $receiverName";
    String date = formatForSqlite(DateTime.now());

    Map<String, dynamic> exp1 = {"description": description, "categoryId": -1, "amount": amount, "accountId": spenderId, "date": date};
    await DatabaseHelper().insertExpense(exp1);

    Map<String, dynamic> exp2 = {"description": description, "categoryId": -1, "amount": -amount, "accountId": receiverId, "date": date};
    await DatabaseHelper().insertExpense(exp2);

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
      transfers: 0
    );

    bankAccounts.add(newAcc);

    Map<String, dynamic> ret = await DatabaseHelper().getTotalBudget(filterBudget);
    totalBudget = ret['totalIncome'] + (useBalance ? ret['totalBalance'] : 0);

    await _loadRanges();
    await _loadBudgets();
    notifyListeners();

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
      transfers: getTransfers(id)
    );

    final index = bankAccounts.indexWhere((account) => account.id == targetAccount.id);
    if (delete && targetAccount.id != -1) {
      await DatabaseHelper().deleteBankAccount(targetAccount.id);
      bankAccounts.removeAt(index);
      
      if (filterBudget == targetAccount.id.toString()) {
        filterBudget = "*";
      }
    } else {
      await DatabaseHelper().updateBankAccount(acc, id);
      bankAccounts[index] = targetAccount;
      
    }

    Map<String, dynamic> ret = await DatabaseHelper().getTotalBudget(filterBudget);
    totalBudget = ret['totalIncome'] + (useBalance ? ret['totalBalance'] : 0);

    await _loadMoneyFlows();
    await _loadBankAccounts();
    await _loadRanges();
    await _loadBudgets();
    notifyListeners();

    if (sharedDbConnected && !syncInProgress) {
      syncSharedDb();
    }
  }

  double getTransfers(int accountId) {
    return moneyFlows.where((mf) => mf.receiverAccountId == accountId).fold(0, (sum, mf) => sum + mf.amount);
  }

  // ratePayments
  void addRateAutoExpense(Map<String, dynamic> autoExp, accountId) async {
    autoExp['accountId'] = accountId;
    autoExp['id'] = await DatabaseHelper().insertAutoExpense(autoExp);
    final newAutoExpense = AutoExpense(
      id: autoExp['id'],
      categoryId: autoExp['categoryId'],
      amount: autoExp['amount'],
      description: autoExp['description'],
      bookingPrinciple: autoExp['bookingPrinciple'],
      bookingDay: autoExp['bookingDay'],
      principleMode: autoExp['principleMode'],
      accountId: int.parse(accountId),
      moneyFlow: autoExp['moneyFlow'] == 1,
      receiverAccountId: autoExp['receiverAccountId'],
      ratePayment: true,
      rateCount: autoExp['rateCount'],
      firstRateAmount: autoExp['firstRateAmount'],
      lastRateAmount: autoExp['lastRateAmount']
    );
    // ToDo
    processCreateRates(newAutoExpense);

    await _loadBudgets();
    notifyListeners();

    if (sharedDbConnected && !syncInProgress) {
      syncSharedDb();
    }
  }

  void updateOrDeleteRateAutoExpense(Map<String, dynamic> autoExp, id, accountId) async {
    final newAutoExpense = AutoExpense(
      id: id,
      categoryId: autoExp['categoryId'],
      amount: autoExp['amount'],
      description: autoExp['description'],
      bookingPrinciple: autoExp['bookingPrinciple'],
      bookingDay: autoExp['bookingDay'],
      principleMode: autoExp['principleMode'],
      accountId: int.parse(accountId),
      moneyFlow: autoExp['moneyFlow'] == 1,
      receiverAccountId: autoExp['receiverAccountId'],
      ratePayment: true,
      rateCount: autoExp['rateCount'],
      firstRateAmount: autoExp['firstRateAmount'],
      lastRateAmount: autoExp['lastRateAmount']
    );
    // ToDo
    if (autoExp["amount"] == 0.0) {
      await processDeleteAutoExpenses(newAutoExpense);
      await DatabaseHelper().deleteAutoExpense(id);
    } else {
      await processUpdateRates(newAutoExpense);
      await DatabaseHelper().updateAutoExpense(autoExp, id);
    }

    await _loadBudgets();
    notifyListeners();

    if (sharedDbConnected && !syncInProgress) {
      syncSharedDb();
    }
  }

  // autoExpenses
  void addAutoExpense(Map<String, dynamic> autoExp, accountId) async {
    autoExp['accountId'] = accountId;
    autoExp['id'] = await DatabaseHelper().insertAutoExpense(autoExp);
    final newAutoExpense = AutoExpense(
      id: autoExp['id'],
      categoryId: autoExp['categoryId'],
      amount: autoExp['amount'],
      description: autoExp['description'],
      bookingPrinciple: autoExp['bookingPrinciple'],
      bookingDay: autoExp['bookingDay'],
      principleMode: autoExp['principleMode'],
      accountId: int.parse(accountId),
      moneyFlow: autoExp['moneyFlow'] == 1,
      receiverAccountId: autoExp['receiverAccountId'],
      ratePayment: false
    );

    await processAutoExpenses("none", [newAutoExpense], updateSettings: false);
    if (!newAutoExpense.moneyFlow) {
      autoExpenses.add(newAutoExpense);
    } else {
      moneyFlows.add(newAutoExpense);
      await _loadBankAccounts();
    }
    
    await _loadBudgets();
    notifyListeners();

    if (sharedDbConnected && !syncInProgress) {
      syncSharedDb();
    }
  }

  void updateOrDeleteAutoExpense(Map<String, dynamic> autoExp, id, accountId) async {
    final newAutoExpense = AutoExpense(
      id: id,
      categoryId: autoExp['categoryId'],
      amount: autoExp['amount'],
      description: autoExp['description'],
      bookingPrinciple: autoExp['bookingPrinciple'],
      bookingDay: autoExp['bookingDay'],
      principleMode: autoExp['principleMode'],
      accountId: int.parse(accountId),
      moneyFlow: autoExp['moneyFlow'] == 1,
      receiverAccountId: autoExp['receiverAccountId'],
      ratePayment: false
    );

    int index;

    if (!newAutoExpense.moneyFlow) {
      index = autoExpenses.indexWhere((expense) => expense.id == newAutoExpense.id);
    } else {
      index = moneyFlows.indexWhere((expense) => expense.id == newAutoExpense.id);
    }
    if (autoExp["amount"] == 0.0) {
      await processDeleteAutoExpenses(newAutoExpense);
      await DatabaseHelper().deleteAutoExpense(id);
        if (index != -1) {
          if (!newAutoExpense.moneyFlow) {
            autoExpenses.removeAt(index);
          } else {
            moneyFlows.removeAt(index);
            await _loadBankAccounts();
          }
        }
    } else {
      await processUpdateAutoExpenses(newAutoExpense);
      await DatabaseHelper().updateAutoExpense(autoExp, id);
      if (index != -1) {
        if (!newAutoExpense.moneyFlow) {
          autoExpenses[index] = newAutoExpense;
        } else {
          moneyFlows[index] = newAutoExpense;
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
  Future<int> insertCategory(Map<String, dynamic> category) async {
    final newPos = rawCategories.length;
    int id = await DatabaseHelper().insertCategory(category, filterBudget, newPos);
    rawCategories.add(Category(id: id, name: category['name'], budget: category['budget'], color: category['raw_color'], position: newPos));
    categories.add(CategoryBudget(categoryId: id, category: category['name'], budget: category['budget'], spent: 0.0, color: category['raw_color'], position: newPos));
    sortRawCategories();
    sortCategories();
    calcNotAssignedBudget();
    notifyListeners();

    if (sharedDbConnected && !syncInProgress) {
      syncSharedDb();
    }

    return id;
  }

  // categories
  void updateCategory(CategoryBudget oldCategory, CategoryBudget newCategory) {
    final index = categories.indexOf(oldCategory);
    if (index != -1) {
      categories[index] = newCategory;
      notifyListeners();
    }
  }

  void sortCategories(){
    categories.sort((a, b) {
      return b.position.compareTo(a.position);
    });
  }

  // raw categories
  void sortRawCategories(){
    rawCategories.sort((a, b) {
      return b.position.compareTo(a.position);
    });
  }

  Future<void> updateRawCategory(Category updatedCategory) async {
    await DatabaseHelper().updateCategoryBase(updatedCategory, filterBudget);
    for (Category cat in rawCategories){
      if (cat.id == updatedCategory.id){
        cat.name = updatedCategory.name;
        cat.budget = updatedCategory.budget;
        cat.color = updatedCategory.color;
        cat.position = updatedCategory.position;
      }
    }

    for (CategoryBudget cat in categories){
      if (cat.categoryId == updatedCategory.id){
        cat.category = updatedCategory.name;
        cat.budget = updatedCategory.budget;
        cat.color = updatedCategory.color;
        cat.position = updatedCategory.position;
      }
    }

    calcNotAssignedBudget();
    notifyListeners();

    if (sharedDbConnected && !syncInProgress) {
      syncSharedDb();
    } 
  }

  Future<void> saveCategoryOrder() async {
    List<Map<String, int>> positions = [];
    for (Category cat in rawCategories) {
      positions.add({"id": cat.id, "pos": cat.position}) ;
      final category = categories.firstWhere((category) => category.categoryId == cat.id);
      category.position = cat.position;
    }

    await DatabaseHelper().updatePositions(positions);
    sortRawCategories();
    sortCategories();
    notifyListeners();

    if (sharedDbConnected && !syncInProgress) {
      syncSharedDb();
    }
  }

  Future<void> deleteRawCategory(int id, dynamic oldText) async {
    await DatabaseHelper().deleteCategory(id);
    rawCategories.removeWhere((rcat) => rcat.id == id);
    double transferSpent = categories.where((cat) => cat.categoryId == id).first.spent;
    categories.removeWhere((cat) => cat.categoryId == id);
    categories.where((cat) => cat.categoryId == -1).first.spent += transferSpent;
    autoExpenses.removeWhere((ae) => ae.categoryId == id);
    reloadData();
    calcNotAssignedBudget();
    notifyListeners();

    if (sharedDbConnected && !syncInProgress) {
      syncSharedDb();
    }
  }

  // expenses
  Future<void> addExpense(String category, int categoryId, double amount, String description, String date, int accountId) async {
    bool expenseInPast = dateBeforRange(DateTime.parse(date), budgetRanges[0]['start']!);
    final expense = {
      'amount': amount,
      'description': description,
      'categoryId': categoryId,
      'date': date,
      'accountId': accountId
    };
    await DatabaseHelper().insertExpense(expense);

    if (expenseInPast) {
      BankAccount account = bankAccounts.firstWhere((acc) => acc.id == accountId);
      Map<String, dynamic> updatedVal = {"balance": account.balance - amount};
      await DatabaseHelper().updateBankAccount(updatedVal, accountId);
      await _loadBankAccounts();
    }

    await _loadRanges();
    await _loadBudgets();
    notifyListeners();

    if (sharedDbConnected && !syncInProgress) {
      syncSharedDb();
    }
  }

  Future<void> updateExpense(int id, int categoryId, double amount, String description, String date, int accountId) async {
    bool expenseInPast = dateBeforRange(DateTime.parse(date), budgetRanges[0]['start']!);
    double oldAmount = (expenseInPast) ? (await DatabaseHelper().getExpense(id))['amount'] as double : 0;

    final expense = {
      'id': id,
      'amount': amount,
      'description': description,
      'categoryId': categoryId,
      'date': date,
      'accountId': accountId
    };

    await DatabaseHelper().updateExpense(expense);
    if (expenseInPast) {
      BankAccount account = bankAccounts.firstWhere((acc) => acc.id == accountId);
      Map<String, dynamic> updatedVal = {"balance": account.balance + oldAmount - amount};
      await DatabaseHelper().updateBankAccount(updatedVal, accountId);
      await _loadBankAccounts();
    }

    await _loadRanges();
    await _loadBudgets();
    notifyListeners();

    if (sharedDbConnected && !syncInProgress) {
      syncSharedDb();
    }
  }

  Future<void> deleteExpense(int id, String date, int accountId) async {
    bool expenseInPast = dateBeforRange(DateTime.parse(date), budgetRanges[0]['start']!);
    double oldAmount = (expenseInPast) ? (await DatabaseHelper().getExpense(id))['amount'] as double : 0;
    final expense = {
      'id': id
    };
    await DatabaseHelper().deleteExpense(expense);

    if (expenseInPast) {
      BankAccount account = bankAccounts.firstWhere((acc) => acc.id == accountId);
      Map<String, dynamic> updatedVal = {"balance": account.balance + oldAmount};
      await DatabaseHelper().updateBankAccount(updatedVal, accountId);
      await _loadBankAccounts();
    }

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
        statistics = (await DatabaseHelper().lastMonthsTotal(budgetRanges, filterBudget));
      case "month_by_cat":
        statistics = (await DatabaseHelper().statisticMonthTotalByCat(budgetRanges[range], filterBudget));
      case "history_by_cat":
        statistics = (await DatabaseHelper().lastMonthsByCat(budgetRanges, filterBudget));
      // month_total
      default:
        statistics = (await DatabaseHelper().statisticMonthTotal(budgetRanges[range], filterBudget));
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
    return (await sharedDb.changeBlockStatus(sharedDbUrl, newStatus, uuid));
  }
}
