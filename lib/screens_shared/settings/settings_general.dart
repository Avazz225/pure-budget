import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/widgets_shared/dialogs/adaptive_alert_dialog.dart';
import 'package:jne_household_app/widgets_shared/settings/language.dart';
import 'package:provider/provider.dart';

class SettingsGeneralScreen extends StatefulWidget {
  const SettingsGeneralScreen({super.key});

  @override
  State<SettingsGeneralScreen> createState() => _SettingsGeneralScreenState();
}

class _SettingsGeneralScreenState extends State<SettingsGeneralScreen> {
  void _editCurrency(String currency) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController currencyController = TextEditingController(text: currency);

        return AdaptiveAlertDialog(
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
            FilledButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final settingsState = Provider.of<BudgetState>(context, listen: false);
                await settingsState.updateCurrency(currencyController.text);
                navigator.pop();
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
    final currency = budgetState.settings.currency;

    return Scaffold(
      appBar: AppBar(
        title: Text(I18n.translate("settingsCategoryGeneral")),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Column(
          children: [
            Card(
              child: Padding(
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
                      value: budgetState.settings.includePlanned,
                      onChanged: (value) {
                        setState(() {
                          budgetState.updateInclude(value);
                        });
                      },
                      activeThumbColor: Colors.green,
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
                      value: budgetState.settings.showAvailableBudget,
                      onChanged: (value) {
                        setState(() {
                          budgetState.updateAvailableBudget(value);
                        });
                      },
                      activeThumbColor: Colors.green,
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
                      value: budgetState.settings.useBalance,
                      onChanged: (value) {
                        setState(() {
                          budgetState.updateUseBalance(value);
                        });
                      },
                      activeThumbColor: Colors.green,
                    )
                  ],
                )
              )
            ),
            Card(
              child: Language(budgetState: budgetState)
            ),
          ]
        )
      ),
    );
  }
}
