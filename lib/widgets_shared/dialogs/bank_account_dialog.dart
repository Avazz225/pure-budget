
import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/text_formatter.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/bankaccount.dart';
import 'package:jne_household_app/models/booking_principles.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:provider/provider.dart';

void addOrEditAutoExpenseDialog(BuildContext context, {int? accountId}) {
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

    final budgetState = Provider.of<BudgetState>(context, listen: false);

    BankAccount? existingAccount;
    if (accountId != null) {
      existingAccount = budgetState.bankAccounts.firstWhere((acc) => acc.id == accountId);
      nameController.text = existingAccount.name;
      descriptionController.text = existingAccount.description;
      incomeController.text = existingAccount.income.toString();
      balanceController.text = existingAccount.balance.toString();
      budgetResetPrinciple = existingAccount.budgetResetPrinciple;
      budgetResetDay = existingAccount.budgetResetDay;
    } else {
      balanceController.text = "0";
    }

    showDialog(
      context: context,
      builder: (context) {

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [ 
                Text(accountId == null ? I18n.translate("addAccount") : I18n.translate("editAccount")),
                if (accountId != null)
                IconButton(
                  onPressed: () {
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
                      "lastSavingRun": existingAccount!.lastSavingRun
                    };
                    budgetState.updateOrDeleteBankAccount(newBankAccount, accountId, true);
                    Navigator.of(context).pop();
                  }, 
                  icon: Icon(Icons.delete_rounded, color: Theme.of(context).colorScheme.error, semanticLabel: I18n.translate('delete'),),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                children: [
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
                  TextFormField(
                    controller: incomeController,
                    focusNode: incomeFocusNode,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      DecimalTextInputFormatter(decimalRange: 2),
                    ],
                    decoration: InputDecoration(labelText: I18n.translate("income")),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return I18n.translate("numberRequired");
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        if (I18n.comma()){
                          incomeController.text = value.replaceAll('.', ",");
                        }
                        incomeController.selection = TextSelection.fromPosition(
                          TextPosition(offset: incomeController.text.length),
                        );
                      });
                    },
                  ),
                  TextFormField(
                    controller: balanceController,
                    focusNode: balanceFocusNode,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      DecimalTextInputFormatter(decimalRange: 2),
                    ],
                    decoration: InputDecoration(labelText: I18n.translate("balance")),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        balanceController.text = "0";
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        if (I18n.comma()){
                          balanceController.text = value.replaceAll('.', ",");
                        }
                        balanceController.selection = TextSelection.fromPosition(
                          TextPosition(offset: balanceController.text.length),
                        );
                      });
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: budgetResetPrinciple,
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
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(I18n.translate("cancel")),
              ),
              TextButton(
                onPressed: () {
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
                    "lastSavingRun": (accountId != null) ? existingAccount!.lastSavingRun : "none"
                  };

                  if (accountId == null) {
                    budgetState.addBankAccount(newBankAccount);
                  } else {
                    budgetState.updateOrDeleteBankAccount(newBankAccount, accountId, false);
                  }

                  Navigator.of(context).pop();
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