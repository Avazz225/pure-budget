import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jne_household_app/logger.dart';

import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/design_state.dart';
import 'package:jne_household_app/models/settings.dart';
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
    Settings settings = await dbHelper.getSettings();

    // execute asnyc jobs
    Logger().debug("Processing background jobs", tag: "initialization Service");
    await backgroundJobs(dbHelper: dbHelper, lastAutoExpenseRun: settings.lastAutoExpenseRun);
    Logger().debug("Processing background jobs done.", tag: "initialization Service");

    // refresh settings
    settings = await dbHelper.getSettings();

    // update filter
    String filter = settings.filterBudget;

    // read money flows
    final moneyFlows = await dbHelper.getMoneyFlows();

    // read rest of data
    final bankAccounts = await dbHelper.getBankAccounts(moneyFlows);
    if (bankAccounts.where((acc) => acc.id.toString() == filter).isEmpty){
      filter = "*";
    }
    final categories = await dbHelper.getCategories(filter);
    final autoExpenses = await dbHelper.getAutoExpenses();
    final totalBalance = (await dbHelper.getTotalBudget(filter))[settings.useBalance ? 'totalBalance' : 'totalIncome'];
    
    Map<String, dynamic> resetInfo;

    // read resetInfo
    if (filter == "*") {
      resetInfo = {"principle": bankAccounts[0].budgetResetPrinciple, "day":bankAccounts[0].budgetResetDay};
    } else {
      resetInfo = {"principle": bankAccounts.where((acc) => acc.id == int.tryParse(filter)).first.budgetResetPrinciple, "day": bankAccounts.where((acc) => acc.id == int.tryParse(filter)).first.budgetResetDay};
    }

    // determine whether app has been set up
    bool isSetupComplete = (bankAccounts[0].balance != 0.00 || bankAccounts[0].income != 0.00 || categories.length != 1);

    // Initialize BudgetState
    final budgetState = await BudgetState.initialize(
      totalBudget: totalBalance,
      rawCategories: categories,
      resetInfo: resetInfo,
      autoExpenses: autoExpenses,
      isSetupComplete: isSetupComplete,
      bankAccounts: bankAccounts,
      moneyFlows: moneyFlows,
      settings: settings
    );

    // Load language settings (if set manually)
    if (settings.language != "auto") {
      await I18n.load(settings.language, saveWidgetData: budgetState.saveWidgetData);
    }

    Map<String, dynamic> designData = await dbHelper.genericSelect("design", onlyFirst: true);

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
      mainMenuStyle: designData["mainMenuStyle"] as int,
      blurIntensity: designData["blurIntensity"] as double,
      customGradient: designData["customGradient"] as String,
      intervalStyle: designData["intervalStyle"] as int
    );

    // Initialize date formatting
    await initializeDateFormatting(defaultLocale.toString());

    return InitializationData(budgetState: budgetState, designState: designState);
  }
}