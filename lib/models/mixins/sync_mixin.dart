import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/settings.dart';
import 'package:jne_household_app/shared_database/shared_database.dart';

/// Handles shared-database connection and sync lifecycle.
mixin SyncMixin on ChangeNotifier {
  // ── State accessors (implemented by BudgetState) ──────────────────────────
  Settings get settings;
  SharedDatabase get sharedDb;
  bool get sharedDbConnected;
  set sharedDbConnected(bool v);
  bool get syncInProgress;
  set syncInProgress(bool v);

  // ── Methods this mixin calls on BudgetState ───────────────────────────────
  Future<void> reloadData();

  // ── Mixin implementation ──────────────────────────────────────────────────

  Future<bool> initSharedDb() async {
    final status = await sharedDb.initSharedDatabase(
      settings.sharedDbUrl,
      settings.isPro,
      newConnection: true,
    );
    if (status != sharedDbConnected && !status) {
      sharedDbConnected = status;
      notifyListeners();
      return false;
    } else {
      sharedDbConnected = status;
      if (!status) return false;
      syncSharedDb();
      return true;
    }
  }

  Future<void> syncSharedDb({bool manual = false, bool changeKey = false}) async {
    final db = DatabaseHelper();
    if (settings.syncMode == "frequently" && !manual) {
      final lastSync = await db.getLastSync();
      if (lastSync.add(Duration(seconds: settings.syncFrequency)).isBefore(DateTime.now())) {
        manual = true;
      }
    }

    if (settings.syncMode == "instant" || manual) {
      syncInProgress = true;
      notifyListeners();
      final result = await sharedDb.syncWithRemote(
        settings.sharedDbUrl,
        changeEncryptKey: changeKey,
        isPro: settings.isPro,
      );
      if (result[0]) {
        sharedDbConnected = true;
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          settings.isPro = result[1];
          await settings.save();
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

  Future<List<Map<String, dynamic>>> getRegisteredRemoteDevices() async {
    return sharedDb.getRegisteredDevices(settings.sharedDbUrl);
  }

  Future<bool> updateRemoteDeviceMetadata(String uuid, Map<String, dynamic> metadata) async {
    return sharedDb.updateRegisteredDeviceMetadata(settings.sharedDbUrl, uuid, metadata);
  }

  Future<bool> changeBlockStatus(int newStatus, String uuid) async {
    return sharedDb.changeBlockStatus(settings.sharedDbUrl, newStatus, uuid);
  }
}
