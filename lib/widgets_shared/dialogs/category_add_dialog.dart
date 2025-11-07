import 'package:flutter/material.dart';
import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/models/bankaccount.dart';
import 'package:jne_household_app/models/category.dart';
import 'package:jne_household_app/models/category_budget_plain.dart';
import 'package:jne_household_app/models/category_plain.dart';
import 'package:jne_household_app/services/brightness.dart';
import 'package:jne_household_app/services/text_formatter.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/screens_shared/settings.dart';
import 'package:jne_household_app/widgets_shared/dialogs/adaptive_alert_dialog.dart';
import 'package:jne_household_app/widgets_shared/dialogs/color_picker_dialog.dart';
import 'package:provider/provider.dart';

Future<void> addCategory(context, List<BankAccount> bankAccounts) async {
    String name = '';
    double budget = 0.0;
    Color selectedColor = availableColors.first;
    final FocusNode descriptionFocusNode = FocusNode();
    final FocusNode amountFocusNode = FocusNode();
    int? overrideBankAccount;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AdaptiveAlertDialog(
              title: Text(I18n.translate("newCategory")),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: I18n.translate("name")),
                      focusNode: descriptionFocusNode,
                      textInputAction: TextInputAction.next,
                      onChanged: (value) {
                        name = value;
                      },
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: I18n.translate("budget")),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      focusNode: amountFocusNode,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        DecimalTextInputFormatter(decimalRange: 2),
                      ],
                      onChanged: (value) {
                        budget = double.tryParse(value.replaceAll(",", ".")) ?? 0.0;
                      },
                    ),
                    if (bankAccounts.length > 1)
                    ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int?>(
                        value: overrideBankAccount,
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
                    )],
                    const SizedBox(height: 10),
                    Text(I18n.translate("pickColor")),
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
                              child: selectedColor == color ? const Icon(Icons.check, color: Colors.white) : null,
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
                  onPressed: () {
                    if (name.isNotEmpty && budget > 0) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  child: Text(I18n.translate("save")),
                ),
              ],
            );
          },
        );
      }
    );

    if (name.isNotEmpty && budget > 0) {
      final budgetState = Provider.of<BudgetState>(context, listen: false);
      CategoryPlain c = CategoryPlain({
        "name": name,
        "color": colorToHex(selectedColor),
        "position": budgetState.categories.length
      });

      await c.save();

      int filter = budgetState.settings.filterBudget == "*" ? -1 : int.parse(budgetState.settings.filterBudget);

      double de = 0.0;

      List<CategoryBudgetPlain> l = budgetState.bankAccounts.map((ba) => CategoryBudgetPlain({
        'categoryId': c.id,
        'accountId': ba.id,
        'budget': ba.id == filter ? budget : de,
        "overrideBankAccount": overrideBankAccount
      })).toList();

      Category newC = Category(
        budget: budget,
        categoryBudgetsPlain: l,
        category: c
      );
      await budgetState.insertCategory(newC);
    }
  }