import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/brightness.dart';
import 'package:jne_household_app/helper/btn_styles.dart';
import 'package:jne_household_app/helper/format_date.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/helper/free_restrictions.dart';
import 'package:jne_household_app/widgets_shared/dialogs/auto_expense_dialog.dart';
import 'package:jne_household_app/widgets_shared/dialogs/move_dialog.dart';
import 'package:provider/provider.dart';

Widget autoExpenseList(dynamic budgetState) {

  List<Widget> buildAutoExpensesForCategory(context, int categoryId) {
    final budgetState = Provider.of<BudgetState>(context);
    var allowNewAutoExpense = (budgetState.autoExpenses.length < maxAutoExpenses) || getProStatus(budgetState.isPro);

    final expenses = budgetState.autoExpenses
      .where((expense) => expense.categoryId == categoryId)
      .toList();

    List<Widget> expenseWidgets = [
      if (allowNewAutoExpense) 
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () {
              if (allowNewAutoExpense){
                addOrEditAutoExpenseDialog(context, categoryId);
              }
            },
            style: btnNeutralStyle,
            child: Text(I18n.translate("addAutoExpense")),
          ),
        ),
    ];

    if (expenses.isEmpty) {
      expenseWidgets.add(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(I18n.translate("noAutoExpenses")),
        )
      );
    } else {
      expenseWidgets.addAll(expenses.map((expense) {
        String expenseAmount = expense.amount.toStringAsFixed(2);
        String principle;

        if (expense.principleMode == "monthly") {
          principle = I18n.translate(expense.bookingPrinciple, placeholders: {'day': expense.bookingDay.toString()});
        } else if (expense.principleMode == "daily") {
          principle = I18n.translate("daily");
        } else if (expense.principleMode == "weekly") {
          principle = "${I18n.translate("weekly")} ${I18n.translate(expense.bookingPrinciple)}";
        } else {
          principle = "${I18n.translate("yearly")} ${formatDate(expense.bookingPrinciple, context, short: true, year: false)}";
        }

        if (I18n.commaAsSeparator){
          expenseAmount = expenseAmount.replaceAll(".", ",");
        }

        if (budgetState.filterBudget == "*" || expense.accountId.toString() == budgetState.filterBudget) {
          return Card( 
            child: ListTile(
              title: Text(expense.description),
              subtitle: Text(
                '${I18n.translate("expenseAmount", placeholders: {"amount": expenseAmount, "currency": budgetState.currency})} - $principle${budgetState.filterBudget == "*" && budgetState.bankAccounts.length > 1 ? "\n${budgetState.bankAccounts.where((exp) => exp.id == expense.accountId).first.name}" : ""}'
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.swap_horiz_rounded),
                    onPressed: () async {
                      await showMoveDialog(context: context, categoryId: categoryId, targetId: expense.id, autoExpense: true, accountId: expense.accountId);
                    }
                  ),
                  IconButton( icon: const Icon(Icons.edit_rounded), onPressed: () =>  addOrEditAutoExpenseDialog(context, categoryId, expenseId: expense.id))
                ],
              )
            )
          );
        } else {
          return const SizedBox.shrink();
        }
      }).toList());
    }

    return expenseWidgets;
  }


  return Expanded(child: 
    ListView.builder(
      itemCount: budgetState.categories.length,
      itemBuilder: (context, index) {
        final category = budgetState.categories[index];
        return 
        Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ExpansionTile(
              title: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: category.color,
                  borderRadius: BorderRadius.circular(8)
                ),
                child: Text(
                  (category.category != "__undefined_category_name__")? category.category : I18n.translate("unassigned"),
                  style: TextStyle(color: getTextColor(category.color)),
                )
              ),
              children: buildAutoExpensesForCategory(context, category.categoryId)
            )
          )
        );
      }
    ),
  );
}