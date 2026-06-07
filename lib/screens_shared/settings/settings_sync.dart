import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/btn_styles.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/screens_shared/remote_database.dart';
import 'package:jne_household_app/widgets_shared/settings/export_import.dart';
import 'package:provider/provider.dart';

class SettingsSyncScreen extends StatelessWidget {
  const SettingsSyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final budgetState = Provider.of<BudgetState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(I18n.translate("settingsCategorySync")),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Column(
          children: [
            ElevatedButton(
              style: btnNeutralStyle,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RemoteDatabase(budgetState: budgetState,),
                ),
              ),
              child: Text(I18n.translate("sharedDB"))
            ),
            if (budgetState.settings.sharedDbUrl == "none")
            ...[
              const SizedBox(height: 8),
              const ExportImport(),
            ],
          ]
        )
      ),
    );
  }
}
