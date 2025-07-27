import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';

class BankAccount extends StatelessWidget {
  final BudgetState budgetState;
  const BankAccount({super.key, required this.budgetState});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              I18n.translate("filterBankAccount"),
              style: Theme.of(context).textTheme.bodyLarge,
            )
          ),
          DropdownButton<String>(
            value: budgetState.filterBudget,
            items: [
              DropdownMenuItem<String>(
                value: "*",
                child: Text(I18n.translate("allAcc")),
              )
            ] + budgetState.bankAccounts.map((entry) {
              int index = entry.id;
              String displayText = entry.name;
              return DropdownMenuItem<String>(
                value: index.toString(),
                child: Text(displayText),
              );
            }).toList(),
            onChanged: (String? filter) async {
              if (filter != null) {
                Future.microtask(() async {
                  await budgetState.updateFilter(filter);
                });
              }
            },
          )
        ],
      )
    );
  }
}