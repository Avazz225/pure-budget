import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:jne_household_app/helper/brightness.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/widgets_shared/dialogs/expense_dialog.dart';
import 'package:jne_household_app/widgets_shared/main/expense_list.dart';
import 'package:jne_household_app/i18n/i18n.dart';


Widget categoryList(String currency, BudgetState budgetState, BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  int crossAxisCount = (screenWidth / 350).floor();
  if (crossAxisCount == 0) {
    crossAxisCount = 1;
  }


  void showExpensesBottomSheet(BuildContext context, String category, int categoryId, Color color) {

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final name = (category != "__undefined_category_name__")? category : I18n.translate("unassigned");
        return FractionallySizedBox(
          heightFactor: 0.75,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: .5),
                  blurRadius: 8,
                  offset: const Offset(0, -4),
                ),
              ]
            ),
            child: ExpenseList(categoryId: categoryId, category: category, currency: currency, state: budgetState, name: name)
          ),
        );
      },
    );
  }

  return Expanded(
    child: MasonryGridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      itemCount: budgetState.categories.length,
      itemBuilder: (context, index) {
        final category = budgetState.categories[index];
        final unassigned = (category.category == "__undefined_category_name__");
        final allSpent = (!unassigned)
            ? category.spent > category.budget
            : category.spent > budgetState.notAssignedBudget;
        final Color textColor = ((!unassigned
                ? (category.spent <= category.budget)
                : (category.spent <= budgetState.notAssignedBudget))
            ? getTextColor(
                category.color.withAlpha((allSpent) ? 51 : 255))
            : Colors.red);

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [ 
            Stack(
              children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: (allSpent)? .2 : 1),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: (!unassigned) ? (category.spent / category.budget).clamp(0.0, 1.0) : (category.spent / budgetState.notAssignedBudget).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: (allSpent)? 0 : 0.5),
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(8),
                              right: Radius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    title: Text(
                      (!unassigned)
                          ? category.category
                          : I18n.translate("unassigned"),
                      style: TextStyle(color: textColor),
                    ),
                    subtitle: Text(
                      (budgetState.showAvailableBudget)
                          ? I18n.translate("available", placeholders: {
                              "actual": ((!unassigned)
                                      ? (category.budget - category.spent)
                                      : (budgetState.notAssignedBudget -
                                          category.spent))
                                  .toStringAsFixed(2),
                              "planned": (!unassigned)
                                  ? category.budget.toStringAsFixed(2)
                                  : budgetState.notAssignedBudget
                                      .toStringAsFixed(2),
                              "currency": currency.toString()
                            })
                          : I18n.translate("spent", placeholders: {
                              "actual": category.spent.toStringAsFixed(2),
                              "planned": (!unassigned)
                                  ? category.budget.toStringAsFixed(2)
                                  : budgetState.notAssignedBudget
                                      .toStringAsFixed(2),
                              "currency": currency.toString()
                            }),
                      style: TextStyle(color: textColor),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.add_rounded, color: textColor),
                      onPressed: () {
                        showExpenseDialog(
                            context: context,
                            category: category.category,
                            categoryId: category.categoryId,
                            accountId: budgetState.filterBudget,
                            bankAccounts: budgetState.bankAccounts,
                            bankAccoutCount: budgetState.bankAccounts.length);
                      },
                    ),
                    onTap: () async {
                      showExpensesBottomSheet(
                        context,
                        category.category,
                        category.categoryId,
                        category.color,
                      );
                    },
                  ),
                ],
              ),
            ]
          )
        );
      },
    ),
  );
}