import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/widgets_shared/settings/edit_category.dart';

Widget categoryList(BudgetState budgetState, Function setState) {

  void updateCategoryPositions() {
      final ref = budgetState.rawCategories.length;
      for (int i = 0; i < ref; i++) {
        final newPos = ref - i - 1;
        budgetState.rawCategories[i].category.position = newPos;
      }

      budgetState.saveCategoryOrder();
    }

  String currentAccount = (budgetState.bankAccounts.length == 1) ? "" : ((budgetState.settings.filterBudget == "*") ? "\n(${budgetState.bankAccounts.firstWhere((acc) => acc.id.toString() == "-1").name})" : "\n(${budgetState.bankAccounts.firstWhere((acc) => acc.id.toString() == budgetState.settings.filterBudget).name})");

  return Expanded(
    child: ReorderableListView.builder(
      itemCount: budgetState.rawCategories.length,
      onReorderItem: (fromIndex, toIndex) {
        setState(() {
          final movedCategory = budgetState.rawCategories.removeAt(fromIndex);
          budgetState.rawCategories.insert(toIndex, movedCategory);
        });

        updateCategoryPositions();
      },
      itemBuilder: (context, index) {
        final category = budgetState.rawCategories[index];
        final assigned = category.category.id != -1;

        return Align(
          key: ValueKey(category.category.id),
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              shadowColor: Colors.black.withValues(alpha: 0.4),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                leading: SizedBox(
                  width: 72,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle_rounded),
                      ),
                      const SizedBox(width: 4),
                      CircleAvatar(backgroundColor: colorFromHex(category.category.color)!),
                    ],
                  ),
                ),
                title: Text(
                  (assigned) ? category.category.name : I18n.translate("unassigned"),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "${I18n.translate("budgetWithVars", placeholders: {
                        "amount": assigned
                            ? category.budget.toStringAsFixed(2)
                            : budgetState.notAssignedBudget.toStringAsFixed(2),
                        "currency": budgetState.settings.currency.toString()
                      })}$currentAccount",
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () => editCategory(
                      context, category, assigned, setState, currentAccount, budgetState.bankAccounts),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}