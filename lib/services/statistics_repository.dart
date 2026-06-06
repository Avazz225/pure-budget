import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/models/interval.dart';

/// All time-series statistics queries, extracted from DatabaseHelper.
/// Uses the DatabaseHelper singleton internally.
class StatisticsRepository {
  static final StatisticsRepository _instance = StatisticsRepository._internal();
  factory StatisticsRepository() => _instance;
  StatisticsRepository._internal();

  Future<List<Map<String, dynamic>>> statisticMonthTotal(
      PBInterval range, dynamic filter) async {
    final db = await DatabaseHelper().database;
    String query;
    List<dynamic> params = [];

    if (filter == "*") {
      query =
          "SELECT SUM(amount) as amount, date FROM expenses WHERE date >= ? AND date <= ? AND categoryId IS NOT NULL GROUP BY DATE(date)";
      params = [formatForSqlite(range.start), formatForSqlite(range.end)];
    } else {
      query =
          "SELECT SUM(amount) as amount, date FROM expenses WHERE date >= ? AND date <= ? AND categoryId IS NOT NULL AND accountId = ? GROUP BY DATE(date)";
      params = [formatForSqlite(range.start), formatForSqlite(range.end), filter];
    }
    return db.rawQuery(query, params);
  }

  Future<List<Map<String, dynamic>>> statisticMonthTotalByCat(
      PBInterval range, dynamic filter) async {
    final db = await DatabaseHelper().database;
    String query;
    List<dynamic> params = [];

    if (filter == "*") {
      query =
          "SELECT SUM(amount) as amount, date, name as category, color FROM expenses LEFT JOIN categories ON expenses.categoryId = categories.id WHERE date >= ? AND date <= ? AND categoryId IS NOT NULL GROUP BY DATE(date), category";
      params = [formatForSqlite(range.start), formatForSqlite(range.end)];
    } else {
      query =
          "SELECT SUM(amount) as amount, date, name as category, color FROM expenses LEFT JOIN categories ON expenses.categoryId = categories.id WHERE date >= ? AND date <= ? AND categoryId IS NOT NULL AND accountId = ? GROUP BY DATE(date), category";
      params = [formatForSqlite(range.start), formatForSqlite(range.end), filter];
    }
    return db.rawQuery(query, params);
  }

  Future<List<Map<String, dynamic>>> lastMonthsTotal(
      List<PBInterval> ranges, dynamic filter) async {
    final db = await DatabaseHelper().database;
    String query;
    List<String> extra = [];

    if (filter == "*") {
      query =
          "SELECT SUM(amount) as amount FROM expenses WHERE date >= ? AND date <= ? AND categoryId IS NOT NULL";
    } else {
      query =
          "SELECT SUM(amount) as amount FROM expenses WHERE date >= ? AND date <= ? AND categoryId IS NOT NULL AND accountId = ?";
      extra = [filter.toString()];
    }

    final result = <Map<String, dynamic>>[];
    for (final range in ranges) {
      final label = _label(range);
      final rows = await db.rawQuery(
          query, [formatForSqlite(range.start), formatForSqlite(range.end), ...extra]);
      result.add({"date": label, "amount": rows[0]['amount'] ?? 0.0});
    }
    return result.reversed.toList();
  }

  Future<List<Map<String, dynamic>>> lastTotalBudgets(
      List<PBInterval> ranges, dynamic filter) async {
    final db = await DatabaseHelper().database;
    String query;
    List<String> extra = [];

    if (filter == "*") {
      query = "SELECT SUM(income) as income FROM realizedBankaccounts WHERE intervalId = ?";
    } else {
      query =
          "SELECT SUM(income) as income FROM realizedBankaccounts WHERE intervalId = ? AND accountId = ?";
      extra = [filter.toString()];
    }

    final result = <Map<String, dynamic>>[];
    for (final range in ranges) {
      final label = _label(range);
      final rows = await db.rawQuery(query, [range.id, ...extra]);
      result.add({"date": label, "income": rows[0]['income'] ?? 0.0});
    }
    return result.reversed.toList();
  }

  Future<List<Map<String, dynamic>>> lastMonthsByCat(
      List<PBInterval> ranges, dynamic filter) async {
    final db = await DatabaseHelper().database;
    String query;
    List<String> extra = [];

    if (filter == "*") {
      query =
          "SELECT SUM(amount) as amount, name as category, color FROM expenses LEFT JOIN categories ON expenses.categoryId = categories.id WHERE date >= ? AND date <= ? AND categoryId IS NOT NULL GROUP BY category";
    } else {
      query =
          "SELECT SUM(amount) as amount, name as category, color FROM expenses LEFT JOIN categories ON expenses.categoryId = categories.id WHERE date >= ? AND date <= ? AND categoryId IS NOT NULL AND accountId = ? GROUP BY category";
      extra = [filter.toString()];
    }

    final result = <Map<String, dynamic>>[];
    for (final range in ranges) {
      final label = _label(range);
      final rows = await db.rawQuery(
          query, [formatForSqlite(range.start), formatForSqlite(range.end), ...extra]);
      for (final row in rows) {
        result.add({"date": label, "amount": row['amount'], "category": row['category'], "color": row['color']});
      }
    }
    return result.reversed.toList();
  }

  Future<List<Map<String, dynamic>>> lastMonthsCatBudget(
      List<PBInterval> ranges, dynamic filter) async {
    final db = await DatabaseHelper().database;
    String query;
    List<String> extra = [];

    if (filter == "*") {
      query =
          "SELECT SUM(budget) as budget, name as category FROM realizedCategoryBudgets LEFT JOIN categories ON realizedCategoryBudgets.categoryId = categories.id WHERE intervalId = ? GROUP BY category";
    } else {
      query =
          "SELECT SUM(budget) as budget, name as category FROM realizedCategoryBudgets LEFT JOIN categories ON realizedCategoryBudgets.categoryId = categories.id WHERE intervalId = ? AND accountId = ? GROUP BY category";
      extra = [filter.toString()];
    }

    final result = <Map<String, dynamic>>[];
    for (final range in ranges) {
      final label = _label(range);
      final rows = await db.rawQuery(query, [range.id, ...extra]);
      for (final row in rows) {
        result.add({"date": label, "income": row['budget'], "category": row['category']});
      }
    }
    return result.reversed.toList();
  }

  // ── Private ───────────────────────────────────────────────────────────────

  static String _label(PBInterval range) {
    return createLabel(range); // delegates to top-level helper in database_helper.dart
  }
}
