// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';

import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/models/export_import.dart';
import 'package:jne_household_app/widgets_shared/dialogs/adaptive_alert_dialog.dart';
import 'package:path/path.dart' as p;

void showDummyImportDialog(BuildContext context, BudgetState budgetState) {
  List<String> langCodes = I18n.getProvidedRealLangs();
  Logger logger = Logger();

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AdaptiveAlertDialog(
        title: const Text('Dummy-Daten importieren'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: langCodes.length,
            itemBuilder: (context, index) {
              final code = langCodes[index];
              return ListTile(
                leading: const Icon(Icons.file_copy),
                title: Text('Import: $code'),
                onTap: () async {
                  final path = p.join(
                    Directory.current.path,
                    'dummydata',
                    'exports',
                    '$code.pbstate',
                  );
                  logger.debug("Starting import of $path dummydata", tag:"dummyImport");

                  if (await BackupManager.importDataFromFile(path: path)) {
                    await budgetState.updateLanguage(code);
                    await budgetState.reloadData();
                    logger.debug("Loaded data from $path", tag:"dummyImport");
                    Navigator.of(dialogContext).pop();
                  } else {
                    logger.debug("Failed to load data from $path", tag:"dummyImport");
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Data not found: $path')),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
        ],
      );
    },
  );
}
