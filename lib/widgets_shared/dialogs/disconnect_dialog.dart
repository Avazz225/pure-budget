import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/widgets_shared/dialogs/adaptive_alert_dialog.dart';

Future<void> disconnectDialog(BuildContext context, BudgetState budgetState) async {
  await showDialog(
    context: context,
    builder: (context) => AdaptiveAlertDialog(
      title: Text(I18n.translate("disconnectDialog")),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(I18n.translate("disconnectInfo")),
          const SizedBox(height: 16,),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await budgetState.updateSharedDbUrl("none");
              navigator.pop();
            },
            child: Text(I18n.translate("reallyDisconnect"))
          ),
          const SizedBox(height: 16,),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(I18n.translate("cancel"))
          )
        ]
      ),
    ),
  );
}