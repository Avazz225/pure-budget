
import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/bankaccount.dart';
import 'package:jne_household_app/models/booking_principles.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/widgets_shared/decimal_amount_field.dart';
import 'package:jne_household_app/widgets_shared/dialogs/adaptive_alert_dialog.dart';
import 'package:provider/provider.dart';

void addOrEditAutoExpenseDialog(BuildContext context, List<BankAccount> existingAccounts, {int? accountId}) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController incomeController = TextEditingController();
    final TextEditingController balanceController = TextEditingController();

    final FocusNode nameFocusNode = FocusNode();
    final FocusNode descriptionFocusNode = FocusNode();
    final FocusNode incomeFocusNode = FocusNode();
    final FocusNode balanceFocusNode = FocusNode();
    
    String principleMode = principleModes[2];
    String budgetResetPrinciple = availablePrinciples[0];
    int budgetResetDay = 1;
    bool isCreditCard = false;
    int refillsFrom = -1;
    String refillPrincipleMode = principleModes[2];

    final budgetState = Provider.of<BudgetState>(context, listen: false);
    final formKey = GlobalKey<FormState>();

    BankAccount? existingAccount;
    if (accountId != null) {
      existingAccount = budgetState.bankAccounts.firstWhere((acc) => acc.id == accountId);
      nameController.text = existingAccount.name;
      descriptionController.text = existingAccount.description;
      incomeController.text = existingAccount.income.toString();
      balanceController.text = existingAccount.balance.toString();
      budgetResetPrinciple = existingAccount.budgetResetPrinciple;
      budgetResetDay = existingAccount.budgetResetDay;
      isCreditCard = existingAccount.isCreditCard;
      refillsFrom = existingAccount.refillsFrom;
      refillPrincipleMode = existingAccount.refillPrincipleMode;
    } else {
      balanceController.text = "0";
    }

    showDialog(
      context: context,
      builder: (context) {

      return StatefulBuilder(
        builder: (context, setState) {
          return AdaptiveAlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [ 
                Text(accountId == null ? I18n.translate("addAccount") : I18n.translate("editAccount")),
                if (accountId != null && accountId != -1)
                IconButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AdaptiveAlertDialog(
                        title: Text(I18n.translate("delete")),
                        content: Text(I18n.translate("confirmDeleteAccount")),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text(I18n.translate("cancel")),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: Text(
                              I18n.translate("delete"),
                              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true || !context.mounted) return;

                    if (principleWithoutDay.contains(budgetResetPrinciple)){
                      budgetResetDay = 1;
                    }

                    final newBankAccount = {
                      "name": nameController.text,
                      "description": descriptionController.text,
                      "income": double.tryParse(incomeController.text.replaceAll(",", ".")) ?? 0.0,
                      "balance": double.tryParse(balanceController.text.replaceAll(",", ".")) ?? 0.0,
                      "budgetResetPrinciple": budgetResetPrinciple,
                      "budgetResetDay": budgetResetDay,
                      "lastSavingRun": existingAccount!.lastSavingRun,
                      "isCreditCard": isCreditCard,
                      "refillsFrom": refillsFrom,
                      "refillPrincipleMode": refillPrincipleMode,
                    };
                    final navigator = Navigator.of(context);
                    await budgetState.updateOrDeleteBankAccount(newBankAccount, accountId, true);
                    navigator.pop();
                  },
                  icon: Icon(Icons.delete_rounded, color: Theme.of(context).colorScheme.error, semanticLabel: I18n.translate('delete')),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                children: [
                  if (existingAccounts.isNotEmpty && accountId == null || (accountId != null && existingAccounts.length > 1 && accountId != -1))
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(I18n.translate("isCreditCard"), style: Theme.of(context).textTheme.bodyLarge!),
                      Switch(
                        value: isCreditCard, 
                        onChanged: (value) {
                          setState(() {
                            isCreditCard = value;
                          });
                        },
                        activeThumbColor: Colors.green,
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: I18n.translate("nameMand")),
                    focusNode: nameFocusNode,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return I18n.translate("nameRequired");
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(labelText: I18n.translate("description")),
                    focusNode: descriptionFocusNode,
                    textInputAction: TextInputAction.next,
                  ),
                  if (!isCreditCard)
                  ...[
                    DecimalAmountField(
                      controller: incomeController,
                      focusNode: incomeFocusNode,
                      labelKey: "income",
                      setState: setState,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return I18n.translate("numberRequired");
                        }
                        return null;
                      },
                    ),
                    DecimalAmountField(
                      controller: balanceController,
                      focusNode: balanceFocusNode,
                      labelKey: "balance",
                      textInputAction: TextInputAction.done,
                      setState: setState,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          balanceController.text = "0";
                        }
                        return null;
                      },
                    ),
                  ]
                  else if ((existingAccounts.isNotEmpty && accountId == null) || (accountId != null && existingAccounts.length > 1))
                  ...[
                    DropdownButtonFormField<int>(
                      initialValue: refillsFrom,
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            refillsFrom = newValue;
                          });
                        }
                      },
                      items: existingAccounts.where((acc) => acc.id != accountId).map((BankAccount acc) {
                        return DropdownMenuItem<int>(
                          value: acc.id,
                          child: Text(acc.name),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        labelText: I18n.translate("refillsFrom"),
                      ),
                    ),
                  ],
                  DropdownButtonFormField<String>(
                    initialValue: budgetResetPrinciple,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          budgetResetPrinciple = newValue;
                        });
                      }
                    },
                    items: (principleMode == "monthly" ? availablePrinciples : availableWeekDays).map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(I18n.translate(value, placeholders: {"day": "x"})),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: I18n.translate("principle"),
                    ),
                  ),
                  if ( !principleWithoutDay.contains(budgetResetPrinciple))
                  TextFormField(
                    initialValue: budgetResetDay.toString(),
                    decoration: InputDecoration(labelText: I18n.translate("bookingDay")),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      budgetResetDay = int.tryParse(value) ?? 1;
                    },
                  ),
                ],
              ),
            ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(I18n.translate("cancel")),
              ),
              FilledButton(
                onPressed: () async {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  if (principleWithoutDay.contains(budgetResetPrinciple)){
                    budgetResetDay = 1;
                  }

                  final newBankAccount = {
                    "name": nameController.text,
                    "description": descriptionController.text,
                    "income": double.tryParse(incomeController.text.replaceAll(",", ".")) ?? 0.0,
                    "balance": double.tryParse(balanceController.text.replaceAll(",", ".")) ?? 0.0,
                    "budgetResetPrinciple": budgetResetPrinciple,
                    "budgetResetDay": budgetResetDay,
                    "lastSavingRun": (accountId != null) ? existingAccount!.lastSavingRun : "none",
                    "isCreditCard": isCreditCard,
                    "refillsFrom": refillsFrom,
                    "refillPrincipleMode": refillPrincipleMode,
                  };

                  final navigator = Navigator.of(context);
                  if (accountId == null) {
                    await budgetState.addBankAccount(newBankAccount);
                  } else {
                    await budgetState.updateOrDeleteBankAccount(newBankAccount, accountId, false);
                  }

                  if (context.mounted) navigator.pop();
                },
                child: Text(I18n.translate("save")),
              ),
            ],
          );
        },
      );
    }
  );
}