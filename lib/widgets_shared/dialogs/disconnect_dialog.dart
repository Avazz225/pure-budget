import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/btn_styles.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';

Future<void> disconnectDialog(BuildContext context, BudgetState budgetState) async {
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(I18n.translate("disconnectDialog")),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(I18n.translate("disconnectInfo")),
          const SizedBox(height: 16,),
          ElevatedButton(
            style: btnNeutralStyle,
            onPressed: () async {
              await budgetState.updateSharedDbUrl("none");
              Navigator.of(context).pop();
            }, 
            child: Text(I18n.translate("reallyDisconnect"))
          ),
          const SizedBox(height: 16,),
          ElevatedButton(
            style: btnNegativeStyle,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(I18n.translate("cancel"))
          )
        ]
      ),
    ),
  );
}