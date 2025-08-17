import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/design_state.dart';
import 'package:jne_household_app/services/background_jobs.dart';

class InitializationData {
  final BudgetState budgetState;
  final DesignState designState;

  InitializationData({required this.budgetState, required this.designState});
}

class InitializationService {
  static Future<InitializationData> initializeApp() async {
    // set language
    final defaultLocale = PlatformDispatcher.instance.locale;
    await I18n.load(defaultLocale.toString(), locale: defaultLocale);

    // create database connector
    DatabaseHelper dbHelper = DatabaseHelper();

    // get settings
    Map<String, dynamic> settings = await dbHelper.getSettings();

    // execute asnyc jobs
    await backgroundJobs(dbHelper: dbHelper, lastAutoExpenseRun: settings['lastAutoExpenseRun']);

    // refresh settings
    settings = await dbHelper.getSettings();

    // update filter
    String filter = settings['filterBudget'].toString();

    // read money flows
    final moneyFlows = await dbHelper.getMoneyFlows();

    // read rest of data
    final bankAccounts = await dbHelper.getBankAccounts(moneyFlows);
    if (bankAccounts.where((acc) => acc.id.toString() == filter).isEmpty){
      filter = "*";
    }
    final categories = await dbHelper.getCategories(filter);
    final autoExpenses = await dbHelper.getAutoExpenses();
    final totalBalance = (await dbHelper.getTotalBudget(filter))[settings['useBalance'] == 1 ? 'totalBalance' : 'totalIncome'];
    
    Map<String, dynamic> resetInfo;

    // read resetInfo
    if (filter == "*") {
      resetInfo = {"principle": bankAccounts[0].budgetResetPrinciple, "day":bankAccounts[0].budgetResetDay};
    } else {
      resetInfo = {"principle": bankAccounts.where((acc) => acc.id == int.tryParse(filter)).first.budgetResetPrinciple, "day": bankAccounts.where((acc) => acc.id == int.tryParse(filter)).first.budgetResetDay};
    }

    // Load language settings (if set manually)
    if (settings['language'] != "auto") {
      await I18n.load(settings['language']);
    }

    // determine whether app has been set up
    bool isSetupComplete = (bankAccounts[0].balance != 0.00 || settings['currency'] != "€" || bankAccounts[0].income != 0.00 || categories.length != 1);

    // Initialize BudgetState
    final budgetState = await BudgetState.initialize(
      totalBudget: totalBalance,
      rawCategories: categories,
      currency: settings['currency'] ?? "€",
      resetInfo: resetInfo,
      language: settings['language'],
      includePlanned: settings['includePlanned'] == 1,
      autoExpenses: autoExpenses,
      showAvailableBudget: settings['showAvailableBudget'] == 1,
      isPro: settings['isPro'] == 1,
      isSetupComplete: isSetupComplete,
      filterBudget: filter,
      useBalance: settings['useBalance'] == 1,
      bankAccounts: bankAccounts,
      moneyFlows: moneyFlows,
      sharedDbUrl: settings['sharedDbUrl'],
      syncMode: settings['syncMode'],
      syncFrequency: settings['syncFrequency'],
      lockApp: settings['lockApp'] == 1,
      isDesktopPro: settings['isDesktopPro'] == 1,
      selectedScanCategory: settings['selectedScanCategory']
    );

    Map<String, dynamic> designData = await dbHelper.getDesignData();

    final designState = DesignState.initialize(
      layoutMainVertical: designData["layoutMainVertical"] == 1,
      categoryMainStyle: designData["categoryMainStyle"] as int,
      addExpenseStyle: designData["addExpenseStyle"] as int,
      arcStyle: designData["arcStyle"] as int,
      arcSegmentsRounded: designData["arcSegmentsRounded"] == 1,
      arcWidth: designData["arcWidth"] as double,
      arcPercent: designData["arcPercent"] as double,
      dialogSolidBackground: designData["dialogSolidBackground"] == 1,
      appBackgroundSolid: designData["appBackgroundSolid"] == 1,
      appBackground: designData["appBackground"] as int,
      customBackgroundPath: designData["customBackgroundPath"] as String,
      customBackgroundBlur: designData["customBackgroundBlur"] == 1,
      mainMenuStyle: designData["mainMenuStyle"] as int
    );

    // Initialize date formatting
    await initializeDateFormatting(defaultLocale.toString());

    return InitializationData(budgetState: budgetState, designState: designState);
  }
}