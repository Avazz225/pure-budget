import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/services/background_jobs.dart';

class InitializationData {
  final BudgetState budgetState;

  InitializationData({required this.budgetState});
}

class InitializationService {
  static Future<InitializationData> initializeApp() async {

    if (kDebugMode) {
      debugPrint("Running init service");
    }

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
      lockApp: settings['lockApp'] == 1
    );

    // Initialize date formatting
    await initializeDateFormatting(defaultLocale.toString());

    return InitializationData(budgetState: budgetState);
  }
}