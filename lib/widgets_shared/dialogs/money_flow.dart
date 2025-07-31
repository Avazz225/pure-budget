import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/text_formatter.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/autoexpenses.dart';
import 'package:jne_household_app/models/bankaccount.dart';
import 'package:jne_household_app/models/booking_principles.dart';
import 'package:jne_household_app/models/budget_state.dart';
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
            return AlertDialog(
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
                    TextFormField(
                      controller: amountController,
                      decoration: InputDecoration(labelText: I18n.translate("budget")),
                      focusNode: amountFocusNode,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        DecimalTextInputFormatter(decimalRange: 2),
                      ],
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
                            amountController.text = value.replaceAll('.', ",");
                          }
                          amountController.selection = TextSelection.fromPosition(
                            TextPosition(offset: amountController.text.length),
                          );
                        });
                      },
                    ),
                    DropdownButtonFormField<int>(
                      value: receiverAccountId,
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
                    DropdownButtonFormField<String>(
                      value: bookingPrinciple,
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
                      decoration: InputDecoration(
                        labelText: I18n.translate("principle"),
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
                TextButton(
                  onPressed: () {
                    if (principleWithoutDay.contains(bookingPrinciple)){
                      bookingDay = 1;
                    }

                    final newAutoExpense = {
                      "categoryId": -1,
                      "amount": double.parse(amountController.text.replaceAll(",", ".")),
                      "description": descriptionController.text,
                      "bookingPrinciple": bookingPrinciple,
                      "bookingDay": bookingDay,
                      "principleMode": principleMode,
                      "receiverAccountId": receiverAccountId,
                      "moneyFlow": 1,
                    };

                    Logger().debug(newAutoExpense.toString(), tag: "autoExpense");
                    
                    if (expenseId == null) {
                      budgetState.addAutoExpense(newAutoExpense, spenderId.toString());
                    } else {
                      budgetState.updateOrDeleteAutoExpense(newAutoExpense, expenseId, spenderId.toString());
                    }

                    Navigator.of(context).pop();

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