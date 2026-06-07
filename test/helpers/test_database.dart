/// Test helper: opens an in-memory SQLite database with the full production
/// schema and wires it into the DatabaseHelper singleton.
///
/// Usage:
///   setUp(setUpTestDatabase);
///   tearDown(tearDownTestDatabase);
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/logger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Module-level reference so tearDown can close the DB without going through
// the DatabaseHelper singleton (which might try to call _initDatabase if setUp
// failed mid-way).
Database? _currentTestDb;

// Logger.init() uses a `late final` field — call it only once per process.
bool _loggerInitialized = false;

/// Opens a fresh in-memory database with the production schema and injects it
/// into DatabaseHelper. Call at the start of every test or in setUp.
Future<Database> setUpTestDatabase() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  if (!_loggerInitialized) {
    await Logger().init(minLevel: LogLevel.error);
    _loggerInitialized = true;
  }

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 39,
      onCreate: _createSchema,
    ),
  );

  _currentTestDb = db;
  DatabaseHelper.overrideDatabaseForTesting(db);
  return db;
}

/// Closes the database and resets the DatabaseHelper singleton.
/// Call in tearDown.
Future<void> tearDownTestDatabase() async {
  await _currentTestDb?.close();
  _currentTestDb = null;
  DatabaseHelper.resetForTesting();
}

// ---------------------------------------------------------------------------
// Schema — mirrors database_helper.dart _initDatabase onCreate exactly.
// If the schema changes in production, update here too.
// ---------------------------------------------------------------------------
Future<void> _createSchema(Database db, int version) async {
  await db.execute(
    'CREATE TABLE expenses(id INTEGER PRIMARY KEY, date TEXT, amount REAL, accountId INTEGER DEFAULT -1, categoryId INTEGER, description TEXT, auto INTEGER DEFAULT 0, autoId INTEGER DEFAULT -1)',
  );
  await db.execute(
    'CREATE TABLE categories(id INTEGER PRIMARY KEY, name TEXT, color TEXT, position INTEGER)',
  );
  await db.execute(
    "CREATE TABLE settings (id INTEGER PRIMARY KEY, currency TEXT, language TEXT DEFAULT 'auto', includePlanned INTEGER DEFAULT 0, lastAutoExpenseRun TEXT DEFAULT 'none', showAvailableBudget INTEGER DEFAULT 0, isPro INTEGER DEFAULT 0, useBalance INTEGER DEFAULT 0, filterBudget TEXT DEFAULT '*', lastAdFail TEXT DEFAULT 'none', lastAdSuccess TEXT DEFAULT 'none', lastSavingRun TEXT DEFAULT 'none', lastProcessedBatchId INTEGER DEFAULT -1, sharedDbUrl TEXT DEFAULT 'none', syncMode TEXT DEFAULT 'instant', syncFrequency INTEGER DEFAULT 1, lastSync TEXT DEFAULT 'none', lockApp INTEGER DEFAULT 0, isDesktopPro INTEGER DEFAULT 0, selectedScanCategory INTEGER DEFAULT -1, reminder TEXT DEFAULT '{}', lastCreditCardRefillRun TEXT DEFAULT 'none', tourCompleted INTEGER DEFAULT 0)",
  );
  await db.execute(
    "CREATE TABLE autoexpenses (id INTEGER PRIMARY KEY, amount REAL, accountId INTEGER DEFAULT -1, categoryId INTEGER, description TEXT, bookingPrinciple TEXT, bookingDay INTEGER, principleMode TEXT DEFAULT 'monthly', receiverAccountId DEFAULT -1, moneyFlow INTEGER DEFAULT 0, ratePayment INTEGER DEFAULT 0, rateCount INTEGER, firstRateAmount REAL, lastRateAmount REAL)",
  );
  await db.execute(
    "CREATE TABLE bankaccounts (id INTEGER PRIMARY KEY, name TEXT, balance REAL, income REAL, description TEXT, budgetResetPrinciple TEXT, budgetResetDay INTEGER, lastSavingRun TEXT DEFAULT 'none', isCreditCard INTEGER DEFAULT 0, refillsFrom INTEGER DEFAULT -1, refillPrincipleMode TEXT DEFAULT 'monthly')",
  );
  await db.execute(
    'CREATE TABLE categoryBudgets(id INTEGER PRIMARY KEY, categoryId INTEGER, accountId INTEGER, budget REAL, overrideBankAccount INTEGER DEFAULT null)',
  );
  await db.execute(
    "CREATE TABLE editLog (id INTEGER PRIMARY KEY, affectedTable TEXT, affectedId INTEGER, type TEXT, sharedBatchId INTEGER DEFAULT -1)",
  );
  await db.execute(
    "CREATE TABLE design (id INTEGER PRIMARY KEY, layoutMainVertical INTEGER DEFAULT 1, categoryMainStyle INTEGER DEFAULT 0, addExpenseStyle INTEGER DEFAULT 1, arcStyle INTEGER DEFAULT 0, arcPercent REAL DEFAULT 50.0, arcWidth REAL DEFAULT 0.8, arcSegmentsRounded INTEGER DEFAULT 1, dialogSolidBackground INTEGER DEFAULT 1, appBackgroundSolid INTEGER DEFAULT 1, appBackground INTEGER DEFAULT 0, customBackgroundBlur INTEGER DEFAULT 0, customBackgroundPath TEXT DEFAULT 'none', mainMenuStyle INTEGER DEFAULT 0, blurIntensity REAL DEFAULT 0.1, customGradient TEXT DEFAULT '{}', intervalStyle INTEGER DEFAULT 0, goMobileBannerDismissed INTEGER DEFAULT 0, liquidGlassMode INTEGER DEFAULT 0, navBarStyle INTEGER DEFAULT 0)",
  );
  await db.execute(
    'CREATE TABLE creditCardRefills (id INTEGER PRIMARY KEY, accountId INTEGER, creditAccountId INTEGER, amount REAL, date TEXT, categoryId INTEGER)',
  );
  await db.execute(
    'CREATE TABLE intervals (id INTEGER PRIMARY KEY, start TEXT, end TEXT, accountId INTEGER)',
  );
  await db.execute(
    'CREATE TABLE realizedCategoryBudgets (id INTEGER PRIMARY KEY, intervalId INTEGER, accountId INTEGER, categoryId INTEGER, budget REAL, overrideBankAccount INTEGER DEFAULT null)',
  );
  await db.execute(
    'CREATE TABLE realizedBankaccounts (id INTEGER PRIMARY KEY, intervalId INTEGER, accountId INTEGER, balance REAL, income REAL)',
  );
  await db.execute(
    'CREATE TABLE realizedAutoexpenses (id INTEGER PRIMARY KEY, intervalId INTEGER, autoexpenseId INTEGER, expenseId INTEGER)',
  );

  // Sentinel records required by the app (id = -1 = "Unassigned")
  await db.execute("INSERT INTO settings (currency) VALUES ('€')");
  await db.execute("INSERT INTO design (id) VALUES (1)");
  await db.execute(
    "INSERT INTO categories (id, name, color, position) VALUES (-1, '__undefined_category_name__', 'ff616161', 0)",
  );
  await db.execute(
    "INSERT INTO bankaccounts (id, name, balance, income, budgetResetPrinciple, budgetResetDay) VALUES (-1, 'Unassigned', 0, 0, 'monthStart', 1)",
  );
  await db.execute(
    'INSERT INTO categoryBudgets (categoryId, accountId, budget) VALUES (-1, -1, 0)',
  );

  // A valid current-month interval for the sentinel account (-1) prevents
  // checkNewInterval() and backgroundJobs() from treating it as needing rollover.
  final now = DateTime.now();
  final monthStart = '${now.year}-${now.month.toString().padLeft(2, '0')}-01 00:00:00';
  final nextMonth = now.month == 12 ? 1 : now.month + 1;
  final nextYear = now.month == 12 ? now.year + 1 : now.year;
  final monthEnd = '$nextYear-${nextMonth.toString().padLeft(2, '0')}-01 00:00:00';
  await db.execute(
    "INSERT INTO intervals (start, end, accountId) VALUES ('$monthStart', '$monthEnd', -1)",
  );
  // realizedBankaccounts for sentinel interval (needed if backgroundJobs rolls over another account)
  await db.execute(
    "INSERT INTO realizedBankaccounts (intervalId, accountId, income, balance) VALUES (last_insert_rowid(), -1, 0, 0)",
  );
}
