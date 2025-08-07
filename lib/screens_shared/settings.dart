// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/btn_styles.dart';
import 'package:jne_household_app/helper/free_restrictions.dart';
import 'package:jne_household_app/keys.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/screens_shared/remote_database.dart';
import 'package:jne_household_app/widgets_shared/settings/bank_account.dart';
import 'package:jne_household_app/widgets_shared/settings/export_import.dart';
import 'package:jne_household_app/widgets_shared/settings/language.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

final List<Color> availableColors = [
  Colors.red[400]!,
  Colors.deepOrange[400]!,
  Colors.lime[800]!,
  Colors.green[600]!,
  Colors.blue[600]!,
  Colors.cyan[700]!,
  Colors.indigo[400]!,
  Colors.purple[400]!,
  Colors.pink[400]!
];

class SettingsScreenState extends State<SettingsScreen> {
  SettingsScreenState();
  
  final LocalAuthentication auth = LocalAuthentication();

  void _editCurrency(String currency){
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController currencyController = TextEditingController(text: currency);

        return AlertDialog(
          title: Text(I18n.translate("editCurrency")),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SingleChildScrollView(
                child: TextField(
                  controller: currencyController,
                  decoration: InputDecoration(labelText: I18n.translate("currency")),
                )
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(I18n.translate("cancel")),
            ),
            TextButton(
              onPressed: () async {
                final settingsState = Provider.of<BudgetState>(context, listen: false);
                await settingsState.updateCurrency(currencyController.text);
                Navigator.of(context).pop();
              },
              child: Text(I18n.translate("save")),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = Provider.of<BudgetState>(context);
    final currency = budgetState.currency;

    return Scaffold(
      appBar: AppBar(
        title: Text(I18n.translate("appSettings")),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Column(
          children: [ 
            Card(
              child: Padding (
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      I18n.translate("currencyWithVal", placeholders: {"currency": currency.toString()}),
                      style: Theme.of(context).textTheme.bodyLarge
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: () => _editCurrency(currency),
                    ),
                  ],
                ),
              )
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        I18n.translate("includePlannedSpendings"),
                        style: Theme.of(context).textTheme.bodyLarge,
                      )
                    ),
                    Switch(
                      value: budgetState.includePlanned,
                      onChanged: (value) {
                        setState(() {
                          budgetState.updateInclude(value);
                        });
                      },
                      activeColor: Colors.green,
                    )
                  ],
                )
              )
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        I18n.translate("showAvailableBudget"),
                        style: Theme.of(context).textTheme.bodyLarge,
                      )
                    ),
                    Switch(
                      value: budgetState.showAvailableBudget,
                      onChanged: (value) {
                        setState(() {
                          budgetState.updateAvailableBudget(value);
                        });
                      },
                      activeColor: Colors.green,
                    )
                  ],
                )
              )
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        I18n.translate("considerBalance"),
                        style: Theme.of(context).textTheme.bodyLarge,
                      )
                    ),
                    Switch(
                      value: budgetState.useBalance,
                      onChanged: (value) {
                        setState(() {
                          budgetState.updateUseBalance(value);
                        });
                      },
                      activeColor: Colors.green,
                    )
                  ],
                )
              )
            ),
            if (Platform.isAndroid || Platform.isIOS)
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        I18n.translate("lockApp"),
                        style: Theme.of(context).textTheme.bodyLarge,
                      )
                    ),
                    Switch(
                      value: budgetState.lockApp,
                      onChanged: (value) async {
                        try {
                          bool supported = await auth.isDeviceSupported();
                          bool biometricAvailable = await auth.canCheckBiometrics;
                          final isBiometricAvailable = biometricAvailable || supported;
                          if (isBiometricAvailable) {
                            bool authenticated = await auth.authenticate(
                              localizedReason: I18n.translate("authRequired"),
                              options: const AuthenticationOptions(
                                useErrorDialogs: true,
                                stickyAuth: true,
                              ),
                            );
                            if (authenticated) {
                              setState(() {
                                budgetState.updateLockApp(value);
                              });
                            }
                          }
                        } catch (e) {
                          Logger().warning("User authentication failed: $e", tag: "auth");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text( I18n.translate("authFailed", placeholders: {'error': e.toString()}))),
                          );
                          Navigator.of(context).pop();
                        }
                      },
                      activeColor: Colors.green,
                    )
                  ],
                )
              )
            ),
            if (budgetState.bankAccounts.length > 1)
            Card(
              child: BankAccount(budgetState: budgetState)
            ),
            Card(
              child: Language(budgetState: budgetState)
            ),
            const SizedBox(height: 8,),
            if (getProStatus(budgetState.isPro) || kDebugMode || Platform.isLinux || Platform.isWindows || Platform.isMacOS)
            ElevatedButton(
              style: btnNeutralStyle,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RemoteDatabase(budgetState: budgetState,),
                ),
              ), 
              child: Text(I18n.translate("sharedDB"))
            ),
            if (budgetState.sharedDbUrl == "none")
            const ExportImport(),
            if (!Platform.isIOS && !Platform.isAndroid)
            const SizedBox(height: 8,),
            if (!Platform.isIOS && !Platform.isAndroid)
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
            if (kDebugMode)
            ElevatedButton(onPressed: () => budgetState.updateIsPro(!budgetState.isPro), child: Text("DEBUG: Toggle pro\nCurrent: ${budgetState.isPro}")),
          ]
        )
      ),
      bottomNavigationBar: Row(
        spacing: 8,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(I18n.translate("appVersion", placeholders: {"version": appVersion})),
          GestureDetector(
            onTap: () async {
              const url = privacyNoticeUrl;
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url));
              }
            },
            child: Text(
              I18n.translate("privacyPolicy"),
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          )
        ]
      ),
    );
  }
} 
