import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jne_household_app/keys.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/widgets_shared/dialogs/debug_import_file_dialog.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsAboutScreen extends StatelessWidget {
  const SettingsAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final budgetState = Provider.of<BudgetState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(I18n.translate("settingsCategoryAbout")),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  children: [
                    Text(I18n.translate("appVersion", placeholders: {"version": appVersion})),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        const url = privacyNoticeUrl;
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url));
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            I18n.translate("privacyPolicy"),
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const Icon(Icons.open_in_new_rounded, size: 12, color: Colors.blue,)
                        ]
                      ),
                    )
                  ],
                ),
              )
            ),
            if (kDebugMode)
            ...[
              const SizedBox(height: 8),
              ElevatedButton(onPressed: () => budgetState.updateIsPro(!budgetState.settings.isPro), child: Text("DEBUG: Toggle pro\nCurrent: ${budgetState.settings.isPro}")),
              ElevatedButton(onPressed: () => {showDummyImportDialog(context, budgetState)}, child: const Text("DEBUG: Fast import pbstate lang file"))
            ]
          ]
        )
      ),
      bottomNavigationBar: (Platform.isIOS)
        ? const SizedBox(width: 1, height: 12)
        : null,
    );
  }
}
