import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/widgets_shared/settings/bank_account.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

class SettingsAccountsScreen extends StatefulWidget {
  const SettingsAccountsScreen({super.key});

  @override
  State<SettingsAccountsScreen> createState() => _SettingsAccountsScreenState();
}

class _SettingsAccountsScreenState extends State<SettingsAccountsScreen> {
  final LocalAuthentication auth = LocalAuthentication();

  @override
  Widget build(BuildContext context) {
    final budgetState = Provider.of<BudgetState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(I18n.translate("settingsCategoryAccounts")),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Column(
          children: [
            if (budgetState.bankAccounts.length > 1)
            Card(
              child: BankAccount(budgetState: budgetState)
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
                      value: budgetState.settings.lockApp,
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
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(I18n.translate("authFailed", placeholders: {'error': e.toString()}))),
                          );
                        }
                      },
                      activeThumbColor: Colors.green,
                    )
                  ],
                )
              )
            ),
          ]
        )
      ),
    );
  }
}
