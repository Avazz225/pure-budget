import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/autoexpenses.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/widgets_shared/dialogs/money_flow.dart';

Widget moneyFlows(BudgetState budgetState, int spenderId, BuildContext context) {
  List<AutoExpense> outgoings = budgetState.moneyFlows.where((mf) => mf.accountId == spenderId).toList();
  String spenderName = budgetState.bankAccounts.firstWhere((cat) => cat.id == spenderId).name;

  if (outgoings.isNotEmpty) {
    double height = 75.0 * outgoings.length;
    if (height > 250.0) {
      height = 250.0;
    }
    return SizedBox(
      height: height,
      child: ListView.builder(
        itemCount: outgoings.length,
        itemBuilder: (context, index) {
          final flow = outgoings[index];
          String amount = flow.amount.toStringAsFixed(2);
          if (I18n.commaAsSeparator) {
            amount = amount.replaceAll(".", ",");
          }
          return ListTile(
            title: Row(
              children: [
                Text((spenderName)),
                const Icon(Icons.arrow_forward_rounded),
                Text((budgetState.bankAccounts.firstWhere((cat) => cat.id == flow.receiverAccountId).name))
              ],
            ),
            subtitle: Text(I18n.translate("expenseAmount", placeholders: {"amount": amount, "currency":budgetState.currency})),
            trailing: IconButton(
              onPressed: () => addOrEditMoneyFlowDialog(context, spenderId, expenseId: flow.id), 
              icon: const Icon(Icons.edit_rounded)
            ),
          );
        }
      )
    );
  } else {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          I18n.translate("noMoneyFlows"),
        )
      ],
    );
  }
}