import 'package:jne_household_app/database_helper.dart';

class Settings {
  int? id;
  late String currency;
  late String language;
  late String lastAutoExpenseRun;
  late String filterBudget;
  late String lastAdFail;
  late String lastAdSuccess;
  late String lastSavingRun;
  late String sharedDbUrl;
  late String syncMode;
  late String lastSync;
  late String reminder;
  late String lastCreditCardRefillRun;

  late int syncFrequency;
  late int lastProcessedBatchId;
  late int selectedScanCategory;

  late bool isDesktopPro;
  late bool lockApp;
  late bool useBalance;
  late bool isPro;
  late bool showAvailableBudget;
  late bool includePlanned;

  Settings(Map<String, dynamic> values) {
    id = values['id'] as int;
    currency = values['currency'] as String;
    language = values['language'] as String;
    lastAutoExpenseRun = values['lastAutoExpenseRun'] as String;
    filterBudget = values['filterBudget'] as String;
    lastAdFail = values['lastAdFail'] as String;
    lastAdSuccess = values['lastAdSuccess'] as String;
    lastSavingRun = values['lastSavingRun'] as String;
    sharedDbUrl = values['sharedDbUrl'] as String;
    syncMode = values['syncMode'] as String;
    lastSync = values['lastSync'] as String;
    reminder = values['reminder'] as String;
    lastCreditCardRefillRun = values['lastCreditCardRefillRun'] as String;

    syncFrequency = values['syncFrequency'] is int ? values['syncFrequency'] : int.tryParse(values['syncFrequency']) ?? values['syncFrequency'];
    lastProcessedBatchId = values['lastProcessedBatchId'] is int ? values['lastProcessedBatchId'] : int.tryParse(values['lastProcessedBatchId']) ?? values['lastProcessedBatchId'];
    selectedScanCategory = values['selectedScanCategory'] is int ? values['selectedScanCategory'] : int.tryParse(values['selectedScanCategory']) ?? values['selectedScanCategory'];

    isDesktopPro = values['isDesktopPro'] == 1 || values['isDesktopPro'] == "1";
    lockApp = values['lockApp'] == 1 || values['lockApp'] == "1";
    useBalance = values['useBalance'] == 1 || values['useBalance'] == "1";
    isPro = values['isPro'] == 1 || values['isPro'] == "1";
    showAvailableBudget = values['showAvailableBudget'] == 1 || values['showAvailableBudget'] == "1";
    includePlanned = values['includePlanned'] == 1 || values['includePlanned'] == "1";
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "currency": currency,
      "language": language,
      "lastAutoExpenseRun": lastAutoExpenseRun,
      "filterBudget": filterBudget,
      "lastAdFail": lastAdFail,
      "lastAdSuccess": lastAdSuccess,
      "lastSavingRun": lastSavingRun,
      "sharedDbUrl": sharedDbUrl,
      "syncMode": syncMode,
      "lastSync": lastSync,
      "reminder": reminder,
      "lastCreditCardRefillRun": lastCreditCardRefillRun,

      "syncFrequency": syncFrequency,
      "lastProcessedBatchId": lastProcessedBatchId,
      "selectedScanCategory": selectedScanCategory,

      "isDesktopPro": isDesktopPro ? 1 : 0,
      "lockApp": lockApp ? 1 : 0,
      "useBalance": useBalance ? 1 : 0,
      "isPro": isPro ? 1 : 0,
      "showAvailableBudget": showAvailableBudget ? 1 : 0,
      "includePlanned": includePlanned ? 1 : 0
    };
  }

  Future<void> save() async {
    final values = toMap();
    await DatabaseHelper().genericUpdate("settings", values);
  }
}