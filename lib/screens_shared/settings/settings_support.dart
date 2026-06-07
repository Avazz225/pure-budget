import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/btn_styles.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/keys.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/screens_shared/help_screen.dart';
import 'package:jne_household_app/widgets_shared/dialogs/report_issue_dialog.dart';
import 'package:jne_household_app/widgets_shared/settings/settings_category_tile.dart';
import 'package:mail_sender/mail_sender.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class SettingsSupportScreen extends StatelessWidget {
  const SettingsSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final budgetState = Provider.of<BudgetState>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(I18n.translate("settingsCategorySupport")),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Column(
          children: [
            SettingsCategoryTile(
              icon: Icons.help_rounded,
              title: I18n.translate("help"),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const HelpScreen(),
                ),
              ),
            ),
            if (Platform.isAndroid || Platform.isIOS)
            ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.tour_rounded),
                label: Text(I18n.translate("replayTour")),
                onPressed: () async {
                  await budgetState.updateTourCompleted(false);
                  if (context.mounted) Navigator.of(context).pop();
                },
              ),
            ],
            if (!Platform.isIOS && !Platform.isAndroid)
            ...[
              const SizedBox(height: 8),
              ElevatedButton(
                style: btnNeutralStyle,
                onPressed: () async {
                  final dir = await getApplicationDocumentsDirectory();
                  final path = p.join(dir.path, 'PureBudget');
                  if (Platform.isWindows) {
                    Process.run('explorer', [path]);
                  } else if (Platform.isMacOS) {
                    Process.run('open', [path]);
                  } else if (Platform.isLinux) {
                    Process.run('xdg-open', [path]);
                  }
                },
                child: Text(I18n.translate("showLogs"))
              ),
            ],
            const SizedBox(height: 8),
            ElevatedButton(
              style: btnNeutralStyle,
              onPressed: () async {
                List<String> data = await showReportIssueDialog(context, budgetState);
                if (data.length == 2) {
                  if (Platform.isAndroid || Platform.isIOS) {
                    final mailSenderPlugin = MailSender();
                    mailSenderPlugin.sendMail(
                      recipient: [reportEmail],
                      subject: data[0],
                      body: data[1]
                    );
                  }
                }
              },
              child: Text(I18n.translate("report")),
            ),
          ]
        )
      ),
    );
  }
}
