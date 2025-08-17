import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/models/export_import.dart';
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
                    ElevatedButton(
                      onPressed: () async {
                        await BackupManager.importDataFromFile();
                        await budgetState.reloadData();
                        Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () => BackupManager.exportData(),
          child: Text(I18n.translate("exportData")),
        ),
        ElevatedButton(
          onPressed: () => _handleImportData(context),
          child: Text(I18n.translate("importData")),
        )
      ],
    );
  }
}