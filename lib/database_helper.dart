import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:jne_household_app/helper/format_date.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/autoexpenses.dart';
import 'package:jne_household_app/models/bankaccount.dart';
import 'package:flutter/material.dart';
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

  Future<Database> _initDatabase() async {
    String dbPath;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final dir = await getApplicationSupportDirectory();
      dbPath = dir.path;
    } else {
      dbPath = await getDatabasesPath();
    }
    
    return openDatabase(
      join(dbPath, (kDebugMode) ? 'debug_budget.db' : 'budget.db'),
      version: 26,
      onCreate: (db, version) {
        db.execute('CREATE TABLE expenses(id INTEGER PRIMARY KEY, date TEXT, amount REAL, accountId INTEGER DEFAULT -1, categoryId INTEGER, description TEXT, auto INTEGER DEFAULT 0, autoId INTEGER DEFAULT -1)');
        db.execute('CREATE TABLE categories(id INTEGER PRIMARY KEY, name TEXT, color TEXT, position INTEGER)');
        db.execute('CREATE TABLE settings (id INTEGER PRIMARY KEY, currency TEXT, language TEXT DEFAULT "auto", includePlanned INTEGER DEFAULT 0, lastAutoExpenseRun TEXT DEFAULT "none", showAvailableBudget INTEGER DEFAULT 0, isPro INTEGER DEFAULT 0, useBalance INTEGER DEFAULT 0, filterBudget TEXT DEFAULT "*", lastAdFail TEXT DEFAULT "none", lastAdSuccess TEXT DEFAULT "none", lastSavingRun TEXT DEFAULT "none", lastProcessedBatchId INTEGER DEFAULT -1, sharedDbUrl TEXT DEFAULT "none", syncMode TEXT DEFAULT "instant", syncFrequency INTEGER DEFAULT 1, lastSync TEXT DEFAULT "none", lockApp INTEGER DEFAULT 0)');
        db.execute('CREATE TABLE autoexpenses (id INTEGER PRIMARY KEY, amount REAL, accountId INTEGER DEFAULT -1, categoryId INTEGER, description TEXT, bookingPrinciple TEXT, bookingDay INTEGER, principleMode TEXT DEFAULT "monthly", receiverAccountId DEFAULT -1, moneyFlow INTEGER DEFAULT 0, ratePayment INTEGER DEFAULT 0, rateCount INTEGER, firstRateAmount REAL, lastRateAmount REAL)');
        db.execute('CREATE TABLE bankaccounts (id INTEGER PRIMARY KEY, name TEXT, balance REAL, income REAL, description TEXT, budgetResetPrinciple TEXT, budgetResetDay INTEGER, lastSavingRun TEXT DEFAULT "none")');
        db.execute('CREATE TABLE categoryBudgets(id INTEGER PRIMARY KEY, categoryId INTEGER, accountId INTEGER, budget REAL)');
        db.execute('INSERT INTO settings (currency) VALUES ("€")');
        db.execute('INSERT INTO categories (id, name, color, position) VALUES (-1, "__undefined_category_name__", "${colorToHex(Colors.grey[700]!)}", 0)');
        db.execute('INSERT INTO bankaccounts (id, name, balance, income, budgetResetPrinciple, budgetResetDay) VALUES (-1, "${I18n.translate("unassignedAccount")}", 0, 0, "monthStart", 1)');
        db.execute('INSERT INTO categoryBudgets (categoryId, accountId, budget) VALUES (-1, -1, 0)');
        db.execute('CREATE TABLE editLog (id INTEGER PRIMARY KEY, affectedTable TEXT, affectedId INTEGER, type TEXT, sharedBatchId INTEGER DEFAULT -1)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE settings(
              id INTEGER PRIMARY KEY,
              totalBudget REAL
            )
          ''');
          await db.execute('''INSERT INTO settings (totalBudget) VALUES (0)''');
        }

        if (oldVersion < 5) {
          await db.execute("ALTER TABLE settings ADD COLUMN currency TEXT DEFAULT '€'");
          await db.execute("ALTER TABLE settings ADD COLUMN budgetResetPrinciple TEXT DEFAULT 'monthStart'");
          await db.execute("ALTER TABLE settings ADD COLUMN budgetResetDay INTEGER DEFAULT 1");
        }

        if (oldVersion < 6) {
          await db.execute("CREATE TABLE autoexpenses (id INTEGER PRIMARY KEY, amount REAL, categoryId INTEGER, description TEXT, bookingPrinciple TEXT, bookingDay INTEGER)");
          await db.execute('ALTER TABLE settings ADD COLUMN language TEXT DEFAULT "auto"');
          await db.execute("ALTER TABLE expenses ADD COLUMN auto TEXT DEFAULT 0");
          await db.execute("ALTER TABLE expenses ADD COLUMN autoId TEXT DEFAULT -1");
        }

        if (oldVersion < 7) {
          await db.execute("ALTER TABLE expenses ADD COLUMN categoryId INTEGER DEFAULT -1");
          await db.execute("UPDATE expenses SET categoryId = (SELECT id FROM categories WHERE name = category);");
          await db.transaction((txn) async {
            await txn.execute('CREATE TABLE expenses_new(id INTEGER PRIMARY KEY, date TEXT, amount REAL, categoryId INTEGER, description TEXT, auto INTEGER DEFAULT 0, autoId INTEGER DEFAULT -1)');
            await txn.execute('''
              INSERT INTO expenses_new (id, date, amount, description, auto, autoId, categoryId)
              SELECT id, date, amount, description, auto, autoId, categoryId FROM expenses;
            ''');
            await txn.execute('DROP TABLE expenses;');
            await txn.execute('ALTER TABLE expenses_new RENAME TO expenses;');
          });
          await db.execute("ALTER TABLE categories ADD COLUMN position INTEGER DEFAULT 0");
        }

        if (oldVersion < 9) {
          db.execute('''INSERT INTO categories (id, name, budget, color, position) VALUES (-1, "__undefined_category_name__", 0.0, "${colorToHex(Colors.grey[700]!)}", 0)''');
        }

        if (oldVersion < 10){
          await db.transaction((txn) async {
            await txn.execute('CREATE TABLE expenses_new(id INTEGER PRIMARY KEY, date TEXT, amount REAL, categoryId INTEGER, description TEXT, auto INTEGER DEFAULT 0, autoId INTEGER DEFAULT -1)');
            await txn.execute('''
              INSERT INTO expenses_new (id, date, amount, description, auto, autoId, categoryId)
              SELECT id, date, amount, description, auto, autoId, categoryId FROM expenses;
            ''');
            await txn.execute('DROP TABLE expenses;');
          });
        }

        if (oldVersion < 11){
          await db.execute('ALTER TABLE expenses_new RENAME TO expenses;');
        }

        if (oldVersion < 12){
          await db.execute('ALTER TABLE settings ADD COLUMN includePlanned INTEGER DEFAULT 0');
        }

        if (oldVersion < 13){
          await db.execute('UPDATE categories SET color = "${colorToHex(Colors.grey[700]!)}" WHERE id = -1;');
        }

        if (oldVersion < 14){
          await db.execute('''ALTER TABLE settings ADD COLUMN lastAutoExpenseRun TEXT DEFAULT "none"''');
        } 

        if (oldVersion < 15){
          await db.execute('''UPDATE expenses SET date = REPLACE(date, 'T', ' ')''');
          await db.execute('''UPDATE settings SET lastAutoExpenseRun = REPLACE(lastAutoExpenseRun, 'T', ' ')''');
        }

        if (oldVersion < 16){
          await db.execute('''ALTER TABLE settings ADD COLUMN showAvailableBudget INTEGER DEFAULT 0''');
        }

        if (oldVersion < 17){
          await db.execute('''ALTER TABLE settings ADD COLUMN isPro INTEGER DEFAULT 0''');
        }

        if (oldVersion < 18){
          
          await db.execute('INSERT OR IGNORE INTO categories (id, name, budget, color, position) VALUES (-1, "__undefined_category_name__", 0, "${colorToHex(Colors.grey[700]!)}", 0)');
        }

        if (oldVersion < 19){
          await db.execute('ALTER TABLE autoexpenses ADD COLUMN principleMode TEXT DEFAULT "monthly"');
        }

        if (oldVersion < 20){
          await db.execute('CREATE TABLE bankaccounts (id INTEGER PRIMARY KEY, name TEXT, balance REAL, income REAL, description TEXT, budgetResetPrinciple TEXT, budgetResetDay INTEGER)');
          Map<String, dynamic> result = (await db.query('settings'))[0];
          
          await db.execute('INSERT INTO bankaccounts (id, name, balance, income, budgetResetPrinciple, budgetResetDay) VALUES (-1, "${I18n.translate("unassignedAccount")}", 0, ?, ?, ?)', [result['totalBudget'], result['budgetResetPrinciple'], result['budgetResetDay']], );
          await db.execute('ALTER TABLE expenses ADD COLUMN accountId INTEGER DEFAULT -1');
          await db.execute('ALTER TABLE autoexpenses ADD COLUMN accountId INTEGER DEFAULT -1');
          await db.execute('ALTER TABLE settings ADD COLUMN useBalance INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE settings ADD COLUMN filterBudget TEXT DEFAULT "*"');
        }

        if (oldVersion < 21) {
          // transform data to new tables
          await db.execute('ALTER TABLE settings ADD COLUMN lastAdFail TEXT DEFAULT "none"');
          await db.execute('ALTER TABLE settings ADD COLUMN lastAdSuccess TEXT DEFAULT "none"');
          await db.execute('CREATE TABLE categoryBudgets(id INTEGER PRIMARY KEY, categoryId INTEGER, accountId INTEGER, budget REAL)');
          List<Map<String, dynamic>> categories = await db.query('categories');
          List<Map<String, dynamic>> bankaccounts = await db.query('bankaccounts');

          for (Map<String, dynamic> acc in bankaccounts) {
            for (Map<String, dynamic> cat in categories) {
              await db.execute("INSERT INTO categoryBudgets (categoryId, accountId, budget) VALUES (?, ?, ?)", [cat['id'], acc['id'], acc['id'] == -1 ? cat['budget'] : 0]);
            }
          }

          // remove dead columns from tables
          // settings
          await db.transaction((txn) async {
            await txn.execute('CREATE TABLE settings_new (id INTEGER PRIMARY KEY, currency TEXT, language TEXT DEFAULT "auto", includePlanned INTEGER DEFAULT 0, lastAutoExpenseRun TEXT DEFAULT "none", showAvailableBudget INTEGER DEFAULT 0, isPro INTEGER DEFAULT 0, useBalance INTEGER DEFAULT 0, filterBudget TEXT DEFAULT "*", lastAdFail TEXT DEFAULT "none", lastAdSuccess TEXT DEFAULT "none")');
            await txn.execute('''
              INSERT INTO settings_new (id, currency, language, includePlanned, lastAutoExpenseRun, showAvailableBudget, isPro, useBalance, filterBudget, lastAdFail, lastAdSuccess)
              SELECT id, currency, language, includePlanned, lastAutoExpenseRun, showAvailableBudget, isPro, useBalance, filterBudget, lastAdFail, lastAdSuccess FROM settings;
            ''');
            await txn.execute('DROP TABLE settings;');
            await txn.execute('ALTER TABLE settings_new RENAME TO settings;');
          });

          // categories
          await db.transaction((txn) async {
            await txn.execute('CREATE TABLE categories_new (id INTEGER PRIMARY KEY, name TEXT, color TEXT, position INTEGER)');
            await txn.execute('''
              INSERT INTO categories_new (id, name, color, position)
              SELECT id, name, color, position FROM categories;
            ''');
            await txn.execute('DROP TABLE categories;');
            await txn.execute('ALTER TABLE categories_new RENAME TO categories;');
          });
        }

        if (oldVersion < 22) {
          await db.execute('''ALTER TABLE bankaccounts ADD COLUMN lastSavingRun TEXT DEFAULT "none"''');
          await db.execute('''ALTER TABLE autoexpenses ADD COLUMN receiverAccountId DEFAULT -1''');
          await db.execute('''ALTER TABLE autoexpenses ADD COLUMN moneyFlow INTEGER DEFAULT 0''');
        }

        if (oldVersion < 23) {
          await db.execute('''ALTER TABLE settings ADD COLUMN lastProcessedBatchId INTEGER DEFAULT -1''');
          await db.execute('CREATE TABLE editLog (id INTEGER PRIMARY KEY, affectedTable TEXT, affectedId INTEGER, type TEXT, sharedBatchId INTEGER DEFAULT -1)');
          await db.execute('''ALTER TABLE settings ADD COLUMN sharedDbUrl TEXT DEFAULT "none"''');
        }

        if (oldVersion < 24) {
          await db.execute('''ALTER TABLE settings ADD COLUMN syncMode TEXT DEFAULT "instant"''');
          await db.execute('''ALTER TABLE settings ADD COLUMN syncFrequency INTEGER DEFAULT 1''');
          await db.execute('''ALTER TABLE settings ADD COLUMN lastSync TEXT DEFAULT "none"''');
        }

        if (oldVersion < 25) {
          await db.execute('''ALTER TABLE settings ADD COLUMN lockApp INTEGER DEFAULT 0''');
        }

        if (oldVersion < 26) {
          await db.execute('''ALTER TABLE autoexpenses ADD COLUMN ratePayment INTEGER DEFAULT 0''');
          await db.execute('''ALTER TABLE autoexpenses ADD COLUMN rateCount INTEGER''');
          await db.execute('''ALTER TABLE autoexpenses ADD COLUMN firstRateAmount REAL''');
          await db.execute('''ALTER TABLE autoexpenses ADD COLUMN lastRateAmount REAL''');
        }
      },
    );
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
        _logger.debug("Already have ebtry for this change", tag: "database");
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
    await db.execute('INSERT INTO settings (currency) VALUES ("€")');
    await db.execute('INSERT INTO categories (id, name, color, position) VALUES (-1, "__undefined_category_name__", "${colorToHex(Colors.grey[700]!)}", 0)');
    await db.execute('INSERT INTO bankaccounts (id, name, balance, income, budgetResetPrinciple, budgetResetDay) VALUES (-1, "${I18n.translate("unassignedAccount")}", 0, 0, "monthStart", 1)');
    await db.execute('INSERT INTO categoryBudgets (categoryId, accountId, budget) VALUES (-1, -1, 0)');

    await insertEditLog("categories", -1, "insert", dbObj: db);
    await insertEditLog("bankaccounts", -1, "insert", dbObj: db);
    await insertEditLog("categoryBudgets", -1, "insert", dbObj: db);
  }

  Future<void> processSavings(int accountId, Map<String, DateTime> range) async {
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

    dynamic balance = (await db.query("bankaccounts", columns: ['balance'], where: 'id = ?', whereArgs: [accountId]))[0]['balance'] as double;
    balance ??= 0.0;

    double newBalance = double.parse((balance + (income - spent)).toStringAsFixed(2));

    await db.update("bankaccounts", {"balance": newBalance}, where: 'id = ?', whereArgs: [accountId]);
    await insertEditLog("bankaccounts", accountId, "update", dbObj: db);
  }

  Future<Map<String, dynamic>> getSettings() async {
    final db = await database;
    return (await db.query('settings'))[0];
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

  Future<void> updateSettings(String key, dynamic value) async {
    final db = await database;
    await db.update('settings', {key: value}, where: 'id = 1');
  }

  Future<void> updatePositions(List<Map<String, int>> positions) async {
    final db = await database;
    for (Map<String, int> pos in positions) {
      await db.update('categories', {"position": pos['pos']}, where: 'id = ?', whereArgs: [pos['id']]);
      await insertEditLog("categories", pos['id']!, "update", dbObj: db);
    }
  }

  Future<double> getSpentForCurrentMonth(int categoryId, String accountId, Map<String, DateTime> range, bool includePlanned) async {
    final db = await database;
    final now = DateTime.now();
    final nowAfterEnd = range['end']!.isBefore(now);
    String query;
    List params = [];

    if (accountId == "*") {
      query = '''SELECT SUM(amount) as totalSpent
        FROM expenses
        WHERE categoryId = ?
          AND date >= ?
          AND date < ?
      ''';
      params = [categoryId, formatForSqlite(range['start']!), (includePlanned || nowAfterEnd) ? formatForSqlite(range['end']!) : formatForSqlite(now)];
    } else {
      query  = '''SELECT SUM(amount) as totalSpent
      FROM expenses
      WHERE categoryId = ?
        AND accountID = ?
        AND date >= ?
        AND date < ?''';
      params = [categoryId, accountId, formatForSqlite(range['start']!), (includePlanned || nowAfterEnd) ? formatForSqlite(range['end']!) : formatForSqlite(now)];
    }

    final result = await db.rawQuery(query, params);

    return (result.first['totalSpent'] as double?) ?? 0.0;
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
      int budId = await db.insert("categoryBudgets", {"categoryId": id, "accountId": acc.id, "budget": (filter == acc.id.toString()) ? category['budget'] : 0});
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

  Future<void> updateAutoExpense(Map<String, dynamic> autoExpense, int id) async {
    final db = await database;
    await db.update('autoexpenses', autoExpense, where: "id = ?", whereArgs: [id]);
    await insertEditLog("autoexpenses", id, "update", dbObj: db);
  }

  Future<void> deleteAutoExpense(int id) async {
    final db = await database;

    await db.delete('autoexpenses', where: "id = ?", whereArgs: [id]);
    await insertEditLog("autoexpenses", id, "delete", dbObj: db);
  }

  Future<int> insertBankAccount(Map<String, dynamic> bankAccount, {Database? dbObj}) async {
    final db = dbObj ?? await database;
    int id = await db.insert('bankaccounts', bankAccount);
    await insertEditLog("bankaccounts", id, "insert", dbObj: db);
    List<Category> cats = await getCategories("*");
    for (Category cat in cats) {
      int cbId = await db.insert("categoryBudgets", {"accountId": id, "categoryId": cat.id, "budget": 0});
      await insertEditLog("categoryBudgets", cbId, "insert", dbObj: db);
    }

    return id;
  }

  Future<void> updateBankAccount(Map<String, dynamic> bankAccount, id) async {
    final db = await database;
    await db.update('bankaccounts', bankAccount, where: "id = ?", whereArgs: [id]);
    await insertEditLog("bankaccounts", id, "update", dbObj: db);
  }

  Future<void> deleteBankAccount(int id) async {
    final db = await database;
    await db.delete('bankaccounts', where: "id = ?", whereArgs: [id]);
    await insertEditLog("bankaccounts", id, "delete", dbObj: db);

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

  Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
    await insertEditLog("categories", id, "delete", dbObj: db);

    List<Map<String, dynamic>> affected = await db.query('categoryBudgets', where: 'categoryId = ?', whereArgs: [id]);
    await db.delete('categoryBudgets', where: 'categoryId = ?', whereArgs: [id]);
    for (Map<String, dynamic> entry in affected) {
      await insertEditLog("categoryBudgets", entry['id'], "delete", dbObj: db);
    }

    affected = await db.query('expenses', where: 'categoryId = ?', whereArgs: [id]);
    await db.update('expenses', {'categoryId': "-1"}, where: 'categoryId = ?', whereArgs: [id]);
    for (Map<String, dynamic> entry in affected) {
      await insertEditLog("expenses", entry['id'], "update", dbObj: db);
    }

    List<Map<String, dynamic>> autoexpensesId = await db.query("autoexpenses", columns: ["id"], where: 'categoryId = ?', whereArgs: [id]);
    await db.update("autoexpenses", {"categoryId": -1}, where: 'categoryId = ?', whereArgs: [id]);
    for (Map<String, dynamic> id in autoexpensesId) {
      await insertEditLog("autoexpenses", id['id'], "update", dbObj: db);

      affected = await db.query("expenses", where: "autoId = ?", whereArgs: [id['id']]);
      await db.update("expenses", {"categoryId": -1}, where: "autoId = ?", whereArgs: [id['id']]);
      for (Map<String, dynamic> entry in affected) {
        await insertEditLog("expenses", entry['id'], "update", dbObj: db);
      }
    }
  }

  Future<List<Category>> getCategories(String filter) async {
    final db = await database;
    final List<Map<String, dynamic>> categoryData = await db.query('categories', orderBy: 'position DESC');
    final List<Map<String, dynamic>> catBudgetData = await db.query("categoryBudgets");

    return categoryData.map((data) {
      double budget;
      if (filter == "*") {
        budget = catBudgetData
          .where((cb) => cb['categoryId'] == data['id'])
          .fold(0.0, (sum, cb) => sum + (cb['budget'] ?? 0.0));
      } else {
        budget = catBudgetData.firstWhere((cb) => cb['categoryId'] == data['id'] && cb['accountId'].toString() == filter)['budget'];
      }

      return Category(
        id: data['id'] as int,
        name: data['name'] as String,
        budget: budget,
        position: data['position'],
        color: data['color'] != null ?hexToColor(data['color'] as String) : Colors.grey, // Farbe umwandeln
      );
    }).toList();
  }

  Future<List<BankAccount>> getBankAccounts(List<AutoExpense> moneyFlows) async {
    final db = await database;
    final List<Map<String, dynamic>> bankaccountdata = List.from(await db.query('bankaccounts'));
    // Konvertiere die Datenbankzeilen in Category-Objekte
    return bankaccountdata.map((data) {
      return BankAccount(
        id: data['id'] as int,
        name: data['name'] as String,
        income: data['income'] as double,
        balance: data['balance'] as double,
        description: data['description'] != null ? data['description'] as String : "",
        budgetResetPrinciple: data['budgetResetPrinciple'] as String,
        budgetResetDay: data['budgetResetDay'] as int,
        lastSavingRun: data['lastSavingRun'] as String,
        transfers: moneyFlows.where((mf) => mf.receiverAccountId == data['id']).fold(0, (sum, mf) => sum + mf.amount)
      );
    }).toList();
  }

  Future<List<AutoExpense>> getAutoExpenses({bool noMoneyFlow = true}) async {
    final db = await database;
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

  Future<void> updateCategoryBase(Category category, String filter) async {
    final db = await database;
    await db.update(
      'categories',
      {
        'name': category.name,
        'color': colorToHex(category.color),
        'position': category.position
      },
      where: 'id = ?',
      whereArgs: [category.id],
    );

    await insertEditLog("categories", category.id, "update", dbObj: db);

    if (filter == "*") {
      filter = "-1";
    }

    List<Map<String, dynamic>> affected = await db.query('categoryBudgets', where: 'categoryId = ? AND accountId = ?', whereArgs: [category.id, filter]);
    await db.update('categoryBudgets', {"budget": category.budget}, where: 'categoryId = ? AND accountId = ?', whereArgs: [category.id, filter]);
    for (Map<String, dynamic> entry in affected) {
      await insertEditLog("categoryBudgets", entry['id'], "update", dbObj: db);
    }
    
  }

  Future<bool> checkAutoExpense(int autoId, int categoryId, String date) async {
    final db = await database;
    return (await db.query("expenses", where: "autoId = ? AND categoryId = ? AND date = ?", whereArgs: [autoId, categoryId, formatForSqliteFromStr(date)])).isNotEmpty;
  }

  Future<Map<String, dynamic>> getFirstExpense() async {
    final db = await database;
    return (await db.query('expenses', limit: 1, orderBy: "date ASC"))[0];
  }

  Future<void> insertExpense(Map<String, dynamic> expense, {Database? dbObj}) async {
    final db = dbObj ?? await database;
    int id = await db.insert('expenses', expense);
    await insertEditLog("expenses", id, "insert", dbObj: db);
  }

  Future<void> updateExpense(Map<String, dynamic> expense) async {
    final db = await database;
    await db.update('expenses', expense, where: 'id = ?', whereArgs: [expense['id']]);
    await insertEditLog("expenses", expense['id'], "update", dbObj: db);
  }

  Future<void> deleteExpense(Map<String, dynamic> expense) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [expense['id']]);
    await insertEditLog("expenses", expense['id'], "delete", dbObj: db);
  }

  Future<List<Map<String, dynamic>>> getExpenses(int categoryId, String accountId, Map<String, DateTime> range) async {
    final db = await database;
    String where;
    List whereParams = [];

    if (accountId == "*") {
      where = "categoryId = ? AND date >= ? AND date <= ?";
      whereParams = [categoryId, formatForSqlite(range['start']!), formatForSqlite(range['end']!)];
    } else {
      where = "categoryId = ? AND accountId = ? AND date >= ? AND date <= ?";
      whereParams = [categoryId, accountId, formatForSqlite(range['start']!), formatForSqlite(range['end']!)];
    }

    List<Map<String, dynamic>>result = await db.query('expenses', where: where, whereArgs: whereParams, orderBy: "date ASC");
    return result;
  }

  Future<Map<String, dynamic>> getExpense(int id) async {
    final db = await database;
    return (await db.query('expenses', where: 'id = ?', whereArgs: [id]))[0];
  }

  Future<void> deleteAutoExpRealizations(int autoId, String date) async {
    final db = await database;
    List<Map<String, dynamic>> affected = await db.query("expenses", where: 'autoId = ? AND date > ?', whereArgs: [autoId, formatForSqliteFromStr(date)]);
    await db.delete('expenses', where: 'autoId = ? AND date > ?', whereArgs: [autoId, formatForSqliteFromStr(date)]);
    for (Map<String, dynamic> entry in affected) {
      await insertEditLog("expenses", entry['id'], "delete", dbObj: db);
    }
  }

  Future<List<Map<String, dynamic>>> exportTable(String table) async {
    final db = await database;
    return await db.query(table);
  }

  Future<void> resetDatabase([bool keepSettings = false]) async {
    final db = await database;
    List<String> tables;

    if (keepSettings) {
      tables = ['expenses', 'categories', 'autoexpenses', 'bankaccounts', 'categoryBudgets', 'editLog'];
    } else {
      tables = ['expenses', 'categories', 'settings', 'autoexpenses', 'bankaccounts', 'categoryBudgets', 'editLog'];
    }

    for (final table in tables) {
      await db.delete(table);
    }
  }

  Future<void> importData(Map<String, dynamic> data) async {
    final db = await database;

    await resetDatabase();

    for (Map<String, dynamic> expense in data['expenses']){
      await insertExpense(expense, dbObj: db);
    }

    for (Map<String, dynamic> autoexpenses in data['autoexpenses']){
      await insertAutoExpense(autoexpenses, dbObj: db);
    }

    if (data.keys.contains('bankaccounts')) {
      for (Map<String, dynamic> settings in data['settings']){
        settings.remove("isPro");
        await insertSettings(settings, dbObj: db);
      }

      for (Map<String, dynamic> bankaccount in data['bankaccounts']){
        await insertBankAccount(bankaccount, dbObj: db);
      }
    } else {
      Map<String, dynamic> setting = {
        "id": data['settings'][0]['id'],
        "currency": data['settings'][0]['currency'],
        "language": data['settings'][0]['language'],
        "includePlanned": data['settings'][0]['includePlanned'],
        "lastAutoExpenseRun": data['settings'][0]['lastAutoExpenseRun'],
        "showAvailableBudget": data['settings'][0]['showAvailableBudget'],
        "isPro": data['settings'][0]['isPro']
      };
      await insertSettings(setting, dbObj: db);

      Map<String, dynamic> bank = {
        "id": -1,
        "name": "__undefined_account_name__",
        "balance": 0,
        "income": data['settings'][0]['totalBudget'],
        "budgetResetPrinciple": data['settings'][0]['budgetResetPrinciple'],
        "budgetResetDay": data['settings'][0]['budgetResetDay']
      };
      await insertBankAccount(bank, dbObj: db);
    }

    final moneyFlows = await getMoneyFlows();
    
    if (data.keys.contains('categoryBudgets')) {
      for (Map<String, dynamic> categoryBudgets in data['categoryBudgets']){
        await insertCategoryBudget(categoryBudgets, dbObj: db);
      }

      for (Map<String, dynamic> categories in data['categories']){
        await insertCategoryFlat(categories, dbObj: db);
      }
    } else {
      List<BankAccount> bankAccounts = await getBankAccounts(moneyFlows);
      for (BankAccount bankAcc in bankAccounts){
        for (Map<String, dynamic> cat in data['categories']){
          Map<String, dynamic> catBudget = {
            "accountId": bankAcc.id,
            "categoryId": cat['id'],
            "budget": bankAcc.id == -1 && cat.keys.contains('budget') ? cat['budget'] : 0
          };
          await insertCategoryBudget(catBudget, dbObj: db);
        }
      }

      for (Map<String, dynamic> cat in data['categories']){
        cat.remove('budget');
        await insertCategoryFlat(cat, dbObj: db);
      }
    }

    db.delete("editLog");

    if (data.keys.contains('editLog')) {
      for (Map<String, dynamic> editLog in data['editLog']){
      await insertEditLogFlat(editLog, dbObj: db);
    }
    }
  }

  Future<List<Map<String, dynamic>>> statisticMonthTotal(Map<String, DateTime> range, dynamic filter) async {
    final db = await database;
    String query;
    List<dynamic> params = [];

    if (filter == "*") {
      query = "SELECT SUM(amount) as amount, date FROM expenses WHERE date >= ? AND date <= ? AND categoryId IS NOT NULL GROUP BY DATE(date)";
      params = [formatForSqlite(range['start']!), formatForSqlite(range['end']!)];
    } else {
      query = "SELECT SUM(amount) as amount, date FROM expenses WHERE date >= ? AND date <= ? AND categoryId IS NOT NULL AND accountId = ? GROUP BY DATE(date)";
      params = [formatForSqlite(range['start']!), formatForSqlite(range['end']!), filter];
    }
    return await db.rawQuery(query, params);
  }

  Future<List<Map<String, dynamic>>> statisticMonthTotalByCat(Map<String, DateTime> range, dynamic filter) async {
    final db = await database;
    String query;
    List<dynamic> params = [];

    if (filter == "*") {
      query = "SELECT SUM(amount) as amount, date, name as category, color FROM expenses LEFT JOIN categories ON expenses.categoryId = categories.id WHERE date >= ? AND date <= ? AND categoryId IS NOT NULL GROUP BY DATE(date), category";
      params = [formatForSqlite(range['start']!), formatForSqlite(range['end']!)];
    } else {
      query = "SELECT SUM(amount) as amount, date, name as category, color FROM expenses LEFT JOIN categories ON expenses.categoryId = categories.id WHERE date >= ? AND date <= ? AND categoryId IS NOT NULL AND accountId = ? GROUP BY DATE(date), category";
      params = [formatForSqlite(range['start']!), formatForSqlite(range['end']!), filter];
    }
    return await db.rawQuery(query, params);
  }

  Future<List<Map<String, dynamic>>> lastMonthsTotal(List<Map<String, DateTime>> ranges, dynamic filter) async {
    final db = await database;
    String query;
    List<String> params = [];

    if (filter == "*") {
      query = "SELECT SUM(amount) as amount FROM expenses WHERE date >= ? AND date <= ? AND categoryId IS NOT NULL";
    } else {
      query = "SELECT SUM(amount) as amount FROM expenses WHERE date >= ? AND date <= ? AND categoryId IS NOT NULL AND accountId = ?";
      params = [filter.toString()];
    }

    List<Map<String, dynamic>> result = [];
    for (Map<String, DateTime> range in ranges) {
      String label = createLabel(range);
      result.add({"date": label, "amount": (await db.rawQuery(query, [formatForSqlite(range['start']!), formatForSqlite(range['end']!)] + params))[0]['amount'] ?? 0.0});
    }

    return result.reversed.toList();
  }

  Future<List<Map<String, dynamic>>> lastMonthsByCat(List<Map<String, DateTime>> ranges, dynamic filter) async {
    final db = await database;
    String query;
    List<String> params = [];

    if (filter == "*") {
      query = "SELECT SUM(amount) as amount, name as category, color FROM expenses LEFT JOIN categories ON expenses.categoryId = categories.id WHERE date >= ? AND date <= ? AND categoryId IS NOT NULL GROUP BY category";
    } else {
      query = "SELECT SUM(amount) as amount, name as category, color FROM expenses LEFT JOIN categories ON expenses.categoryId = categories.id WHERE date >= ? AND date <= ? AND categoryId IS NOT NULL AND accountId = ? GROUP BY category";
      params = [filter.toString()];
    }

    List<Map<String, dynamic>> result = [];
    for (Map<String, DateTime> range in ranges) {
      String label = createLabel(range);
      List<Map<String, dynamic>> rows = await db.rawQuery(query, [formatForSqlite(range['start']!), formatForSqlite(range['end']!)] + params);
      for (Map<String, dynamic> row in rows) {
        result.add({"date": label, "amount": row['amount'], "category": row['category'], "color": row['color']});
      }
    }

    return result.reversed.toList();
  }

  Future<void> moveExpense(id, newCatid, newAccountId) async {
    final db = await database;
    await db.update("expenses", {"categoryId": newCatid, "accountId": newAccountId}, where: "id = ?", whereArgs: [id]);
    await insertEditLog("expenses", id, "update", dbObj: db);
  }

  Future<void> moveAutoExpense(id, newCatid, newAccountId) async {
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

String createLabel(Map<String, DateTime> range) {
  if (range['start']!.day == 1 && range['end']!.day == 1) {
    return shortMonthYr(range['start']!);
  } else {
    return "${shortMonthYr(range['start']!)} / ${shortMonthYr(range['end']!)}";
  }
}

String colorToHex(Color color) {
  return color.value.toRadixString(16).padLeft(8, '0');
}

Color hexToColor(String hex) {
  return Color(int.parse(hex, radix: 16));
}

String formatForSqlite(DateTime dt) {
  return dt.toIso8601String().replaceFirst("T", " ").split(".").first;
}

String formatForSqliteFromStr(String dt) {
  return dt.replaceFirst("T", " ").split(".").first;
}