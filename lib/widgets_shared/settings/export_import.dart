import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/models/export_import.dart';
import 'package:jne_household_app/models/interval.dart';
import 'package:jne_household_app/services/csv_export.dart';
import 'package:jne_household_app/services/format_date.dart';
import 'package:jne_household_app/services/pdf_export.dart';
import 'package:jne_household_app/widgets_shared/dialogs/adaptive_alert_dialog.dart';
import 'package:provider/provider.dart';

class ExportImport extends StatelessWidget {
  const ExportImport({super.key});

  Future<void> _handleImportData(context) async {
    await showDialog(
      context: context,
      builder: (context) {
        final budgetState = Provider.of<BudgetState>(context, listen: false);
        return StatefulBuilder(
          builder: (context, setState) {
            return AdaptiveAlertDialog(
              title: Text(I18n.translate("importData")),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      I18n.translate("warning"),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(I18n.translate("importInformation")),
                    const SizedBox(height: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await BackupManager.importDataFromFile();
                        await budgetState.reloadData();
                        navigator.pop();
                      },
                      child: Text(I18n.translate("confirmImportData")),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(I18n.translate("abortImportData")),
                    ),
                  ],
                )
              ),
            );
          },
        );
      }
    );
  }

  Future<void> _showPdfPeriodPicker(BuildContext context, BudgetState budgetState) async {
    final intervals = budgetState.budgetRanges;
    if (intervals.isEmpty) return;

    PBInterval selected = intervals.first;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AdaptiveAlertDialog(
          title: Text(I18n.translate("exportPdfSelectPeriod")),
          content: SizedBox(
            width: double.maxFinite,
            child: RadioGroup<PBInterval>(
              groupValue: selected,
              onChanged: (v) { if (v != null) setState(() => selected = v); },
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: intervals.length,
                itemBuilder: (_, i) {
                  final interval = intervals[i];
                  final label = i == 0
                      ? I18n.translate("currentRange")
                      : '${formatDate(interval.start.toIso8601String(), ctx, short: true)}'
                        ' – '
                        '${formatDate(interval.end.toIso8601String(), ctx, short: true)}';
                  return RadioListTile<PBInterval>(
                    title: Text(label),
                    value: interval,
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(I18n.translate("cancel")),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: Text(I18n.translate("exportPdf")),
              onPressed: () async {
                final navigator = Navigator.of(ctx);
                navigator.pop();
                await PdfExportService.exportReport(
                  interval: selected,
                  currency: budgetState.settings.currency,
                  filterBudget: budgetState.settings.filterBudget,
                  appTitle: I18n.translate("appTitle"),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = Provider.of<BudgetState>(context, listen: false);
    final isPro = budgetState.proStatusIsSet(simplePro: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Backup (encrypted .pbstate) ────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => BackupManager.exportData(),
              child: Text(I18n.translate("exportData")),
            ),
            ElevatedButton(
              onPressed: () => _handleImportData(context),
              child: Text(I18n.translate("importData")),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // ── CSV export ─────────────────────────────────────────────────────
        OutlinedButton.icon(
          icon: const Icon(Icons.table_chart_rounded),
          label: Text(I18n.translate("exportCsv")),
          onPressed: () => CsvExportService.exportExpenses(
            currency: budgetState.settings.currency,
            filterBudget: budgetState.settings.filterBudget,
          ),
        ),
        const SizedBox(height: 4),
        // ── PDF export (Pro) ────────────────────────────────────────────────
        Tooltip(
          message: isPro ? '' : I18n.translate("proFeature"),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: Text(
              '${I18n.translate("exportPdf")}${isPro ? '' : ' ★'}',
            ),
            onPressed: isPro
                ? () => _showPdfPeriodPicker(context, budgetState)
                : null,
          ),
        ),
      ],
    );
  }
}