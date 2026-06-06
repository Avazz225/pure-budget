import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:jne_household_app/models/bankaccount.dart';
import 'package:jne_household_app/services/brightness.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/models/category.dart';
import 'package:jne_household_app/screens_shared/settings.dart';
import 'package:jne_household_app/widgets_shared/decimal_amount_field.dart';
import 'package:jne_household_app/widgets_shared/dialogs/adaptive_alert_dialog.dart';
import 'package:jne_household_app/widgets_shared/dialogs/color_picker_dialog.dart';
import 'package:provider/provider.dart';

void editCategory(context, Category category, bool assigned, Function setState, String currentAccount, List<BankAccount> bankAccounts) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category.category.name);
    final budgetController = TextEditingController(
      text: I18n.comma()
          ? category.budget.toString().replaceAll(".", ",")
          : category.budget.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        Color selectedColor = colorFromHex(category.category.color)!;
        int? overrideBankAccount = category.categoryBudgetsPlain.first.overrideBankAccount;

        return StatefulBuilder(
          builder: (context, setState) {
            return AdaptiveAlertDialog(
              title: Text(I18n.translate("editCategory")),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (assigned) ...[
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(labelText: I18n.translate("name")),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return I18n.translate("nameRequired");
                            }
                            return null;
                          },
                        ),
                        DecimalAmountField(
                          controller: budgetController,
                          labelKey: "budget",
                          setState: setState,
                          validator: (value) {
                            final parsed = double.tryParse(
                              (value ?? '').replaceAll(',', '.'),
                            );
                            if (parsed == null || parsed <= 0) {
                              return I18n.translate("numberRequired");
                            }
                            return null;
                          },
                        ),
                      ],
                      if (bankAccounts.length > 1)
                        DropdownButtonFormField<int?>(
                          initialValue: overrideBankAccount,
                          decoration: InputDecoration(
                            labelText: I18n.translate("overrideAccount"),
                          ),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(I18n.translate("defaultAccount")),
                            ),
                            ...bankAccounts.map((account) => DropdownMenuItem<int?>(
                                  value: account.id,
                                  child: Text(account.name),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() => overrideBankAccount = value);
                          },
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: availableColors.map((color) {
                            return GestureDetector(
                              onTap: () => setState(() => selectedColor = color),
                              child: CircleAvatar(
                                backgroundColor: color,
                                child: selectedColor == color
                                    ? const Icon(Icons.check_rounded, color: Colors.white)
                                    : null,
                              ),
                            );
                          }).toList() +
                              [
                                GestureDetector(
                                  onTap: () async {
                                    final temp = await openColorPickerDialog(context, selectedColor);
                                    setState(() => selectedColor = temp);
                                  },
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: selectedColor,
                                    child: Icon(
                                      Icons.color_lens_rounded,
                                      color: getTextColor(selectedColor, 0, context: context),
                                    ),
                                  ),
                                ),
                              ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(I18n.translate("cancel")),
                ),
                if (assigned && category.category.id != -1)
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AdaptiveAlertDialog(
                          title: Text(I18n.translate("delete")),
                          content: Text(I18n.translate("confirmDeleteCategory")),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: Text(I18n.translate("cancel")),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(ctx).colorScheme.error,
                              ),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: Text(I18n.translate("delete")),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true || !context.mounted) return;
                      final navigator = Navigator.of(context);
                      final budgetState = Provider.of<BudgetState>(context, listen: false);
                      final toDelete = category;
                      toDelete.budget = 0;
                      if (budgetState.settings.filterBudget == "*") {
                        toDelete.categoryBudgetsPlain.first.budget = 0;
                      } else {
                        toDelete.categoryBudgetsPlain
                            .firstWhere((cb) => cb.accountId.toString() == budgetState.settings.filterBudget)
                            .budget = 0;
                      }
                      await budgetState.updateRawCategory(toDelete);
                      navigator.pop(true);
                    },
                    child: Text(I18n.translate("delete")),
                  ),
                FilledButton(
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    final navigator = Navigator.of(context);
                    final partialBudgetState = Provider.of<BudgetState>(context, listen: false);

                    final updatedCategory = category;
                    final newBudget = double.tryParse(
                          budgetController.text.replaceAll(",", "."),
                        ) ??
                        category.budget;
                    updatedCategory.budget = newBudget;
                    updatedCategory.category.name = nameController.text.trim();
                    updatedCategory.category.color = colorToHex(selectedColor);
                    updatedCategory.category.position = category.category.position;
                    if (partialBudgetState.settings.filterBudget == "*") {
                      updatedCategory.categoryBudgetsPlain.first.overrideBankAccount = overrideBankAccount;
                      updatedCategory.categoryBudgetsPlain.first.budget = newBudget;
                    } else {
                      updatedCategory.categoryBudgetsPlain
                          .firstWhere((cb) => cb.accountId.toString() == partialBudgetState.settings.filterBudget)
                          .budget = newBudget;
                      updatedCategory.categoryBudgetsPlain
                          .firstWhere((cb) => cb.accountId.toString() == partialBudgetState.settings.filterBudget)
                          .overrideBankAccount = overrideBankAccount;
                    }

                    await partialBudgetState.updateRawCategory(updatedCategory);
                    navigator.pop(true);
                  },
                  child: Text(I18n.translate("save")),
                ),
              ],
            );
          },
        );
      },
    );
  }