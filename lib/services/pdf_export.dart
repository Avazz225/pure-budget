import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/interval.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class PdfExportService {
  static final _logger = Logger();

  // ── Colour palette ─────────────────────────────────────────────────────────
  static const _headerBg = PdfColor.fromInt(0xFF1976D2);   // primary blue
  static const _altRow    = PdfColor.fromInt(0xFFF5F5F5);  // light grey
  static const _overBudget= PdfColor.fromInt(0xFFD32F2F);  // red

  /// Generates a PDF report for the given [interval] and shares it.
  ///
  /// [filterBudget] is `"*"` for all accounts or a bank-account-id string.
  static Future<void> exportReport({
    required PBInterval interval,
    required String currency,
    required String filterBudget,
    String appTitle = 'Pure Budget',
  }) async {
    final db = DatabaseHelper();

    // ── Fetch data ────────────────────────────────────────────────────────────
    final rawExpenses = await db.genericSelect(
      'expenses',
      filter: 'date >= ? AND date < ?',
      filterArgs: [formatForSqlite(interval.start), formatForSqlite(interval.end)],
      order: 'date ASC',
    ) as List;

    final categories = await db.genericSelect('categories') as List;
    final accounts   = await db.genericSelect('bankaccounts') as List;

    final categoryById = {for (final c in categories) c['id'] as int: c['name'] as String};
    final accountById  = {for (final a in accounts)   a['id'] as int: a['name'] as String};

    // Filter by account if needed
    final expenses = filterBudget == '*'
        ? rawExpenses
        : rawExpenses.where((e) => e['accountId'].toString() == filterBudget).toList();

    // ── Aggregations ──────────────────────────────────────────────────────────
    final totalSpent = expenses.fold<double>(0, (s, e) => s + (e['amount'] as num));

    // Total budget (income) from realizedBankaccounts for the exact interval.
    // This is the historically correct value, not the current account income.
    final dbRaw = await db.database;
    final budgetRows = filterBudget == '*'
        ? await dbRaw.rawQuery(
            'SELECT SUM(income) AS totalIncome FROM realizedBankaccounts WHERE intervalId = ?',
            [interval.id])
        : await dbRaw.rawQuery(
            'SELECT SUM(income) AS totalIncome FROM realizedBankaccounts WHERE intervalId = ? AND accountId = ?',
            [interval.id, int.tryParse(filterBudget)]);
    final totalBudget = (budgetRows.first['totalIncome'] as num?)?.toDouble() ?? 0;

    // Category totals (actual spending per category)
    final catTotals = <int, double>{};
    for (final e in expenses) {
      final id = e['categoryId'] as int;
      catTotals[id] = (catTotals[id] ?? 0) + (e['amount'] as num);
    }

    // Historical budgets from realizedCategoryBudgets for the exact interval.
    // accountId = -1 is the sentinel used when filterBudget == "*".
    final accountId = filterBudget == '*' ? -1 : (int.tryParse(filterBudget) ?? -1);
    final realizedBudgets = await dbRaw.rawQuery(
      'SELECT categoryId, budget FROM realizedCategoryBudgets WHERE intervalId = ? AND accountId = ?',
      [interval.id, accountId],
    );

    final catBudgetMap = <int, double>{};
    double assignedBudget = 0;
    for (final row in realizedBudgets) {
      final catId = row['categoryId'] as int;
      final bgt = (row['budget'] as num).toDouble();
      if (catId != -1) {
        catBudgetMap[catId] = bgt;
        assignedBudget += bgt;
      }
    }
    // "Unassigned" budget = total income − sum of all named category budgets
    catBudgetMap[-1] = (totalBudget - assignedBudget).clamp(0, double.infinity);

    // ── Load font (Unicode support: €, –, — etc.) ─────────────────────────────
    final fontData = await rootBundle.load('lib/assets/fonts/RobotoMono-Bold.ttf');
    final ttf = pw.Font.ttf(fontData);
    final theme = pw.ThemeData.withFont(base: ttf, bold: ttf);

    // ── Build PDF ─────────────────────────────────────────────────────────────
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _buildHeader(ctx, appTitle, interval, currency),
        footer: (ctx) => _buildFooter(ctx),
        build: (ctx) => [
          _summarySection(totalBudget, totalSpent, currency),
          pw.SizedBox(height: 16),
          _categoryTable(catTotals, catBudgetMap, categoryById, currency),
          pw.SizedBox(height: 16),
          _expenseTable(expenses, categoryById, accountById, currency),
        ],
      ),
    );

    // ── Write & deliver ───────────────────────────────────────────────────────
    final bytes = await pdf.save();
    final defaultName =
        'pure_budget_${_periodLabel(interval).replaceAll(' ', '').replaceAll('.', '-')}.pdf';

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // Desktop: native save-file dialog so the user picks the location
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: I18n.translate("pdfSaveDialogTitle"),
        fileName: defaultName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (savePath == null) return; // user cancelled
      await File(savePath).writeAsBytes(bytes);
      _logger.info("PDF saved to $savePath", tag: "pdfExport");
    } else {
      // Mobile: system share sheet
      final dir  = await getTemporaryDirectory();
      final path = '${dir.path}/$defaultName';
      await File(path).writeAsBytes(bytes);
      _logger.info("PDF written to $path", tag: "pdfExport");
      await Share.shareXFiles(
        [XFile(path, mimeType: 'application/pdf')],
        subject: '$appTitle — ${_periodLabel(interval)}',
      );
    }
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  static pw.Widget _buildHeader(
    pw.Context ctx,
    String title,
    PBInterval interval,
    String currency,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _headerBg, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold,
                  color: _headerBg)),
          pw.Text(_periodLabel(interval),
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        '${I18n.translate("page")} ${ctx.pageNumber} / ${ctx.pagesCount}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
      ),
    );
  }

  static pw.Widget _summarySection(
      double totalBudget, double totalSpent, String currency) {
    final balance = totalBudget - totalSpent;
    final overBudget = balance < 0;
    final balanceStr =
        '${overBudget ? '' : '+'}${balance.toStringAsFixed(2)} $currency';

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _altRow,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _statCell(I18n.translate('budget'),
              '${totalBudget.toStringAsFixed(2)} $currency'),
          _statCell(I18n.translate('totalSpentLabel'),
              '${totalSpent.toStringAsFixed(2)} $currency'),
          _statCell(
            I18n.translate('balance'),
            balanceStr,
            valueColor: overBudget ? _overBudget : PdfColors.green800,
          ),
        ],
      ),
    );
  }

  static pw.Widget _statCell(String label, String value,
      {PdfColor valueColor = PdfColors.black}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: valueColor)),
      ],
    );
  }

  static pw.Widget _categoryTable(
    Map<int, double> catTotals,
    Map<int, double> catBudgetMap,
    Map<int, String> categoryById,
    String currency,
  ) {
    final rows = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(I18n.translate('categories')),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
          },
          children: [
            _tableHeaderRow([
              I18n.translate('categories'),
              I18n.translate('budget'),
              I18n.translate('labelSpent'),
              I18n.translate('remaining'),
            ]),
            for (int i = 0; i < rows.length; i++)
              _categoryRow(rows[i], catBudgetMap, categoryById, currency, i.isOdd),
          ],
        ),
      ],
    );
  }

  static pw.TableRow _categoryRow(
    MapEntry<int, double> entry,
    Map<int, double> catBudgetMap,
    Map<int, String> categoryById,
    String currency,
    bool shade,
  ) {
    final catId   = entry.key;
    final spent   = entry.value;
    final budget  = catBudgetMap[catId] ?? 0;
    final remaining = budget - spent;
    final overBudget = spent > budget && budget > 0;
    final rawName = categoryById[catId] ?? '';
    final name = rawName == '__undefined_category_name__' ? I18n.translate('unassigned') : rawName;

    final style = pw.TextStyle(
      fontSize: 9,
      color: overBudget ? _overBudget : PdfColors.black,
    );

    return pw.TableRow(
      decoration: pw.BoxDecoration(color: shade ? _altRow : null),
      children: [
        _cell(name, style: style),
        _cell(budget > 0 ? '${budget.toStringAsFixed(2)} $currency' : '-', style: style),
        _cell('${spent.toStringAsFixed(2)} $currency', style: style),
        _cell(budget > 0 ? '${remaining.toStringAsFixed(2)} $currency' : '-',
              style: style.copyWith(color: overBudget ? _overBudget : PdfColors.green800)),
      ],
    );
  }

  static pw.Widget _expenseTable(
    List expenses,
    Map<int, String> categoryById,
    Map<int, String> accountById,
    String currency,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(I18n.translate('expenses')),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(72),  // date
            1: const pw.FlexColumnWidth(3),     // description
            2: const pw.FlexColumnWidth(2),     // category
            3: const pw.FixedColumnWidth(70),   // amount
          },
          children: [
            _tableHeaderRow([
              I18n.translate('date'),
              I18n.translate('description'),
              I18n.translate('categories'),
              I18n.translate('moneyAmount'),
            ]),
            for (int i = 0; i < expenses.length; i++)
              _expenseRow(expenses[i], categoryById, accountById, currency, i.isOdd),
          ],
        ),
      ],
    );
  }

  static pw.TableRow _expenseRow(
    dynamic expense,
    Map<int, String> categoryById,
    Map<int, String> accountById,
    String currency,
    bool shade,
  ) {
    final rawCat = categoryById[expense['categoryId'] as int] ?? '';
    final catName = rawCat == '__undefined_category_name__' ? I18n.translate('unassigned') : rawCat;
    final amount = (expense['amount'] as num).toDouble();
    final amountStr = '${amount.toStringAsFixed(2)} $currency';
    final d = DateTime.parse(expense['date'] as String);
    final dateStr = '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    const style = pw.TextStyle(fontSize: 9);

    return pw.TableRow(
      decoration: pw.BoxDecoration(color: shade ? _altRow : null),
      children: [
        _cell(dateStr, style: style),
        _cell(expense['description'] as String, style: style),
        _cell(catName, style: style),
        _cell(amountStr,
              style: style.copyWith(color: amount < 0 ? PdfColors.green800 : PdfColors.black)),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static pw.TableRow _tableHeaderRow(List<String> labels) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: _headerBg),
      children: labels
          .map((l) => _cell(l,
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white)))
          .toList(),
    );
  }

  static pw.Widget _cell(String text, {pw.TextStyle? style}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(text, style: style ?? const pw.TextStyle(fontSize: 9)),
    );
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
          fontSize: 12, fontWeight: pw.FontWeight.bold, color: _headerBg),
    );
  }

  static String _periodLabel(PBInterval interval) {
    final s = interval.start;
    final e = interval.end;
    return '${s.day.toString().padLeft(2, '0')}.${s.month.toString().padLeft(2, '0')}.${s.year}'
        ' – '
        '${e.day.toString().padLeft(2, '0')}.${e.month.toString().padLeft(2, '0')}.${e.year}';
  }
}
