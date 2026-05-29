import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:jne_household_app/models/bankaccount.dart';
import 'package:jne_household_app/services/brightness.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/models/category.dart';
import 'package:jne_household_app/screens_shared/settings.dart';
import 'package:jne_household_app/widgets_shared/dialogs/adaptive_alert_dialog.dart';
import 'package:jne_household_app/widgets_shared/dialogs/color_picker_dialog.dart';
import 'package:provider/provider.dart';

void editCategory(context, Category category, bool assigned, Function setState, String currentAccount, List<BankAccount> bankAccounts) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController nameController = TextEditingController(text: category.category.name);
        final TextEditingController budgetController = TextEditingController(text: I18n.comma()?category.budget.toString().replaceAll(".", ","):category.budget.toString());
        Color selectedColor = colorFromHex(category.category.color)!;
        int? overrideBankAccount = category.categoryBudgetsPlain.first.overrideBankAccount;

        return StatefulBuilder(
          builder: (context, setState) {
            return AdaptiveAlertDialog(
              title: Text(I18n.translate("editCategory")),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    assigned ?
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: I18n.translate("name")),
                    )
                    : 
                    const SizedBox.shrink(),
                    assigned ?
                    TextField(
                      controller: budgetController,
                      decoration: InputDecoration(labelText: "${I18n.translate("budget")} - ${currentAccount.replaceAll("\n", "")}"),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        setState(() {
                          if (I18n.comma()){
                            budgetController.text = value.replaceAll('.', ",");
                          }

                          budgetController.selection = TextSelection.fromPosition(
                            TextPosition(offset: budgetController.text.length),
                          );
                        });
                      },
                    )
                    :
                    const SizedBox.shrink(),
                    if (bankAccounts.length > 1)
                    DropdownButtonFormField<int?>(
                      value: overrideBankAccount, // ignore: deprecated_member_use
                      decoration: InputDecoration(
                        labelText: I18n.translate("overrideAccount"),
                      ),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text(I18n.translate("defaultAccount")),
                        ),
                        ...bankAccounts.map((account) {
                          return DropdownMenuItem<int?>(
                            value: account.id,
                            child: Text(account.name),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          overrideBankAccount = value;
                        });
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 4.0),
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: availableColors.map((color) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedColor = color;
                              });
                            },
                            child: CircleAvatar(
                              backgroundColor: color,
                              child: selectedColor == color ? const Icon(Icons.check_rounded, color: Colors.white) : null,
                            ),
                          );
                        }).toList() + [
                          GestureDetector(
                            onTap: () async {
                              Color temp = await openColorPickerDialog(context, selectedColor);
                              setState(() {
                                selectedColor = temp;
                              });
                            },
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: selectedColor,
                              child: Icon(Icons.color_lens_rounded, color: getTextColor(selectedColor, 0, context: context)),
                            ),
                          )
                        ],
                      ),
                    ) 
                  ],
                )
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(I18n.translate("cancel")),
                ),
                TextButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final partialBudgetState = Provider.of<BudgetState>(context, listen: false);

                    final updatedCategory = category;
                    updatedCategory.budget = double.tryParse(budgetController.text.replaceAll(",", ".")) ?? category.budget;

                    updatedCategory.category.name = nameController.text;
                    updatedCategory.category.color = colorToHex(selectedColor);
                    updatedCategory.category.position = category.category.position;
                    if (partialBudgetState.settings.filterBudget == "*") {
                      updatedCategory.categoryBudgetsPlain.first.overrideBankAccount = overrideBankAccount;
                      updatedCategory.categoryBudgetsPlain.first.budget = double.tryParse(budgetController.text.replaceAll(",", ".")) ?? category.budget;
                    } else {
                      updatedCategory.categoryBudgetsPlain.firstWhere((cb) => cb.accountId.toString() == partialBudgetState.settings.filterBudget).budget = double.tryParse(budgetController.text.replaceAll(",", ".")) ?? category.budget;
                      updatedCategory.categoryBudgetsPlain.firstWhere((cb) => cb.accountId.toString() == partialBudgetState.settings.filterBudget).overrideBankAccount = overrideBankAccount;
                    }
                    

                    await partialBudgetState.updateRawCategory(updatedCategory);

                    navigator.pop(true);
                  },
                  child: Text(category.category.id != -1 ? (double.tryParse(budgetController.text.replaceAll(",", ".")) == 0.0) ? I18n.translate("delete") : I18n.translate("save") : I18n.translate("save")),
                ),
              ],
            );
          },
        );
      }
    );
  }