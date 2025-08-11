import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:jne_household_app/helper/brightness.dart';
import 'package:jne_household_app/helper/debug_screenshot_manager.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/models/category_budget.dart';
import 'package:jne_household_app/models/design_state.dart';
import 'package:jne_household_app/widgets_shared/buttons.dart';
import 'package:jne_household_app/widgets_shared/dialogs/expense_dialog.dart';
import 'package:jne_household_app/widgets_shared/main/expense_list.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:provider/provider.dart';


Widget categoryList(String currency, BudgetState budgetState, BuildContext context, {bool isVertical = true}) {
  final screenWidth = MediaQuery.of(context).size.width;
  final designState = Provider.of<DesignState>(context);
  final buttonBuilder = (designState.mainMenuStyle == 0) ? glassButton : flatButton;
  int crossAxisCount = (screenWidth / 350).floor();
  if (crossAxisCount == 0) {
    crossAxisCount = 1;
  }


  void showExpensesBottomSheet(BuildContext context, String category, int categoryId, Color color) {
    if (kDebugMode && !Platform.isAndroid && !Platform.isIOS) {
      ScreenshotManager().takeScreenshot(name: "expenseSheet");
    }
    
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

  Widget gridView() {
    return MasonryGridView.count(
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
                category.color.withAlpha((allSpent) ? 51 : 255), designState.categoryMainStyle, context)
            : Colors.red);

        return listTile(
          budgetState: budgetState,
          designState: designState,
          context: context,
          unassigned: unassigned,
          category: category,
          textColor: textColor,
          currency: currency,
          buttonBuilder: buttonBuilder,
          allSpent: allSpent,
          showExpensesBottomSheet: () => showExpensesBottomSheet(
            context,
            category.category,
            category.categoryId,
            category.color,
          ),
          onPressed: () => showExpenseDialog(
            context: context,
            category: category.category,
            categoryId: category.categoryId,
            accountId: budgetState.filterBudget,
            bankAccounts: budgetState.bankAccounts,
            bankAccoutCount: budgetState.bankAccounts.length
          )
        );
      },
    );
  }

  if (isVertical){
    return Expanded(
      child: gridView()
    );
  } else {
    return gridView();
  }
}

Widget listTile({required context, required bool allSpent, required bool unassigned, required CategoryBudget category, required Color textColor, required BudgetState budgetState, required String currency, required DesignState designState, required Function buttonBuilder, required VoidCallback showExpensesBottomSheet, required VoidCallback onPressed}) {
  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [ 
      Stack(
        children: [
            Positioned(
              height: (designState.categoryMainStyle == 0) ? null : 5,
              left: 0,
              right: 0,
              top: (designState.categoryMainStyle == 0) ? 0 : (designState.categoryMainStyle == 1) ? null : 0,
              bottom: (designState.categoryMainStyle == 0) ? 0 : (designState.categoryMainStyle == 2) ? null : 0,
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
            Positioned(
              height: (designState.categoryMainStyle == 0) ? null : 5,
              left: 0,
              right: 0,
              top: (designState.categoryMainStyle == 0) ? 0 : (designState.categoryMainStyle == 1) ? null : 0,
              bottom: (designState.categoryMainStyle == 0) ? 0 : (designState.categoryMainStyle == 2) ? null : 0,
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
              trailing: (designState.addExpenseStyle == 0) ? IconButton(
                icon: Icon(Icons.add_rounded, color: textColor),
                onPressed: onPressed,
              ) : buttonBuilder(
                context,
                onPressed,
                label: I18n.translate("new")
              ),
              onTap: showExpensesBottomSheet,
            )
          ]
        )
      ]
    )
  );
}