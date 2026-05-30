import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/bankaccount.dart';
import 'package:jne_household_app/models/settings.dart';
import 'package:jne_household_app/services/remote/auth.dart';

/// Handles all Settings mutations (currency, pro, sync mode, language, etc.)
/// and the shared-DB URL lifecycle.
mixin SettingsMutationsMixin on ChangeNotifier {
  // ── State accessors ───────────────────────────────────────────────────────
  Settings get settings;
  double get totalBudget;
  set totalBudget(double v);
  List<BankAccount> get bankAccounts;
  bool get sharedDbConnected;
  set sharedDbConnected(bool v);

  // ── Methods this mixin calls on BudgetState / SyncMixin ───────────────────
  Future<void> reloadData();
  Future<void> loadBudgets({int? overrideRange});
  void calcNotAssignedBudget();
  Future<void> saveWidgetData(String id, dynamic data);
  Future<bool> initSharedDb();
  Future<void> syncSharedDb({bool manual = false, bool changeKey = false});

  // ── Settings mutations ────────────────────────────────────────────────────

  Future<void> updateFrequency(int value, String mode) async {
    switch (mode) {
      case "days":   value *= 60 * 60 * 24;
      case "hours":  value *= 60 * 60;
      case "minutes":value *= 60;
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
    await loadBudgets();
    notifyListeners();
  }

  Future<void> updateIsPro(bool pro) async {
    settings.isPro = pro;
    await settings.save();
    await loadBudgets();
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
    final ret = await DatabaseHelper().getTotalBudget(settings.filterBudget);
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
    saveWidgetData("settings.showAvailableBudget", available ? "true" : "false");
    saveWidgetData(
      "totalConnector",
      settings.showAvailableBudget ? I18n.translate("availableStr") : I18n.translate("spentStr"),
    );
  }

  Future<void> updateLanguage(String code) async {
    settings.language = code;
    await settings.save();
    final langCode = (code != "auto") ? code : PlatformDispatcher.instance.locale.toString();
    await I18n.load(langCode, saveWidgetData: saveWidgetData);
    notifyListeners();
    saveWidgetData(
      "totalConnector",
      settings.showAvailableBudget ? I18n.translate("availableStr") : I18n.translate("spentStr"),
    );
    saveWidgetData("totalFrom", I18n.translate("from"));
  }

  Future<bool> updateSharedDbUrl(String url) async {
    settings.sharedDbUrl = url;
    await settings.save();

    if (url != "none") {
      final result = await initSharedDb();
      if (!result) {
        settings.sharedDbUrl = "none";
        await settings.save();
        return false;
      }
    } else {
      const keys = [
        'encryption_key',
        'googleAccessToken', 'googleRefreshToken', 'googleDriveItemId',
        'iCloudAccessTokenJson', 'iCloudItemId',
        'oneDriveAccessTokenJson', 'oneDriveItemId',
        'smbHost', 'smbUname', 'smbPwd', 'smbDom',
      ];
      for (final key in keys) {
        await deleteKey(key);
      }
      sharedDbConnected = false;
      notifyListeners();
    }
    return true;
  }
}
