// ignore_for_file: collection_methods_unrelated_type

import 'dart:convert';
import 'dart:io';
import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/models/settings.dart';
import 'package:jne_household_app/services/remote/auth.dart' as auth;
import 'package:jne_household_app/services/remote/google_drive_connector.dart';
import 'package:jne_household_app/services/remote/one_drive_connector.dart';
import 'package:jne_household_app/services/remote/smb_server.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/shared_database/encryption_handler.dart';
import 'package:jne_household_app/shared_database/network_handler.dart';
// ignore: unnecessary_import
import 'package:sqflite/sqflite.dart';  // mobile specific
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // desktop specific
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

const sharedFileName = "/pureBudgetRemoteDatabase.pbdb";

Future<bool> checkRemoteDbExists(String sharedDbFilePath) async {
  if (sharedDbFilePath == "none") return false;

  if (sharedDbFilePath.startsWith("gdrive://")) {
    return await GoogleDriveConnector().checkExistence(sharedDbFilePath, sharedFileName);
  } else if (sharedDbFilePath.startsWith("onedrive://")) {
    return await OneDriveConnector().checkExistence(sharedDbFilePath, sharedFileName);
  } else if (sharedDbFilePath.startsWith("smb://")) {
    return await SMBServer().checkExistence(sharedDbFilePath, sharedFileName);
  } else {
    final remoteDbFile = File(sharedDbFilePath + sharedFileName);
    return await remoteDbFile.exists();
  }
}

class SharedDatabase {
  final DatabaseHelper localDb;
  late final File tempRemoteDbCopyFile;
  final int remoteDbVersion = 9;
  final _logger = Logger();
  int totalChanges = 0;

  SharedDatabase(this.localDb);

  
  Future<void> _createTables(Database db) async {
    await db.execute('CREATE TABLE expenses(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT, amount REAL, accountId INTEGER DEFAULT -1, categoryId INTEGER, description TEXT, auto INTEGER DEFAULT 0, autoId INTEGER DEFAULT -1)');
    await db.execute('CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, color TEXT, position INTEGER)');
    await db.execute('CREATE TABLE autoexpenses (id INTEGER PRIMARY KEY AUTOINCREMENT, amount REAL, accountId INTEGER DEFAULT -1, categoryId INTEGER, description TEXT, bookingPrinciple TEXT, bookingDay INTEGER, principleMode TEXT DEFAULT "monthly", receiverAccountId DEFAULT -1, moneyFlow INTEGER DEFAULT 0, ratePayment INTEGER DEFAULT 0, rateCount INTEGER, firstRateAmount REAL, lastRateAmount REAL)');
    await db.execute('CREATE TABLE bankaccounts (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, balance REAL, income REAL, description TEXT, budgetResetPrinciple TEXT, budgetResetDay INTEGER, lastSavingRun TEXT DEFAULT "none", isCreditCard INTEGER DEFAULT 0, refillsFrom INTEGER DEFAULT -1, refillPrincipleMode TEXT DEFAULT "monthly")');
    await db.execute('CREATE TABLE categoryBudgets(id INTEGER PRIMARY KEY AUTOINCREMENT, categoryId INTEGER, accountId INTEGER, budget REAL, overrideBankAccount INTEGER DEFAULT null)');
    await db.execute('CREATE TABLE editLog (id INTEGER PRIMARY KEY AUTOINCREMENT, affectedTable TEXT, affectedId INTEGER, type TEXT, sharedBatchId INTEGER DEFAULT -1)');
    await db.execute('CREATE TABLE registeredDevices (id TEXT PRIMARY KEY, deviceMetadata TEXT, isPro INTEGER DEFAULT 0, blocked INTEGER DEFAULT 0)');
    await db.execute('CREATE TABLE creditCardRefills (id INTEGER PRIMARY KEY AUTOINCREMENT, accountId INTEGER, creditAccountId INTEGER, amount REAL, date TEXT, categoryId INTEGER)');
    await db.execute('CREATE TABLE intervals (id INTEGER PRIMARY KEY, start TEXT, end TEXT, accountId INTEGER)');
    await db.execute('CREATE TABLE realizedCategoryBudgets (id INTEGER PRIMARY KEY, intervalId INTEGER, accountId INTEGER, categoryId INTEGER, budget REAL, overrideBankAccount INTEGER DEFAULT null)');
    await db.execute('CREATE TABLE realizedBankaccounts (id INTEGER PRIMARY KEY, intervalId INTEGER, accountId INTEGER, balance REAL, income REAL)');
    await db.execute('CREATE TABLE realizedAutoexpenses (id INTEGER PRIMARY KEY, intervalId INTEGER, autoexpenseId INTEGER, expenseId INTEGER)');
  }

  Future<void> _upgradeTables(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('CREATE TABLE registeredDevices (id TEXT PRIMARY KEY, deviceMetadata TEXT, isPro INTEGER DEFAULT 0, blocked INTEGER DEFAULT 0)');
    }
    if (oldVersion < 3) {
      await db.execute("DROP TABLE IF EXISTS registeredDevices");
      await db.execute('CREATE TABLE registeredDevices (id TEXT PRIMARY KEY, deviceMetadata TEXT, isPro INTEGER DEFAULT 0, blocked INTEGER DEFAULT 0)');
    }
    if (oldVersion < 4) {
      await db.execute('''ALTER TABLE autoexpenses ADD COLUMN ratePayment INTEGER DEFAULT 0''');
      await db.execute('''ALTER TABLE autoexpenses ADD COLUMN rateCount INTEGER''');
      await db.execute('''ALTER TABLE autoexpenses ADD COLUMN firstRateAmount REAL''');
      await db.execute('''ALTER TABLE autoexpenses ADD COLUMN lastRateAmount REAL''');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE bankaccounts ADD COLUMN isCreditCard INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE bankaccounts ADD COLUMN refillsFrom INTEGER DEFAULT -1');
      await db.execute('ALTER TABLE bankaccounts ADD COLUMN refillPrincipleMode TEXT DEFAULT "monthly"');
    }
    if (oldVersion < 6) {
      await db.execute('CREATE TABLE creditCardRefills (id INTEGER PRIMARY KEY AUTOINCREMENT, accountId INTEGER, creditAccountId INTEGER, amount REAL, date TEXT)');
    }
    if( oldVersion < 7) {
      await db.execute('ALTER TABLE creditCardRefills ADD COLUMN categoryId INTEGER');
    }
    if (oldVersion < 8) {
      await db.execute('ALTER TABLE categoryBudgets ADD COLUMN overrideBankAccount INTEGER DEFAULT null');
    }
    if (oldVersion < 9) {
      await db.execute('CREATE TABLE intervals (id INTEGER PRIMARY KEY, start TEXT, end TEXT, accountId INTEGER)');
      await db.execute('CREATE TABLE realizedCategoryBudgets (id INTEGER PRIMARY KEY, intervalId INTEGER, accountId INTEGER, categoryId INTEGER, budget REAL, overrideBankAccount INTEGER DEFAULT null)');
      await db.execute('CREATE TABLE realizedBankaccounts (id INTEGER PRIMARY KEY, intervalId INTEGER, accountId INTEGER, balance REAL, income REAL)');
      await db.execute('CREATE TABLE realizedAutoexpenses (id INTEGER PRIMARY KEY, intervalId INTEGER, autoexpenseId INTEGER, expenseId INTEGER)');
    }
  }

  Future<void> initialize() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS){
      final tempDir = await getApplicationSupportDirectory();
      tempRemoteDbCopyFile = File('${tempDir.path}/temp_remote_db.sqlite');
    } else {
      final tempDir = await getTemporaryDirectory();
      tempRemoteDbCopyFile = File('${tempDir.path}/temp_remote_db.sqlite');
    }
  }

  Future<bool> initSharedDatabase(sharedDbFilePath, isPro, {newConnection = false}) async {
    if (sharedDbFilePath == "none") return false;

    try {
      final remoteDbExists = await checkRemoteDbExists(sharedDbFilePath);
      if (!remoteDbExists) {
        await EncryptionHelper.generateKey();
        // init new database
        final newRemoteDb = await openDatabase(tempRemoteDbCopyFile.absolute.path, version: remoteDbVersion, onCreate: (db, version) async {
          await _createTables(db);
        });

        // insert local database into remote db
        await _initialDbSync(await localDb.database, newRemoteDb, true);
        await _registerDevice(newRemoteDb, isPro);
        await newRemoteDb.close();

        // upload database to directory
        
        await uploadFile(sharedDbFilePath, tempRemoteDbCopyFile);

        _logger.debug("Initialized and uploaded new shared database", tag: "sharedDatabase");
        
        tempRemoteDbCopyFile.deleteSync();
        return true;
      } else {
        // Download existing remote database for upgrade check
        bool success = await downloadFile(sharedDbFilePath, tempRemoteDbCopyFile);
        if (!success) {
          throw Exception("DB download failed.");
        }

        Settings settings = await localDb.getSettings();
        if (newConnection) {
          await localDb.resetDatabase(true);
          settings.lastProcessedBatchId = -1;

        }

        List result = await syncWithRemote(sharedDbFilePath, initial: true, isPro: isPro);
        settings.isPro = result[1];
        await settings.save();

        return result[0];
      }
    } catch (e) {
      _logger.info("Could not reach shared database: $e", tag: "sharedDatabase");
      return false;
    }
  }

  Future<List<dynamic>> _registerDevice(Database remoteDatabase, bool isPro) async {
    // returns: success, newly registered
    try {
      Map<String, dynamic> metadataRaw = {
        "platform": Platform.operatingSystem,
        "version": Platform.operatingSystemVersion,
      };
      String metadata = jsonEncode(metadataRaw);

      String uuid = await auth.loadKey("pureBudgetDeviceId");

      if (uuid == "") { 
        uuid = const Uuid().v4();
        await auth.saveKey(uuid, "pureBudgetDeviceId");
      }

      _logger.debug("Registering device with id $uuid", tag: "sharedDatabase");
      _logger.debug(metadata, tag: "sharedDatabase");
      
      List<Map<String, dynamic>> device = await remoteDatabase.query("registeredDevices", where: "id = ?", whereArgs: [uuid]);
      _logger.debug(device.toString(), tag: "sharedDatabase");

      if (device.isEmpty) {
        _logger.debug("-> initial registration", tag: "sharedDatabase");
        await remoteDatabase.insert(
        "registeredDevices", 
          {
            "id": uuid,
            "deviceMetadata": metadata,
            "isPro": (isPro && (Platform.isAndroid || Platform.isIOS)) ? "1" : "0"
          },
          conflictAlgorithm: ConflictAlgorithm.ignore
        );
        return [true, true];
      } else if (device[0]['blocked'] == 1) {
        return [false, {
            "id": uuid,
            "deviceMetadata": metadata,
            "isPro": (isPro && (Platform.isAndroid || Platform.isIOS)) ? "1" : "0",
            "blocked": 1
          }];
      } else {
        _logger.debug("-> updating device registration", tag: "sharedDatabase");
        Map<String, dynamic> oldMetadata = jsonDecode(device[0]['deviceMetadata']);

        if (oldMetadata.containsKey("customname")) {
          metadataRaw['customname'] = oldMetadata['customname'];
          metadata = jsonEncode(metadataRaw);
        }

        Map<String, dynamic> updateData = {
          "deviceMetadata": metadata,
          'isPro': (isPro && (Platform.isAndroid || Platform.isIOS)) ? 1 : 0
        };

        await remoteDatabase.update(
          "registeredDevices", 
          updateData,
          where: "id = ?",
          whereArgs: [uuid]
        );
        return [true, false];
      }
    } catch (e) {
      _logger.error("Could not register device: $e", tag: "sharedDatabase");
      throw Exception("Device register failed");
    }
  }

  Future<bool> updateRegisteredDeviceMetadata(String sharedDbFilePath, String uuid, Map<String, dynamic> metadata) async {
    try {
      // Download existing remote database for upgrade check
      bool success = await downloadFile(sharedDbFilePath, tempRemoteDbCopyFile);
      if (!success) {
        throw Exception("DB download failed.");
      }

      final remoteDb = await openDatabase(
        tempRemoteDbCopyFile.absolute.path,
        readOnly: false,
        version: remoteDbVersion,
        onUpgrade: (db, oldVersion, newVersion) async {
          await _upgradeTables(db, oldVersion, newVersion);
        }
      );

      remoteDb.update("registeredDevices", {"deviceMetadata": jsonEncode(metadata)}, where: "id = ?", whereArgs: [uuid]);
      remoteDb.close();
  
      await uploadFile(sharedDbFilePath, tempRemoteDbCopyFile);
      tempRemoteDbCopyFile.deleteSync();
      return true;
    } catch (e) {
      _logger.info("Could not reach shared database: $e", tag: "sharedDatabase");
      return false;
    }
  }

  Future<void> _initialDbSync(Database localDatabase, Database remoteDatabase, bool localToRemote) async {
    List<String> tables = ['expenses', 'categories', 'autoexpenses', 'bankaccounts', 'categoryBudgets'];
    final batchId = DateTime.now().millisecondsSinceEpoch;
    List<Map<String, dynamic>> results;

    for (String table in tables) {
      if (localToRemote) {
        results = await localDatabase.query(table);
      } else {
        results = await remoteDatabase.query(table);
      }

      if (localToRemote) {
        await remoteDatabase.transaction((txn) async {
          for (Map<String, dynamic> entry in results) {
            txn.insert(table, entry, conflictAlgorithm: ConflictAlgorithm.replace);
            txn.insert("editLog", {"affectedTable": table, "affectedId": entry['id'], "type": "insert", "sharedBatchId": batchId});
          }
        });
      } else {
        await localDatabase.transaction((txn) async {
          for (Map<String, dynamic> entry in results) {
            txn.insert(table, entry, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        });
      }
    }

    localDatabase.update("settings", {"lastProcessedBatchId": batchId});
  }

  Future<List<Map<String, dynamic>>> getRegisteredDevices(sharedDbFilePath) async {
    try {
      bool success = await downloadFile(sharedDbFilePath, tempRemoteDbCopyFile);
      if (!success) {
        throw Exception("downloadFail");
      }

      final remoteDb = await openDatabase(
        tempRemoteDbCopyFile.absolute.path,
        readOnly: false,
        version: remoteDbVersion,
        onUpgrade: (db, oldVersion, newVersion) async {
          await _upgradeTables(db, oldVersion, newVersion);
        }
      );

      List<dynamic> res = await _registerDevice(remoteDb, false);
      bool banned = !res[0];
      if (banned) {
        return [res[1]];
      }

      List<Map<String, dynamic>> result = await remoteDb.query("registeredDevices");
      await remoteDb.close();
      tempRemoteDbCopyFile.deleteSync();

      return result;
    } catch (e) {
      _logger.warning("Read error: $e", tag: "sharedDatabase");
      return [];
    }
  }

  Future<bool> changeBlockStatus(String sharedDbFilePath, int newStatus, String uuid) async {
    bool success = await downloadFile(sharedDbFilePath, tempRemoteDbCopyFile);
    if (!success) {
      throw Exception("downloadFail");
    }

    final remoteDb = await openDatabase(
      tempRemoteDbCopyFile.absolute.path,
      readOnly: false,
      version: remoteDbVersion,
      onUpgrade: (db, oldVersion, newVersion) async {
        await _upgradeTables(db, oldVersion, newVersion);
      }
    );

    await remoteDb.update("registeredDevices", {"blocked": newStatus}, where: "id = ?", whereArgs: [uuid]);
    await remoteDb.close();
    await uploadFile(sharedDbFilePath, tempRemoteDbCopyFile);
    tempRemoteDbCopyFile.deleteSync();

    return true;
  }

  Future<List<bool>> syncWithRemote(sharedDbFilePath, {initial = false, isPro = false, changeEncryptKey = false}) async {
    // returns: successful, proStatusinDB, lockedOut

    // no path for shared database
    if (sharedDbFilePath == "none") return [false, false, false];

    totalChanges = 0;
    try {
      // download database file
      bool success = await downloadFile(sharedDbFilePath, tempRemoteDbCopyFile);
      // if failed raise exception
      if (!success) {
        throw Exception("downloadFail");
      }

      // open database connection
      final remoteDb = await openDatabase(
        tempRemoteDbCopyFile.absolute.path,
        readOnly: false,
        version: remoteDbVersion,
        onUpgrade: (db, oldVersion, newVersion) async {
          await _upgradeTables(db, oldVersion, newVersion);
        }
      );

      // re-register device, return false if device is blocked and abort
      List<dynamic> registerResult = (await _registerDevice(remoteDb, isPro));
      bool banned = !registerResult[0];

      if (banned) {
        await remoteDb.close();
        tempRemoteDbCopyFile.deleteSync();
        throw Exception("lockedOut");
      } else if (registerResult[1]) {
        totalChanges++;
      }
      // handle realized* and intervals separately
      totalChanges += await _handleRealizedAndIntervals(remoteDb);

      // push local changes to remote database (important so no id conflict occur)
      await _pushChangesToRemote(remoteDb);
      // pull remote changes to local
      bool hasPro = await _pullChangesFromRemote(remoteDb);
      await remoteDb.close();

      // generate new encryption key if requested
      if (changeEncryptKey) {
        await EncryptionHelper.generateKey();
      }

      // upload remote db file to remote path
      if (totalChanges > 0 || changeEncryptKey) {
        await uploadFile(sharedDbFilePath, tempRemoteDbCopyFile);
      } else{
        _logger.debug("Skipping upload no upstream changes.", tag: "sharedDatabase");
      }

      // delete local copy
      tempRemoteDbCopyFile.deleteSync();

      return [true, (hasPro || ((Platform.isAndroid || Platform.isIOS && isPro)))];
    } catch (e) {
      _logger.debug("Sync error: $e", tag: "sharedDatabase");
      if (e == "lockedOut") {
        return [false, false, true];
      }
      return [false, false, false];
    }
  }

  Future<int> _handleRealizedAndIntervals(Database remoteDb) async {
    final localDatabase = await localDb.database;
    if (!await tempRemoteDbCopyFile.exists()) {
      throw Exception("Shared database file does not exist: ${tempRemoteDbCopyFile.path}");
    }


    try {
      // get all relevant changes from remote and local which require handling
      final List<Map<String, dynamic>> relevantRemoteChanges = await remoteDb.rawQuery(
        'SELECT * FROM editLog WHERE affectedTable IN ("realizedBankaccounts", "realizedCategoryBudgets", "realizedAutoexpenses", "intervals") AND sharedBatchId > ?',
        [await localDatabase.query('settings', columns: ['lastProcessedBatchId'], limit: 1).then((value) => value.first['lastProcessedBatchId'])]
      );

      final List<Map<String, dynamic>> relevantLocalChanges = await localDatabase.rawQuery(
        'SELECT * FROM editLog WHERE affectedTable IN ("realizedBankaccounts", "realizedCategoryBudgets", "realizedAutoexpenses", "intervals") AND sharedBatchId = -1'
      );

      // if either has no relevant changes, return 0
      if (relevantRemoteChanges.isEmpty || relevantLocalChanges.isEmpty) {
        return 0;
      }

      _logger.debug("Handling realized and intervals changes...", tag: "sharedDatabase");

      final batchId = DateTime.now().millisecondsSinceEpoch;

      // process local changes first
      for (final change in relevantLocalChanges) {
        final table = change['affectedTable'] as String;
        final type = change['type'];
        final id = change['affectedId'];

        if (type == 'insert') {
          final immutableData = (await localDatabase.query(
            table,
            where: 'id = ?',
            whereArgs: [id],
          )).first;

          final correspondingRemoteEntry = await _getCorrespondingEntry(remoteDb, immutableData, table);

          if (correspondingRemoteEntry.isEmpty) {
            // Full insert with same ID
            await remoteDb.insert(table, immutableData);
            await _saveSyncedId(localDatabase, table, id, id);
          } else {
            final remoteId = correspondingRemoteEntry['id'];
            if (remoteId != id) {
              await _updateLocalId(localDatabase, table, localId: id, newRemoteId: remoteId);
              await _saveSyncedId(localDatabase, table, id, remoteId);
            }
            final entry = await remoteDb.query(table, where: 'id = ?', whereArgs: [remoteId]).then((value) => value.first);
            await localDatabase.update(
              table,
              entry,
              where: 'id = ?',
              whereArgs: [remoteId],
            );
          }
        }
        else if (type == 'update') {
          // Fetch updated data from local
          final localData = (await localDatabase.query(
            table,
            where: 'id = ?',
            whereArgs: [id],
          )).first;

          // Check for ID mapping
          final synced = await _getSyncedId(localDatabase, table, id);
          final remoteId = synced ?? id;

          if (synced == null && remoteId != id) {
            // ID differs but mapping not stored -> fix local ID
            await _updateLocalId(localDatabase, table, localId: id, newRemoteId: remoteId);
          }

          await remoteDb.update(
            table,
            localData,
            where: 'id = ?',
            whereArgs: [remoteId],
          );
        }
        else if (type == 'delete') {
          final synced = await _getSyncedId(localDatabase, table, id);
          final remoteId = synced ?? id;

          // Interval referential cleanup before delete
          if (table == 'intervals') {
            await _deleteIntervalReferences(remoteDb, remoteId);
          }

          // Delete in remote db
          await remoteDb.delete(
            table,
            where: 'id = ?',
            whereArgs: [remoteId],
          );

          // Remove mapping
          await _removeSyncedId(localDatabase, table, id);
        }

        // Mark change as processed
        await localDatabase.update(
          'editLog',
          {'sharedBatchId': batchId},
          where: 'id = ?',
          whereArgs: [change['id']],
        );
      }
    } catch (e) {
      _logger.error("Error during handling realized and intervals: $e", tag: "sharedDatabase");
      rethrow;
    }

    _logger.debug("Finished realized and intervals changes", tag: "sharedDatabase");

    return 1;
  }

  Future<void> _updateLocalId(Database db, String table,
    {required int localId, required int newRemoteId}) async {

    if (table == "intervals") {
      final relatedTables = [
        "realizedBankaccounts",
        "realizedCategoryBudgets",
        "realizedAutoexpenses"
      ];

      for (final t in relatedTables) {
        await db.update(
          t,
          {"intervalId": newRemoteId},
          where: "intervalId = ?",
          whereArgs: [localId],
        );
      }
    }

    await db.update(
      table,
      {"id": newRemoteId},
      where: "id = ?",
      whereArgs: [localId],
    );
  }

  Future<void> _saveSyncedId(Database db, String table, int localId, int remoteId) async {
    await db.insert(
      "syncedIds",
      {
        "localId": localId,
        "remoteId": remoteId,
        "tableName": table,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int?> _getSyncedId(Database db, String table, int localId) async {
    final res = await db.query(
      "syncedIds",
      where: "localId = ? AND tableName = ?",
      whereArgs: [localId, table],
    );
    if (res.isEmpty) return null;
    return res.first["remoteId"] as int?;
  }

  Future<void> _removeSyncedId(Database db, String table, int localId) async {
    await db.delete(
      "syncedIds",
      where: "localId = ? AND tableName = ?",
      whereArgs: [localId, table],
    );
  }

  Future<void> _deleteIntervalReferences(Database remoteDb, int intervalId) async {
    const relatedTables = [
      "realizedBankaccounts",
      "realizedCategoryBudgets",
      "realizedAutoexpenses",
    ];

    for (final t in relatedTables) {
      await remoteDb.update(
        t,
        {"intervalId": null}, // or delete entire row depending on your business logic
        where: "intervalId = ?",
        whereArgs: [intervalId],
      );
    }
  }

  Future<Map<String, dynamic>> _getCorrespondingEntry(Database localDb, Map<String, dynamic> referenceEntry, String table) async {
    List<String> where = [];
    List<String> whereArgs = [];
    for (String key in referenceEntry.keys) {
      if (key == "id") continue;
      // build where clause
      where.add("$key = ?");
      whereArgs.add(referenceEntry[key].toString());
    }
    final result = await localDb.query(table, where: where.join(" AND "), whereArgs: whereArgs);
    if (result.isNotEmpty) {
      return result.first;
    } else { 
      return {};
    }
  }

  Future<void> _pushChangesToRemote(Database remoteDb) async {
    final localDatabase = await localDb.database;

    if (!await tempRemoteDbCopyFile.exists()) {
      throw Exception("Shared database file does not exist: ${tempRemoteDbCopyFile.path}");
    }


    try {
      List<Map<String, dynamic>> changes = await localDatabase.rawQuery(
        'SELECT * FROM editLog WHERE sharedBatchId = -1'
      );

      _logger.debug("Upstream pushing changes, total: ${changes.length}", tag: "sharedDatabase");
      
      totalChanges += changes.length;

      if (changes.isEmpty) {
        return;
      }

      
      final batchId = DateTime.now().millisecondsSinceEpoch;
      List<Map<String, dynamic>> changedIds = [];
      await remoteDb.transaction((txn) async {
        for (Map<String, dynamic> change in changes) {
          try {
            final table = change['affectedTable'] as String;

            if (["realizedBankaccounts", "realizedCategoryBudgets", "realizedAutoexpenses", "intervals"].contains(table)) {
              continue;
            }

            final type = change['type'];
            int id = change['affectedId'];

            if (type == 'insert') {
              List<Map<String, dynamic>> immutableData = await localDatabase.query(table, where: 'id = ?', whereArgs: [id]);
              List<Map<String, dynamic>> data = List.from(
                  immutableData.map((map) => Map<String, dynamic>.from(map))
              );
              
              if (data.first.keys.contains("sharedBatchId")) {
                data.first.remove("sharedBatchId");
              }

              if (data.isNotEmpty) {
                final entry = Map<String, dynamic>.from(data.first)..remove("id");
                final newId = await txn.insert(table, entry);
                if (newId != id) {
                  changedIds.add({"table": table, "oldId": id, "newId": newId});
                  id = newId;
                }
              }
            } else if (type == 'update') {
              List<Map<String, dynamic>> immutableData = await localDatabase.query(table, where: 'id = ?', whereArgs: [id]);
              List<Map<String, dynamic>> data = List.from(
                  immutableData.map((map) => Map<String, dynamic>.from(map))
              );

              if (data.first.keys.contains("sharedBatchId")) {
                data.first.remove("sharedBatchId");
              }

              if (data.isNotEmpty) {
                await txn.update(table, data.first, where: 'id = ?', whereArgs: [id]);
              }
            } else if (type == 'delete') {
              await txn.delete(table, where: 'id = ?', whereArgs: [id]);
            }

            // await localDatabase.update('editLog', {'sharedBatchId': batchId}, where: 'id = ?', whereArgs: [change['id']]);
            Map<String, dynamic> mutableChange = Map<String, dynamic>.from(change);
            mutableChange['sharedBatchId'] = batchId;
            mutableChange['affectedId'] = id;
            mutableChange.remove('id');
            
            await txn.insert("editLog", mutableChange);
          } catch (e) {
          _logger.error("Error during push of change $change: $e", tag: "sharedDatabase");
        }

          // change local IDs from last (highest ID) to first to prevent ID conflicts
          if (changedIds.isNotEmpty) {
            for (Map<String, dynamic> change in changedIds.reversed) {
              try {
                await localDatabase.update(change['table'], {'id': change['newId']}, where: 'id = ?', whereArgs: [change['oldId']]);
                await localDatabase.update("editLog", {'affectedId': change['newId']}, where: 'affectedId = ? AND affectedTable = ?', whereArgs: [change['oldId'], change['table']]);
              } catch (e) {
                _logger.error("Error updating local IDs during push: $e", tag: "sharedDatabase");
              }
            }
          }
        }
      });
    } catch (e) {
      _logger.error("Error during push of changes: $e", tag: "sharedDatabase");
      rethrow;
    }
  }

  Future<bool> _pullChangesFromRemote(Database remoteDb) async {
    // Get the last processed batch ID
    Database localDatabase = await localDb.database;
    final settings = await localDatabase.query('settings',
      columns: ['lastProcessedBatchId'],
      limit: 1
    );
    final lastBatchId = settings.isNotEmpty ? settings.first['lastProcessedBatchId'] : -1;

    try {
      // Fetch changes from remote database
      final immutableChanges = await remoteDb.rawQuery(
        'SELECT * FROM editLog WHERE sharedBatchId > ?',
        [lastBatchId]
      );

      _logger.debug("Downstream pulling changes, total: ${immutableChanges.length}", tag: "sharedDatabase");
      

      if (immutableChanges.isNotEmpty) {
        List<Map<String, dynamic>> changes = _reduceImmutableChanges(immutableChanges);
        
        _logger.debug("Downstream pulling changes, cleaned: ${changes.length}", tag: "sharedDatabase");

        // Apply changes to local database
        await localDatabase.transaction((txn) async {
          for (final change in changes) {
            final table = change['affectedTable'] as String;
            if (["realizedBankaccounts", "realizedCategoryBudgets", "realizedAutoexpenses", "intervals"].contains(table)) {
              continue;
            }
            final type = change['type'];
            final id = change['affectedId'];

            if (type == 'insert') {
              final immutableData = await remoteDb.query(table, where: 'id = ?', whereArgs: [id]);
              List<Map<String, dynamic>> data = List.from(
                immutableData.map((map) => Map<String, dynamic>.from(map))
              );
              if (data.first.keys.contains("sharedBatchId")) {
                data.first.remove("sharedBatchId");
              }
              if (data.isNotEmpty) {
                await txn.insert(table, data.first, conflictAlgorithm: ConflictAlgorithm.replace);
              }
            } else if (type == 'update') {
              final immutableData = await remoteDb.query(table, where: 'id = ?', whereArgs: [id]);
              List<Map<String, dynamic>> data = List.from(
                  immutableData.map((map) => Map<String, dynamic>.from(map))
              );

              if (data.first.keys.contains("sharedBatchId")) {
                data.first.remove("sharedBatchId");
              }
              if (data.isNotEmpty) {
                await txn.update(table, data.first, where: 'id = ?', whereArgs: [id]);
              }
            } else if (type == 'delete') {
              await txn.delete(table, where: 'id = ?', whereArgs: [id]);
            }
          }
          
          int newBatchId;
          // Update lastProcessedBatchId
          if (changes.isEmpty) {
            newBatchId = DateTime.now().millisecondsSinceEpoch;
          } else if (changes.length == 1) {
            newBatchId = changes.first['sharedBatchId'] as int;
          } else {
            newBatchId = changes.map((e) => e['sharedBatchId'] as int).reduce((a, b) => a > b ? a : b);
          }

          _logger.info("New last changed batchId is $newBatchId", tag: "sharedDatabase");

          await txn.update(
            'settings',
            {'lastProcessedBatchId': newBatchId},
            where: 'id = 1',
          );
          // Cleanup editLog
          await txn.delete(
            "editLog",
            where: "sharedBatchId <= ?",
            whereArgs: [newBatchId]
          );
        });
      }

      List devices = await remoteDb.query("registeredDevices", where: "isPro = ? and blocked = ?", whereArgs: [1, 0]);
      bool hasPro = devices.isNotEmpty;
      return hasPro;
    } catch (e) {
      _logger.error("Could not pull changes: $e", tag: "sharedDatabase");
      return false;
    }
  }

  List<Map<String, dynamic>> _reduceImmutableChanges(
    List<Map<String, dynamic>> immutableChanges) {
    final Map<String, List<Map<String, dynamic>>> groupedChanges = {};

    for (var change in immutableChanges) {
      final key = '${change['affectedTable']}_${change['affectedId']}';
      groupedChanges.putIfAbsent(key, () => []).add(change);
    }

    final reducedChanges = <Map<String, dynamic>>[];
    for (var entry in groupedChanges.entries) {
      final changes = entry.value;
      final types = changes.map((change) => change['type']).toSet();

      if (types.containsAll(['insert', 'delete']) ||
          types.containsAll(['update', 'delete']) ||
          types.containsAll(['insert', 'update', 'delete'])) {
        continue;
      }

      if (types.containsAll(['insert', 'update'])) {
        reducedChanges.addAll(
            changes.where((change) => change['type'] != 'update'));
      } else {
        reducedChanges.addAll(changes);
      }
    }

    return reducedChanges;
  }
}
