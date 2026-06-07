import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:jne_household_app/models/category_budget_plain.dart';
import 'package:jne_household_app/models/category_plain.dart';
import 'package:jne_household_app/models/expense.dart';
import 'package:jne_household_app/models/interval.dart';
import 'package:jne_household_app/models/realized_autoexpenses.dart';
import 'package:jne_household_app/models/realized_bankaccounts.dart';
import 'package:jne_household_app/models/realized_category_budgets.dart';
import 'package:jne_household_app/models/reminder_settings.dart';
import 'package:jne_household_app/models/reset_principles.dart';
import 'package:jne_household_app/models/settings.dart';
import 'package:jne_household_app/services/format_date.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/autoexpenses.dart';
import 'package:jne_household_app/models/bankaccount.dart';
import 'package:flutter/material.dart';
import 'package:jne_household_app/services/remote/auth.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:jne_household_app/models/category.dart';
// ignore: unnecessary_import
import 'package:sqflite/sqflite.dart';  // mobile specific
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // desktop specific

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  final _logger = Logger();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Injects a pre-opened database. Only for use in tests.
  @visibleForTesting
  static void overrideDatabaseForTesting(Database db) => _database = db;

  /// Resets the database singleton. Call in tearDown to ensure test isolation.
  @visibleForTesting
  static void resetForTesting() => _database = null;

  Future<Database> _initDatabase() async {
    String dbPath;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      if (!Platform.isMacOS) {
        // IMPORTANT:
        // Do NOT call sqfliteFfiInit() on macOS.
        // It forces sqlite3 FFI which bundles sqlite3arm64macos.framework
        // -> rejected by Mac App Store.
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      final dir = await getApplicationSupportDirectory();
      dbPath = dir.path;
      _logger.debug("DB path: $dbPath", tag: "db");
    } else {
      dbPath = await getDatabasesPath();
    }
    
    return openDatabase(
      join(dbPath, (kDebugMode) ? 'debug_budget.db' : 'budget.db'),
      version: 43,
      onCreate: (db, version) {
        db.execute('CREATE TABLE expenses(id INTEGER PRIMARY KEY, date TEXT, amount REAL, accountId INTEGER DEFAULT -1, categoryId INTEGER, description TEXT, auto INTEGER DEFAULT 0, autoId INTEGER DEFAULT -1)');
        db.execute('CREATE TABLE categories(id INTEGER PRIMARY KEY, name TEXT, color TEXT, position INTEGER)');
        db.execute('CREATE TABLE settings (id INTEGER PRIMARY KEY, currency TEXT, language TEXT DEFAULT "auto", includePlanned INTEGER DEFAULT 0, lastAutoExpenseRun TEXT DEFAULT "none", showAvailableBudget INTEGER DEFAULT 0, isPro INTEGER DEFAULT 0, useBalance INTEGER DEFAULT 0, filterBudget TEXT DEFAULT "*", lastAdFail TEXT DEFAULT "none", lastAdSuccess TEXT DEFAULT "none", lastSavingRun TEXT DEFAULT "none", lastProcessedBatchId INTEGER DEFAULT -1, sharedDbUrl TEXT DEFAULT "none", syncMode TEXT DEFAULT "instant", syncFrequency INTEGER DEFAULT 1, lastSync TEXT DEFAULT "none", lockApp INTEGER DEFAULT 0, isDesktopPro INTEGER DEFAULT 0, selectedScanCategory INTEGER DEFAULT -1, reminder TEXT DEFAULT "{}", lastCreditCardRefillRun TEXT DEFAULT "none", tourCompleted INTEGER DEFAULT 0)');
        db.execute('CREATE TABLE autoexpenses (id INTEGER PRIMARY KEY, amount REAL, accountId INTEGER DEFAULT -1, categoryId INTEGER, description TEXT, bookingPrinciple TEXT, bookingDay INTEGER, principleMode TEXT DEFAULT "monthly", receiverAccountId DEFAULT -1, moneyFlow INTEGER DEFAULT 0, ratePayment INTEGER DEFAULT 0, rateCount INTEGER, firstRateAmount REAL, lastRateAmount REAL)');
        db.execute('CREATE TABLE bankaccounts (id INTEGER PRIMARY KEY, name TEXT, balance REAL, income REAL, description TEXT, budgetResetPrinciple TEXT, budgetResetDay INTEGER, lastSavingRun TEXT DEFAULT "none", isCreditCard INTEGER DEFAULT 0, refillsFrom INTEGER DEFAULT -1, refillPrincipleMode TEXT DEFAULT "monthly")');
        db.execute('CREATE TABLE categoryBudgets(id INTEGER PRIMARY KEY, categoryId INTEGER, accountId INTEGER, budget REAL, overrideBankAccount INTEGER DEFAULT null)');
        db.execute('CREATE TABLE editLog (id INTEGER PRIMARY KEY, affectedTable TEXT, affectedId INTEGER, type TEXT, sharedBatchId INTEGER DEFAULT -1)');
        db.execute('CREATE TABLE design (id INTEGER PRIMARY KEY, layoutMainVertical INTEGER DEFAULT 1, categoryMainStyle INTEGER DEFAULT 0, addExpenseStyle INTEGER DEFAULT 1, arcStyle INTEGER DEFAULT 0, arcPercent REAL DEFAULT 50.0, arcWidth REAL DEFAULT 0.8, arcSegmentsRounded INTEGER DEFAULT 1, dialogSolidBackground INTEGER DEFAULT 1, appBackgroundSolid INTEGER DEFAULT 1, appBackground INTEGER DEFAULT 0, customBackgroundBlur INTEGER DEFAULT 0, customBackgroundPath TEXT DEFAULT "none", mainMenuStyle INTEGER DEFAULT 0, blurIntensity REAL DEFAULT 0.1, customGradient TEXT DEFAULT "{}", intervalStyle INTEGER DEFAULT 0, goMobileBannerDismissed INTEGER DEFAULT 0, liquidGlassMode INTEGER DEFAULT 0, navBarStyle INTEGER DEFAULT 0)');
        db.execute('CREATE TABLE creditCardRefills (id INTEGER PRIMARY KEY, accountId INTEGER, creditAccountId INTEGER, amount REAL, date TEXT, categoryId INTEGER)');
        db.execute('CREATE TABLE intervals (id INTEGER PRIMARY KEY, start TEXT, end TEXT, accountId INTEGER)');
        db.execute('CREATE TABLE realizedCategoryBudgets (id INTEGER PRIMARY KEY, intervalId INTEGER, accountId INTEGER, categoryId INTEGER, budget REAL, overrideBankAccount INTEGER DEFAULT null)');
        db.execute('CREATE TABLE realizedBankaccounts (id INTEGER PRIMARY KEY, intervalId INTEGER, accountId INTEGER, balance REAL, income REAL)');
        db.execute('CREATE TABLE realizedAutoexpenses (id INTEGER PRIMARY KEY, intervalId INTEGER, autoexpenseId INTEGER, expenseId INTEGER)');

        int arcStyle = (Platform.isWindows || Platform.isMacOS || Platform.isLinux) ? 1 : 0;
        DateTime tdy = DateTime.now();
        String start = formatForSqlite(DateTime(tdy.year, tdy.month));
        String end = formatForSqlite(DateTime(tdy.year, tdy.month + 1));

        final defaultColor = colorToHex(Colors.grey[700]!);
        final unassignedName = I18n.translate("unassignedAccount");
        db.execute('INSERT INTO design (id, arcStyle) VALUES (1, $arcStyle)');
        db.execute("INSERT INTO settings (currency) VALUES ('€')");
        db.execute("INSERT INTO categories (id, name, color, position) VALUES (-1, '__undefined_category_name__', '$defaultColor', 0)");
        db.execute("INSERT INTO bankaccounts (id, name, balance, income, budgetResetPrinciple, budgetResetDay) VALUES (-1, '$unassignedName', 0, 0, 'monthStart', 1)");
        db.execute('INSERT INTO categoryBudgets (categoryId, accountId, budget) VALUES (-1, -1, 0)');
        db.execute("INSERT INTO intervals (start, end, accountId) VALUES ('$start', '$end', -1)");
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        _logger.debug("Upgrading database from version $oldVersion to $newVersion", tag: "database");
        if (oldVersion < 30) {
          await db.execute("ALTER TABLE design ADD COLUMN blurIntensity REAL DEFAULT 0.1");
        }

        if (oldVersion < 31) {
          await db.execute('ALTER TABLE design ADD COLUMN customGradient TEXT DEFAULT "{}"');
        }

        if (oldVersion < 32) {
          await db.execute('ALTER TABLE settings ADD COLUMN reminder TEXT DEFAULT "{}"');
        }

        if (oldVersion < 33) {
          await db.execute('ALTER TABLE bankaccounts ADD COLUMN isCreditCard INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE bankaccounts ADD COLUMN refillsFrom INTEGER DEFAULT -1');
          await db.execute('ALTER TABLE bankaccounts ADD COLUMN refillPrincipleMode TEXT DEFAULT "monthly"');
        }

        if (oldVersion < 34) {
          await db.execute('ALTER TABLE settings ADD COLUMN lastCreditCardRefillRun TEXT DEFAULT "none"');
          await db.execute('CREATE TABLE creditCardRefills (id INTEGER PRIMARY KEY, accountId INTEGER, creditAccountId INTEGER, amount REAL, date TEXT)');
        }

        if (oldVersion < 35) {
          await db.execute('ALTER TABLE creditCardRefills ADD COLUMN categoryId INTEGER');
        }

        if (oldVersion < 36) {
          await db.execute('ALTER TABLE categoryBudgets ADD COLUMN overrideBankAccount INTEGER DEFAULT null');
        }

        if (oldVersion < 37) {
          await db.execute('CREATE TABLE intervals (id INTEGER PRIMARY KEY, start TEXT, end TEXT, accountId INTEGER)');
          await db.execute('CREATE TABLE realizedCategoryBudgets (id INTEGER PRIMARY KEY, intervalId INTEGER, accountId INTEGER, categoryId INTEGER, budget REAL, overrideBankAccount INTEGER DEFAULT null)');
          await db.execute('CREATE TABLE realizedBankaccounts (id INTEGER PRIMARY KEY, intervalId INTEGER, accountId INTEGER, balance REAL, income REAL)');
          await db.execute('CREATE TABLE realizedAutoexpenses (id INTEGER PRIMARY KEY, intervalId INTEGER, autoexpenseId INTEGER, expenseId INTEGER)');
          await migrateTo37(db);
        }

        if (oldVersion < 38) {
          await db.execute('ALTER TABLE design ADD COLUMN intervalStyle INTEGER DEFAULT 0');
        }

        if (oldVersion < 39) {
          await cleanupData(db);
        }

        if (oldVersion < 40) {
          await db.execute('ALTER TABLE settings ADD COLUMN tourCompleted INTEGER DEFAULT 0');
        }

        if (oldVersion < 41) {
          await db.execute('ALTER TABLE design ADD COLUMN goMobileBannerDismissed INTEGER DEFAULT 0');
        }

        if (oldVersion < 42) {
          await db.execute('ALTER TABLE design ADD COLUMN liquidGlassMode INTEGER DEFAULT 0');
        }

        if (oldVersion < 43) {
          await db.execute('ALTER TABLE design ADD COLUMN navBarStyle INTEGER DEFAULT 0');
        }

        if (oldVersion < newVersion) {
          _logger.debug("Database upgraded to version $newVersion", tag: "database");
        }
      },
    );
  }

  Future<void> cleanupData(Database db) async {
    List<Expense> expenses = (await db.query("expenses")).map((e) => Expense(e)).toList();
    final Map<String, List<Expense>> groups = {};

    for (final exp in expenses) {
      final key = [
        exp.date,
        exp.amount,
        exp.accountId,
        exp.categoryId,
        exp.description,
        exp.auto,
        exp.autoId
      ].join("|");

      groups.putIfAbsent(key, () => []).add(exp);
    }

    for (final group in groups.values) {
      if (group.length <= 1) continue;
      group.sort((a, b) => a.id!.compareTo(b.id!));
      for (int i = 1; i < group.length; i++) {
        await group[i].delete(dbObj: db);
      }
    }
  }

  Future<void> migrateTo37(Database db) async {
    _logger.debug("Starting database migration", tag: "dbMigration");
    // read all necessary data
    final List<BankAccount> bankAccounts = await getBankAccounts(null, dbObj: db);
    final List<CategoryBudgetPlain> catgoryBudgets = await getCategoryBudgets(dbObj: db);
    final List<dynamic> allBookedAutoExepenses = (await genericSelect("expenses", filter: "autoId != ?", filterArgs: [-1], dbObj: db)).map((exp) => Expense(exp)).toList();
    final List<AutoExpense> autoExpenses = await getAutoExpenses(dbObj: db);
    _logger.debug("Fetched data ${bankAccounts.length} bankAccounts, ${catgoryBudgets.length} catgoryBudgets, ${autoExpenses.length} autoExpenses, ${allBookedAutoExepenses.length} boooked autoExpenses", tag: "dbMigration");

    List<PBInterval> intervals = [];
    // create all intervals
    _logger.debug("Starting interval migration", tag: "dbMigration");
    for (BankAccount ba in bankAccounts) {
      // read first expense
      final firstExpense = await genericSelect("expenses", onlyFirst: true, dbObj: db);
      DateTime firstDate;
      if (firstExpense != null) {
        firstDate = DateTime.parse(firstExpense['date']);
      } else {
        firstDate = DateTime.now();
      }
      
      final resetInfo = {
        "principle": ba.budgetResetPrinciple,
        "day": ba.budgetResetDay
      };
      List<PBInterval> rawIntervals = getMultipleRanges(resetInfo, 1000, firstDate, ba.id!).reversed.map((i) => PBInterval({'accountId': ba.id, 'start': i.start, 'end': i.end})).toList();
      for (PBInterval r in rawIntervals) {
        await r.save(dbObj: db);
      }
      intervals.addAll(rawIntervals);
    }
    _logger.debug("Finished interval migration", tag: "dbMigration");

    _logger.debug("Starting bankaccount migration", tag: "dbMigration");
    // create all realizedBankaccounts
    for (PBInterval i in intervals) {
      for (BankAccount ba in bankAccounts) {
        if (i.accountId != ba.id) {
          continue;
        }
        final n = RealizedBankaccounts({
          "intervalId": i.id,
          "accountId": ba.id,
          "balance": ba.balance,
          "income": ba.income
        });
        await n.save(dbObj: db);
      }
    }
    _logger.debug("Finished bankaccount migration", tag: "dbMigration");

    _logger.debug("Starting categoryBudget migration", tag: "dbMigration");
    // create all realizedCategoryBudgets
    for (PBInterval i in intervals) {
      for (CategoryBudgetPlain cb in catgoryBudgets) {
        if (i.accountId != cb.accountId) {
          continue;
        }
        final n = RealizedCategoryBudgets({
          "intervalId": i.id,
          "accountId": cb.accountId,
          "categoryId": cb.categoryId,
          "budget": cb.budget,
          "overrideBankAccount": cb.overrideBankAccount
        });
        await n.save(dbObj: db);
      }
    }
    _logger.debug("Finished categoryBudget migration", tag: "dbMigration");
    _logger.debug("Starting autoexpense migration", tag: "dbMigration");
    // create all realizedAutoexpenses
    for (Expense exp in allBookedAutoExepenses) {
      final intervalID = intervals.firstWhere((i) => (i.accountId == exp.accountId && exp.date.isAfter(i.start) && exp.date.isBefore(i.end)), orElse: () => PBInterval({"id": -1, "start": DateTime.now(), "end": DateTime.now(), "accountId": -1}),).id;
      if (intervalID == -1) {
        logger.debug("Deleting expense with id ${exp.id}");
        await exp.delete(dbObj: db);
      } else {
        final ae = autoExpenses.where((ae) => ae.id == exp.autoId).toList();
        final RealizedAutoexpenses e = RealizedAutoexpenses({
          'intervalId': intervalID,
          'autoexpenseId': ae.isEmpty ? -1 : ae.first.id,
          'expenseId': exp.id
        });
        await e.save(dbObj: db);
      }
    }

    _logger.debug("Finished autoexpense migration", tag: "dbMigration");
  }

  Map<String, dynamic> cleanupMap(Map<String, dynamic> values) {
    for (final key in values.keys) {
      if (values[key] == true) {
        values[key] = 1;
      } else if (values[key] == false) {
        values[key] = 0;
      }
    }
    return values;
  }

  Future<int> genericInsert(String table, Map<String, dynamic> values, {Database? dbObj}) async {
    final db = dbObj ?? await database;
    values = cleanupMap(values);
    int id = (await db.insert(table, values));
    await genericInsertLog(table, id, "insert", dbObj: db);
    return id;
  }

  Future<void> genericUpdate(String table, Map<String, dynamic> values, {Database? dbObj}) async {
    final db = dbObj ?? await database;
    values = cleanupMap(values);
    await db.update(table, values, where: "id = ?", whereArgs: [values['id']]);
    await genericInsertLog(table, values['id'],"update", dbObj: db);
  }

  Future<void> genericDelete(String table, int id, {Database? dbObj}) async {
    final db = dbObj ?? await database;
    await db.delete(table, where: "id = ?", whereArgs: [id]);
    await genericInsertLog(table, id, "delete", dbObj: db);
  }

  Future<dynamic> genericSelect(String table, {bool onlyFirst = false, String? filter, List? filterArgs, String? order, Database? dbObj, int? limit}) async {
    final db = dbObj ?? await database;
    List res = await db.query(table, where: filter, whereArgs: filterArgs, orderBy: order, limit: limit);
    if (onlyFirst) {
      try {
        return res.first;
      } catch (e) {
        return null;
      }
    } else {
      return res;
    }
  }

  Future<void> genericInsertLog(table, id, method, {Database? dbObj}) async {
    final db = dbObj ?? await database;
    if (["settings", "design", "editLog"].contains(table)) {
      return;
    }
    await insertEditLog(table, id, method, dbObj: db);
  }

  Future<void> insertEditLog(String table, int affectedId, String type, {Database? dbObj}) async {
    final db = dbObj ?? await database;
    Map<String, dynamic> change = {
      "affectedTable": table,
      "affectedId": affectedId,
      "type": type
    };

    if (type == "insert") {
      await db.insert("editLog", change);
    } else if (type == "update") {
      if ((await db.query("editLog", where: "affectedId = ? and affectedTable = ?", whereArgs: [affectedId, table])).isEmpty) {
        await db.insert("editLog", change);
        _logger.debug("Inserted update into editLog", tag: "database");
      } else {
        _logger.debug("Already have entry for this change", tag: "database");
      }
    } else if (type == "delete") {
      List<Map<String, dynamic>> entries = (await db.query("editLog", where: "affectedId = ? and affectedTable = ?", whereArgs: [affectedId, table]));
      if (entries.isEmpty) {
        await db.insert("editLog", change);
        _logger.debug("Inserted deletion into editLog", tag: "database");
      } else {
        await db.delete("editLog", where: "id = ?", whereArgs: [entries.first['id']]);
        _logger.debug("Removed insert from editLog", tag: "database");
      }
    }
  }

  void createDefaultData() async {
    final db = await database;
    final defaultColor = colorToHex(Colors.grey[700]!);
    final unassignedName = I18n.translate("unassignedAccount");
    await db.execute("INSERT INTO settings (currency) VALUES ('€')");
    await db.execute("INSERT INTO categories (id, name, color, position) VALUES (-1, '__undefined_category_name__', '$defaultColor', 0)");
    await db.execute("INSERT INTO bankaccounts (id, name, balance, income, budgetResetPrinciple, budgetResetDay) VALUES (-1, '$unassignedName', 0, 0, 'monthStart', 1)");
    await db.execute('INSERT INTO categoryBudgets (categoryId, accountId, budget) VALUES (-1, -1, 0)');

    await insertEditLog("categories", -1, "insert", dbObj: db);
    await insertEditLog("bankaccounts", -1, "insert", dbObj: db);
    await insertEditLog("categoryBudgets", -1, "insert", dbObj: db);
  }

  Future<void> updateDesign(String key, dynamic value) async {
    final db = await database;
    Map<String, dynamic> values = {
      "id": 1,
      key: value
    };
    await genericUpdate("design", values, dbObj: db);
  }

  Future<void> processSavings(int accountId, Map<String, DateTime> range, logger) async {
    final db = await database;
    double income = (await getTotalBudget(accountId.toString()))['totalIncome'];
    String query  = '''SELECT SUM(amount) as totalSpent
      FROM expenses
      WHERE accountID = ?
        AND date >= ?
        AND date < ?''';
    List params = [accountId, formatForSqlite(range['start']!), formatForSqlite(range['end']!)];

    dynamic spent = (await db.rawQuery(query, params))[0]['totalSpent'];
    spent ??= 0.0;

    logger.debug("Spent $spent", tag: "balance clac");

    dynamic balance = (await db.query("bankaccounts", columns: ['balance'], where: 'id = ?', whereArgs: [accountId]))[0]['balance'] as double;
    balance ??= 0.0;

    double newBalance = double.parse((balance + (income - spent)).toStringAsFixed(2));

    await db.update("bankaccounts", {"balance": newBalance}, where: 'id = ?', whereArgs: [accountId]);
    await insertEditLog("bankaccounts", accountId, "update", dbObj: db);
  }

  Future<Settings> getSettings() async {
    final db = await database;
    return Settings((await db.query('settings'))[0]);
  }

  Future<Map<String, dynamic>> getTotalBudget(dynamic filterBudget) async {
    final db = await database;
    String query;
    List<dynamic> params = [];

    if (filterBudget == "*") {
      query = "SELECT SUM(income) AS totalIncome, SUM(balance) AS totalBalance FROM bankaccounts";
      return (await db.rawQuery(query, params))[0];
    } else {
      query = "SELECT SUM(income) AS totalIncome, SUM(balance) AS totalBalance FROM bankaccounts WHERE id = ?";
      filterBudget = int.parse(filterBudget);
      params = [filterBudget];
      Map<String, dynamic> result = (await db.rawQuery(query, params))[0];

      dynamic extra = (await db.rawQuery("SELECT SUM(amount) AS addition FROM autoexpenses WHERE moneyFlow = ? AND receiverAccountId = ?", [1, filterBudget]))[0]["addition"];
      extra ??= 0.0;
      return {"totalIncome": result['totalIncome'] + extra, "totalBalance": result['totalBalance']};
    }
  }

  Future<ReminderSettings> loadReminder() async {
    Map<String, dynamic> res = json.decode((await getSettings()).reminder);
    return ReminderSettings.fromJson(res);
  }

  Future<void> updatePositions(List<Map<String, int>> positions) async {
    final db = await database;
    for (Map<String, int> pos in positions) {
      await db.update('categories', {"position": pos['pos']}, where: 'id = ?', whereArgs: [pos['id']]);
      await insertEditLog("categories", pos['id']!, "update", dbObj: db);
    }
  }

  Future<double> getSpentForCurrentMonth(int categoryId, String accountId, PBInterval range, bool includePlanned, List<BankAccount> bankAccounts)async {
    final db = await database;
    final now = DateTime.now();
    final nowAfterEnd = range.end.isBefore(now);
    String query;
    List params = [];
    double result = 0.0;
    query  = '''SELECT SUM(amount) as totalSpent
      FROM expenses
      WHERE categoryId = ?
        AND accountID = ?
        AND date >= ?
        AND date < ?''';

    for (final account in bankAccounts.where((acc) => (accountId == "*") ? true : (acc.isCreditCard) ? (acc.refillsFrom.toString() == accountId) : (acc.id.toString() == accountId))) {
      if (!account.isCreditCard) {
        params = [categoryId, account.id.toString(), formatForSqlite(range.start), (includePlanned || nowAfterEnd) ? formatForSqlite(range.end) : formatForSqlite(now)];
      } else {
        PBInterval adaptRange = await getIntervals(dbObj: db, onlyFirst: true, filter: "accountId = ?", filterArgs: [account.id], order: "id DESC");
        if (dateAfterRange(range, adaptRange.end)) {
          _logger.debug("Skipping this account as the range is in the future", tag: "database");
          continue;
        }
        params = [categoryId, account.id.toString(), formatForSqlite(adaptRange.start), (includePlanned || nowAfterEnd) ? formatForSqlite(adaptRange.end) : formatForSqlite(now)];
      }
      result += (await db.rawQuery(query, params)).first['totalSpent'] as double? ?? 0.0;
    }

    return result;
  }

  Future<double> getBudgetForCurrentInterval(int intervalId, int categoryId, String accountId) async {
    if (accountId == "*") {
      accountId = "-1";
    }

    _logger.debug("Getting budget for interval $intervalId, category $categoryId, account $accountId", tag: "database");

    final db = await database;
    final data = await genericSelect(
      "realizedCategoryBudgets",
      filter: "intervalId = ? AND categoryId = ? AND accountId = ?",
      filterArgs: [intervalId, categoryId, accountId],
      dbObj: db
    );
    if (data.isEmpty) {
      return 0.0;
    }
    return data.first['budget'] as double? ?? 0.0;
  }

  Future<void> insertCategoryBudget(Map<String, dynamic> catBudget, {Database? dbObj}) async {
    final db = dbObj ?? await database;
    int id = await db.insert('categoryBudgets', catBudget);
    await insertEditLog("categoryBudgets", id, "insert", dbObj: db);
  }

  Future<int> insertCategory(Map<String, dynamic> category, String filter, int newPos) async {
    final db = await database;

    final cat = {
      "name": category['name'],
      "color": category['color'],
      "position": newPos
    };

    int id = await db.insert('categories', cat);
    await insertEditLog("categories", id, "insert", dbObj: db);
    List<BankAccount> bankAccounts = await getBankAccounts(await getMoneyFlows());
    if (filter == "*") {
      filter = "-1";
    }

    for (BankAccount acc in bankAccounts) {
      int budId = await db.insert("categoryBudgets", {"categoryId": id, "accountId": acc.id, "budget": (filter == acc.id.toString()) ? category['budget'] : 0, "overrideBankAccount": category["overrideBankAccount"]});
      await insertEditLog("categoryBudgets", budId, "insert", dbObj: db);
    }

    return id;
  }

  Future<void> insertSettings(Map<String, dynamic> settings, {Database? dbObj}) async {
    final db = dbObj ?? await database;
    await db.insert('settings', settings);
  }

  Future<void> insertCategoryFlat(Map<String, dynamic> category, {Database? dbObj}) async {
    final db = dbObj ?? await database;
    int id = await db.insert('categories', category);
    await insertEditLog("categories", id, "insert", dbObj: db);
  }

  Future<void> insertEditLogFlat(Map<String, dynamic> category, {Database? dbObj}) async {
    final db = dbObj ?? await database;
    await db.insert('editLog', category);
  }

  Future<int> insertAutoExpense(Map<String, dynamic> autoExpense, {Database? dbObj}) async {
    final db = dbObj ?? await database;
    int id = await db.insert('autoexpenses', autoExpense);
    await insertEditLog("autoexpenses", id, "insert", dbObj: db);
    return id;
  }

  Future<void> deleteAutoExpense(int id) async {
    final db = await database;

    await db.delete('autoexpenses', where: "id = ?", whereArgs: [id]);
    await insertEditLog("autoexpenses", id, "delete", dbObj: db);
  }

  Future<int> insertBankAccount(Map<String, dynamic> bankAccount, {Database? dbObj}) async {
    final db = dbObj ?? await database;
    // isCreditCard may arrive as int (0/1) from a backup file — convert safely
    bankAccount['isCreditCard'] =
        (bankAccount['isCreditCard'] == true || bankAccount['isCreditCard'] == 1) ? 1 : 0;
    int id = await db.insert('bankaccounts', bankAccount);
    await insertEditLog("bankaccounts", id, "insert", dbObj: db);
    List<Category> cats = await getCategories("*");
    for (Category cat in cats) {
      int cbId = await db.insert("categoryBudgets", {"accountId": id, "categoryId": cat.category.id, "budget": 0});
      await insertEditLog("categoryBudgets", cbId, "insert", dbObj: db);
    }

    return id;
  }

  Future<void> deleteBankAccount(int id) async {
    final db = await database;
    await db.delete('bankaccounts', where: "id = ?", whereArgs: [id]);
    await insertEditLog("bankaccounts", id, "delete", dbObj: db);

    List<Map<String, dynamic>> affectedBankAccounts = await db.query('bankaccounts', where: "refillsFrom = ?", whereArgs: [id]);
    for (Map<String, dynamic> acc in affectedBankAccounts) {
      await db.update('bankaccounts', {"refillsFrom": -1}, where: "id = ?", whereArgs: [acc['id']]);
      await insertEditLog("bankaccounts", acc['id'], "update", dbObj: db);
    }

    List<Map<String, dynamic>> affectedRefills = await db.query('creditCardRefills', where: "accountId = ?", whereArgs: [id]);
    for (Map<String, dynamic> entry in affectedRefills) { 
      await db.update('creditCardRefills', {"accountId": -1}, where: "accountId = ?", whereArgs: [id]);
      await insertEditLog("creditCardRefills", entry['id'], "delete", dbObj: db);
    }

    List<Map<String, dynamic>> affected = await db.query('categoryBudgets', where: "accountId = ?", whereArgs: [id]);
    await db.delete('categoryBudgets', where: "accountId = ?", whereArgs: [id]);
    for (Map<String, dynamic> entry in affected) {
      await insertEditLog("categoryBudgets", entry['id'], "delete", dbObj: db);
    }

    affected = await db.query('expenses', where: "accountId = ?", whereArgs: [id]);
    await db.update('expenses', {"accountId": -1}, where: "accountId = ?", whereArgs: [id]);
    for (Map<String, dynamic> entry in affected) {
      await insertEditLog("expenses", entry['id'], "update", dbObj: db);
    }

    affected = await db.query('autoexpenses', where: "accountId = ? AND moneyFlow = ?", whereArgs: [id, 0]);
    await db.update('autoexpenses', {"accountId": -1}, where: "accountId = ? AND moneyFlow = ?", whereArgs: [id, 0]);
    for (Map<String, dynamic> entry in affected) {
      await insertEditLog("autoexpenses", entry['id'], "update", dbObj: db);
    }

    affected = await db.query('autoexpenses', where: "receiverAccountId = ? AND moneyFlow = ?", whereArgs: [id, 1]);
    await db.delete('autoexpenses', where: "receiverAccountId = ? AND moneyFlow = ?", whereArgs: [id, 1]);
    for (Map<String, dynamic> entry in affected) {
      await insertEditLog("autoexpenses", entry['id'], "delete", dbObj: db);
    }
  }

  Future<List<CategoryPlain>> getCategoriesPlain() async {
    final List<Map<String, dynamic>> result = await genericSelect("categories", order: 'position DESC');
    return result.map((exp) => CategoryPlain(exp)).toList();
  }

  Future<List<CategoryBudgetPlain>> getCategoryBudgets({Database? dbObj}) async {
    final List<Map<String, dynamic>> result = await genericSelect("categoryBudgets", dbObj: dbObj);
    return result.map((exp) => CategoryBudgetPlain(exp)).toList();
  }

  Future<List<Category>> getCategories(String filter) async {
    final categoriesPlain = await getCategoriesPlain();
    final categoryBudgets = await getCategoryBudgets();

    return categoriesPlain.map((data) {
      double budget;
      List<CategoryBudgetPlain> selectedCategoryBudgets;
      if (filter == "*") {
        budget = categoryBudgets
          .where((cb) => cb.categoryId == data.id)
          .fold(0.0, (sum, cb) => sum + (cb.budget));
        selectedCategoryBudgets = categoryBudgets.where((cb) => cb.categoryId == data.id).toList();
      } else {
        selectedCategoryBudgets = [categoryBudgets.firstWhere((cb) => cb.categoryId == data.id && cb.accountId.toString() == filter)];
        budget = selectedCategoryBudgets.first.budget;
      }
      return Category(
        budget: budget,
        categoryBudgetsPlain: selectedCategoryBudgets,
        category: data
      );
    }).where((c) => (c.budget != 0.0 || c.category.id == -1)).toList();
  }

  Future<List<BankAccount>> getBankAccounts(List<AutoExpense>? moneyFlows, {Database? dbObj, int? intervalId}) async {
    final db = dbObj ?? await database;
    final List<Map<String, dynamic>> bankaccountdata = List.from(await db.query('bankaccounts'));
    List<BankAccount> result = [];

    for (Map<String, dynamic> data in bankaccountdata) {
      double income = data['income'] as double;
      double balance = data['balance'] as double;
      if (intervalId != null) {
        final result = (await genericSelect(
          "realizedBankaccounts",
          filter: "intervalId = ? AND accountId = ?",
          filterArgs: [intervalId, data['id']],
          dbObj: db
        ));
        if (result.isNotEmpty) {
          income = result.first['income'] as double;
          balance = result.first['balance'] as double;
        }
      }
      result.add(BankAccount(
        id: data['id'] as int,
        name: data['name'] as String,
        income: income,
        balance: balance,
        description: data['description'] != null ? data['description'] as String : "",
        budgetResetPrinciple: data['budgetResetPrinciple'] as String,
        budgetResetDay: data['budgetResetDay'] as int,
        lastSavingRun: data['lastSavingRun'] as String,
        transfers: moneyFlows != null ? moneyFlows.where((mf) => mf.receiverAccountId == data['id']).fold(0, (sum, mf) => sum + mf.amount) : 0.0,
        isCreditCard: data['isCreditCard'] == 1,
        refillsFrom: data['refillsFrom'] as int,
        refillPrincipleMode: data['refillPrincipleMode'] as String
      ));
    }
    return result;
  }

  Future<List<AutoExpense>> getAutoExpenses({bool noMoneyFlow = true, Database? dbObj}) async {
    final db = dbObj ?? await database;
    final List<Map<String, dynamic>> autoExpenseList = (noMoneyFlow) ?
      List.from(await db.query('autoexpenses', where: 'moneyFlow = ?', whereArgs: [0]))
      :
      List.from(await db.query('autoexpenses'));
    return autoExpenseList.map((data) {
      return AutoExpense(
        id: data['id'] as int,
        amount: data['amount'] as double,
        categoryId: data['categoryId'] as int,
        description:  data['description'] as String,
        bookingPrinciple: data['bookingPrinciple'] as String,
        bookingDay: data['bookingDay'] as int,
        principleMode: data['principleMode'] as String,
        accountId: data['accountId'] as int,
        receiverAccountId: data['receiverAccountId'] as int,
        moneyFlow: data['moneyFlow'] == 1,
        ratePayment: data['ratePayment'] == 1,
        rateCount: data['rateCount'] is num ? (data['rateCount'] as num).toInt() : null,
        firstRateAmount: data['firstRateAmount'] is num ? (data['firstRateAmount'] as num).toDouble() : null,
        lastRateAmount: data['lastRateAmount'] is num ? (data['lastRateAmount'] as num).toDouble() : null,
      );
    }).toList();
  }

  Future<List<AutoExpense>> getMoneyFlows() async {
    final db = await database;
    final List<Map<String, dynamic>> autoExpenseList = List.from(await db.query('autoexpenses', where: 'moneyFlow = ?', whereArgs: [1]));

    return autoExpenseList.map((data) {
      return AutoExpense(
        id: data['id'] as int,
        amount: data['amount'] as double,
        categoryId: data['categoryId'] as int,
        description:  data['description'] as String,
        bookingPrinciple: data['bookingPrinciple'] as String,
        bookingDay: data['bookingDay'] as int,
        principleMode: data['principleMode'] as String,
        accountId: data['accountId'] as int,
        receiverAccountId: data['receiverAccountId'] as int,
        moneyFlow: data['moneyFlow'] == 1,
        ratePayment: data['ratePayment'] == 1
      );
    }).toList();
  }

  Future<Map<String, dynamic>> getFirstExpense() async {
    final db = await database;
    return (await db.query('expenses', limit: 1, orderBy: "date ASC"))[0];
  }

  Future<dynamic> getIntervals({Database? dbObj, int? limit, String? filter, List<dynamic>? filterArgs, String? order, bool onlyFirst = false}) async {
    final db = dbObj ?? await database;
    final List<Map<String, dynamic>> result = await genericSelect("intervals", limit: limit, filter: filter, filterArgs: filterArgs, order: order, dbObj: db);
    if (onlyFirst){
      return PBInterval(result.first);
    } else {
      return result.map((res) => PBInterval(res)).toList();
    }
  }

  Future<dynamic> getRealizedBankAccounts({Database? dbObj, int? limit, String? filter, List<dynamic>? filterArgs, String? order, bool onlyFirst = false}) async {
    final db = dbObj ?? await database;
    final dynamic result = await genericSelect("realizedBankaccounts", limit: limit, filter: filter, filterArgs: filterArgs, order: order, onlyFirst: onlyFirst, dbObj: db);
    if (onlyFirst){
      return RealizedBankaccounts(result);
    } else {
      return result.map((res) => RealizedBankaccounts(res)).toList();
    }
  }

  Future<List<Expense>> getExpenses(int categoryId, String accountId, PBInterval range, List<BankAccount> bankAccounts) async {
    String where;
    List whereParams = [];

    if (accountId == "*") {
      where = "categoryId = ? AND date >= ? AND date <= ?";
      whereParams = [categoryId, formatForSqlite(range.start), formatForSqlite(range.end)];
    } else {
      whereParams = [categoryId];
      String inlay = "";
      for (BankAccount acc in bankAccounts.where((acc) => (acc.isCreditCard) ? (acc.refillsFrom.toString() == accountId) : (acc.id.toString() == accountId))) {
        inlay += "(date >= ? AND date <= ? AND accountId = ?) OR ";
        if (acc.isCreditCard) {
          whereParams.addAll([formatForSqlite(getCreditCardStartDayLastMonth({"principle": acc.budgetResetPrinciple, "day": acc.budgetResetDay}, acc.id!)), formatForSqlite(range.end), acc.id]);
        } else {
          whereParams.addAll([formatForSqlite(range.start), formatForSqlite(range.end), acc.id]);
        }
      }
      where = "categoryId = ? AND (${inlay.substring(0, inlay.length - 3)})";
    }

    final List<Map<String, dynamic>> result = await genericSelect("expenses", filter: where, filterArgs: whereParams, order: "date ASC");
    return result.map((exp) => Expense(exp)).toList();
  }

  Future<List<Map<String, dynamic>>> exportTable(String table) async {
    final db = await database;
    return await db.query(table);
  }

  Future<void> resetDatabase([bool keepSettings = false]) async {
    final db = await database;
    List<String> tables;

    if (keepSettings) {
      tables = ['expenses', 'categories', 'autoexpenses', 'bankaccounts', 'categoryBudgets', 'editLog', 'intervals', 'realizedCategoryBudgets', 'realizedBankaccounts', 'realizedAutoexpenses'];
    } else {
      tables = ['expenses', 'categories', 'settings', 'autoexpenses', 'bankaccounts', 'categoryBudgets', 'editLog', 'intervals', 'realizedCategoryBudgets', 'realizedBankaccounts', 'realizedAutoexpenses'];
    }

    for (final table in tables) {
      await db.delete(table);
    }
  }

  Future<void> importData(Map<String, dynamic> data) async {
    final db = await database;

    // Wrap everything in a transaction so the DB is never left in a partial state.
    // If any insert fails, SQLite rolls back to the state before the import started.
    await db.transaction((txn) async {
      // Clear existing data inside the transaction
      const tables = [
        'expenses', 'categories', 'settings', 'autoexpenses', 'bankaccounts',
        'categoryBudgets', 'editLog', 'intervals', 'realizedCategoryBudgets',
        'realizedBankaccounts', 'realizedAutoexpenses',
      ];

      _logger.debug("Loading data from keys: ${data.keys}r" ,tag: "import");

      _logger.debug("Deleting old data", tag: "import");
      for (final t in tables) {
        await txn.delete(t);
      }

      _logger.debug("Inserting expenses", tag: "import");
      for (final row in (data['expenses'] as List)) {
        await txn.insert('expenses', row as Map<String, dynamic>);
      }

      _logger.debug("Inserting autoexpenses", tag: "import");
      for (final row in (data['autoexpenses'] as List)) {
        await txn.insert('autoexpenses', row as Map<String, dynamic>);
      }

      _logger.debug("Inserting settings", tag: "import");
      for (final row in (data['settings'] as List)) {
        final s = Map<String, dynamic>.from(row as Map)..remove('isPro');
        await txn.insert('settings', s);
      }

      _logger.debug("Inserting bankaccounts", tag: "import");
      for (final row in (data['bankaccounts'] as List)) {
        final acc = Map<String, dynamic>.from(row as Map);
        acc['isCreditCard'] =
            (acc['isCreditCard'] == true || acc['isCreditCard'] == 1) ? 1 : 0;
        await txn.insert('bankaccounts', acc);
      }

      _logger.debug("Inserting categoryBudgets", tag: "import");
      for (final row in (data['categoryBudgets'] as List)) {
        await txn.insert('categoryBudgets', row as Map<String, dynamic>);
      }

      _logger.debug("Inserting categories", tag: "import");
      for (final row in (data['categories'] as List)) {
        await txn.insert('categories', row as Map<String, dynamic>);
      }

      _logger.debug("Inserting creditCardRefills", tag: "import");
      for (final row in (data['creditCardRefills'] as List)) {
        await txn.insert('creditCardRefills', row as Map<String, dynamic>);
      }

      _logger.debug("Inserting intervals", tag: "import");
      for (final row in (data['intervals'] as List)) {
        await txn.insert('intervals', row as Map<String, dynamic>);
      }

      _logger.debug("Inserting realized_bankaccounts", tag: "import");
      for (final row in (data['realized_bankaccounts'] as List)) {
        await txn.insert('realizedBankaccounts', row as Map<String, dynamic>);
      }

      _logger.debug("Inserting realized_categorybudgets", tag: "import");
      for (final row in (data['realized_categorybudgets'] as List)) {
        await txn.insert('realizedCategoryBudgets', row as Map<String, dynamic>);
      }

      _logger.debug("Inserting realized_autoexpenses", tag: "import");
      for (final row in (data['realized_autoexpenses'] as List)) {
        await txn.insert('realizedAutoexpenses', row as Map<String, dynamic>);
      }

      _logger.debug("Inserting editLog", tag: "import");
      for (final row in (data['editLog'] as List)) {
        await txn.insert('editLog', row as Map<String, dynamic>);
      }

      _logger.debug("Finished inserting", tag: "import");
    });
    _logger.debug("Finished import", tag: "import");
  }

  Future<void> insertRefill(Map<String, dynamic> refill, {Database? dbObj}) async {
    final db = dbObj ?? await database;
    int id = await db.insert('creditCardRefills', refill);
    await insertEditLog("creditCardRefills", id, "insert", dbObj: db);
  }

  // statisticMonthTotal … lastMonthsCatBudget → StatisticsRepository

  Future<void> moveExpense(int id, int newCatid, int newAccountId) async {
    final db = await database;
    await db.update("expenses", {"categoryId": newCatid, "accountId": newAccountId}, where: "id = ?", whereArgs: [id]);
    await insertEditLog("expenses", id, "update", dbObj: db);
  }

  Future<void> moveAutoExpense(int id, int newCatid, int newAccountId) async {
    final db = await database;
    final now = DateTime.now();

    await db.update("autoexpenses", {"categoryId": newCatid, "accountId": newAccountId}, where: "id = ?", whereArgs: [id]);
    await insertEditLog("autoexpenses", id, "update", dbObj: db);

    List<Map<String, dynamic>> exp = await db.query("expenses", columns: ["id", "date"], where: "autoId = ? AND DATE(date) >= DATE(?)", whereArgs: [id, formatForSqlite(now)]);
    for (Map<String, dynamic> entry in exp) {
      await db.update("expenses", {"categoryId": newCatid, "accountId": newAccountId}, where: "id = ?", whereArgs: [entry['id']]);
      await insertEditLog("expenses", entry['id'], "update", dbObj: db);
    }
  }

  Future<DateTime> getLastSync({Database? dbObj}) async {
    final db = dbObj ?? await database;
    String result = (await db.query("settings"))[0]['lastSync'].toString();
    if (result == "none") {
      return DateTime.fromMicrosecondsSinceEpoch(0);
    }
    return DateTime.parse(result);
  }
}

String createLabel(PBInterval range) {
  if (range.start.day == 1 && range.end.day == 1) {
    return shortMonthYr(range.start);
  } else {
    return "${shortMonthYr(range.start)} / ${shortMonthYr(range.end)}";
  }
}

String colorToHex(Color color) {
  return color.toARGB32().toRadixString(16).padLeft(8, '0');
}

Color hexToColor(String hex) {
  return Color(int.parse(hex, radix: 16));
}

String formatForSqlite(DateTime dt) {
  return dt.toIso8601String().replaceFirst("T", " ").split(".").first;
}
