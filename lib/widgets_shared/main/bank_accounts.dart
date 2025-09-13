import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:jne_household_app/helper/btn_styles.dart';
import 'package:jne_household_app/helper/free_restrictions.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/widgets_shared/dialogs/bank_account_dialog.dart';
import 'package:jne_household_app/widgets_shared/dialogs/money_flow.dart';
import 'package:jne_household_app/widgets_shared/dialogs/money_flow_manual.dart';
import 'package:jne_household_app/widgets_shared/main/money_flows.dart';
import 'package:jne_household_app/widgets_mobile/main/upgrade_to_pro.dart';


// ToDo: Löschbtn verschieben

Widget bankAccounts(context, BudgetState budgetState, Function setState) {
  final comma = I18n.commaAsSeparator;

  String convertValue(double val) {
    String result = val.toStringAsFixed(2);
    return comma ? result.replaceAll(".", ",") : result;
  }

  Color vertical = Theme.of(context).dividerColor;

  var headlineSmall = Theme.of(context).textTheme.headlineSmall!;
  var bodyLarge = Theme.of(context).textTheme.bodyLarge!;
  var allowMoreAcc = budgetState.proStatusIsSet(simplePro: true) || (maxFreeAccounts > budgetState.bankAccounts.length);
  final screenWidth = MediaQuery.of(context).size.width;
  int crossAxisCount = (screenWidth / 450).floor();
  if (crossAxisCount == 0) {
    crossAxisCount = 1;
  }


  return Padding(
    padding: const EdgeInsets.all(8),
    child: Column(
      children: [
        if (allowMoreAcc)
          TextButton(
            onPressed: () => addOrEditAutoExpenseDialog(context),
            style: btnNeutralStyle,
            child: Text(I18n.translate("addAccount")),
          )
        else
          upgradeToProBtn(
            context,
            "addAccountMax",
            {"count": maxFreeAccounts.toString()},
          ),
        const SizedBox(height: 16),
        Expanded(
          child: MasonryGridView.count(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            itemCount: budgetState.bankAccounts.length,
            itemBuilder: (context, index) {
              final bankAccount = budgetState.bankAccounts[index];
              final assigned = bankAccount.name != "__undefined_account_name__";

              return Card(
                elevation: 4,
                child: ListTile(
                  key: ValueKey(bankAccount.id),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  title: Stack(
                    alignment: AlignmentDirectional.topCenter,
                    children: [
                      Text(
                        assigned
                            ? bankAccount.name
                            : I18n.translate("unassignedAccount"),
                        style: headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(onPressed: () => addOrEditAutoExpenseDialog(context, accountId: bankAccount.id), icon: const Icon(Icons.edit_rounded))
                        ],
                      )
                    ],
                  ),
                  subtitle: Column(
                    spacing: 4,
                    children: [
                      if (bankAccount.description != "")
                        Text(bankAccount.description),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text(
                              I18n.translate("accountIncome", placeholders: {
                                "income": convertValue(bankAccount.income + bankAccount.transfers),
                                "currency": budgetState.currency.toString(),
                              }),
                              textAlign: TextAlign.center,
                              style: bodyLarge,
                            ),
                          ),
                          Container(
                            width: 1,
                            color: vertical,
                            alignment: Alignment.center,
                            height: 50,
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              I18n.translate("accountBalance", placeholders: {
                                "balance": convertValue(bankAccount.balance),
                                "currency": budgetState.currency.toString(),
                              }),
                              textAlign: TextAlign.center,
                              style: bodyLarge,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: TextButton(
                              onPressed: () =>
                                  moneyFlowManual(context, bankAccount.id, bankAccount.name),
                              style: btnNeutralStyle,
                              child: Row(
                                children: [
                                  const Icon(Icons.add_rounded),
                                  Text(I18n.translate("moneyTransfer")),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8,),
                          Expanded(
                            flex: 1,
                            child: TextButton(
                              onPressed: () =>
                                  addOrEditMoneyFlowDialog(context, bankAccount.id),
                              style: btnNeutralStyle,
                              child: Row(
                                children: [
                                  const Icon(Icons.account_balance_wallet_rounded),
                                  Text(I18n.translate("addMonthlyTransfer")),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      ExpansionTile(
                        title: Text(I18n.translate("monthlyTransfers")),
                        children: [
                          moneyFlows(budgetState, bankAccount.id, context),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
