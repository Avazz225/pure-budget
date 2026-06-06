import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/autoexpenses.dart';
import 'package:jne_household_app/models/bankaccount.dart';
import 'package:jne_household_app/models/booking_principles.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/widgets_shared/decimal_amount_field.dart';
import 'package:jne_household_app/widgets_shared/dialogs/adaptive_alert_dialog.dart';
import 'package:provider/provider.dart';

void addOrEditMoneyFlowDialog(BuildContext context, int spenderId, {int? expenseId}) {
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    final FocusNode descriptionFocusNode = FocusNode();
    final FocusNode amountFocusNode = FocusNode();

    String principleMode = principleModes[2];
    String bookingPrinciple = availablePrinciples[0];
    int bookingDay = 1;
    int receiverAccountId = (spenderId != -1) ? -1 : 0;

    final budgetState = Provider.of<BudgetState>(context, listen: false);

    AutoExpense? existingExpense;
    if (expenseId != null) {
      existingExpense = budgetState.moneyFlows.firstWhere((expense) => expense.id == expenseId);
      descriptionController.text = existingExpense.description;
      amountController.text = existingExpense.amount.toString();
      bookingPrinciple = existingExpense.bookingPrinciple;
      bookingDay = existingExpense.bookingDay;
      principleMode = existingExpense.principleMode;
      receiverAccountId = existingExpense.receiverAccountId;
    }

    showDialog(
      context: context,
      builder: (context) {

        return StatefulBuilder(
          builder: (context, setState) {
            return AdaptiveAlertDialog(
              title: Text(expenseId == null ? I18n.translate("addMoneyFlow") : I18n.translate("editMoneyFlow")),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: I18n.translate("descriptionMand")),
                      focusNode: descriptionFocusNode,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return I18n.translate("descRequired");
                        }
                        return null;
                      },
                    ),
                    DecimalAmountField(
                      controller: amountController,
                      focusNode: amountFocusNode,
                      labelKey: "budget",
                      textInputAction: TextInputAction.done,
                      setState: setState,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return I18n.translate("numberRequired");
                        }
                        return null;
                      },
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: receiverAccountId,
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          
                          setState(() {
                            receiverAccountId = newValue;
                            bookingPrinciple = availablePrinciples[0];
                          });
                        }
                      },
                      items: budgetState.bankAccounts.map<DropdownMenuItem<int>>((BankAccount acc) {
                        return DropdownMenuItem<int>(
                          value: acc.id,
                          child: Text(acc.name),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        labelText: I18n.translate("filterBankAccount"),
                      ),
                    ),
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: I18n.translate("principle"),
                      ),
                      child: DropdownButton<String>(
                        value: bookingPrinciple,
                        isExpanded: true,
                        underline: const SizedBox(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              bookingPrinciple = newValue;
                            });
                          }
                        },
                        items: (principleMode == "monthly" ? availablePrinciples : availableWeekDays).map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(I18n.translate(value, placeholders: {"day": "x"})),
                          );
                        }).toList(),
                      ),
                    ),
                    if (principleMode == "monthly" && !principleWithoutDay.contains(bookingPrinciple))
                    TextFormField(
                      initialValue: bookingDay.toString(),
                      decoration: InputDecoration(labelText: I18n.translate("bookingDay")),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        bookingDay = int.tryParse(value) ?? 1;
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
                FilledButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    if (principleWithoutDay.contains(bookingPrinciple)){
                      bookingDay = 1;
                    }

                    final newAutoExpense = AutoExpense(
                      categoryId: -1,
                      amount: double.parse(amountController.text.replaceAll(",", ".")),
                      description: descriptionController.text,
                      bookingPrinciple: bookingPrinciple,
                      bookingDay: bookingDay,
                      principleMode: principleMode,
                      receiverAccountId: receiverAccountId,
                      moneyFlow: true,
                      accountId: spenderId,
                      ratePayment: false
                    );

                    Logger().debug(newAutoExpense.toString(), tag: "autoExpense");
                    
                    if (expenseId == null) {
                      await budgetState.addAutoExpense(newAutoExpense);
                    } else {
                      newAutoExpense.id = expenseId;
                      await budgetState.updateOrDeleteAutoExpense(newAutoExpense);
                    }

                    navigator.pop();

                  },
                  child: (amountController.text.isNotEmpty) ? Text((double.parse(amountController.text.replaceAll(",", ".")) == 0.0 && expenseId != null) 
                  ? I18n.translate("delete") 
                  : I18n.translate("save")) 
                  : Text(I18n.translate("save")),
                ),
              ],
            );
          },
        );
      }
    );
  }