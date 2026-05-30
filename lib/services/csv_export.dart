import 'dart:io';

import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/interval.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CsvExportService {
  static final _logger = Logger();

  /// Exports all expenses in the given [interval] (or all time if null)
  /// as a UTF-8 CSV file and opens the system share sheet.
  ///
  /// Columns: Date, Amount, Currency, Description, Category, Account
  static Future<void> exportExpenses({
    PBInterval? interval,
    String currency = '€',
    String filterBudget = '*',
  }) async {
    final db = DatabaseHelper();

    // Fetch raw data
    final expenses = await db.genericSelect(
      'expenses',
      filter: interval != null
          ? 'date >= ? AND date <= ?'
          : null,
      filterArgs: interval != null
          ? [formatForSqlite(interval.start), formatForSqlite(interval.end)]
          : null,
      order: 'date DESC',
    ) as List;

    final categories = await db.genericSelect('categories') as List;
    final accounts = await db.genericSelect('bankaccounts') as List;

    final categoryById = {
      for (final c in categories)
        c['id'] as int: c['name'] as String,
    };
    final accountById = {
      for (final a in accounts)
        a['id'] as int: a['name'] as String,
    };

    // Build CSV
    final buffer = StringBuffer();

    // Header — use I18n keys so the column names are translated
    buffer.writeln(_csvRow([
      I18n.translate('date'),
      I18n.translate('moneyAmount'),
      currency,
      I18n.translate('description'),
      I18n.translate('categories'),
      I18n.translate('bankaccount'),
    ]));

    for (final row in expenses) {
      final catId = row['categoryId'] as int;
      final accId = row['accountId'] as int;
      final rawCat = categoryById[catId] ?? '';
      final catName = rawCat == '__undefined_category_name__'
          ? I18n.translate('unassigned')
          : rawCat;
      final accName = accountById[accId] ?? '';

      buffer.writeln(_csvRow([
        (row['date'] as String).substring(0, 10), // YYYY-MM-DD
        (row['amount'] as num).toStringAsFixed(2),
        currency,
        row['description'] as String,
        catName,
        accName,
      ]));
    }

    // Write temp file
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/pure_budget_expenses.csv');
    await file.writeAsString(buffer.toString(), encoding: const SystemEncoding());
    _logger.info("CSV written to ${file.path}", tag: "csvExport");

    // Share
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: I18n.translate('exportData'),
    );
  }

  /// Wraps each cell for CSV: escapes double-quotes, quotes fields that
  /// contain a comma, newline, or double-quote.
  static String _csvRow(List<String> cells) {
    return cells.map((cell) {
      final escaped = cell.replaceAll('"', '""');
      if (escaped.contains(',') || escaped.contains('\n') || escaped.contains('"')) {
        return '"$escaped"';
      }
      return escaped;
    }).join(',');
  }
}
