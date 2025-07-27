import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/format_date.dart';
import 'package:jne_household_app/helper/text_formatter.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/autoexpenses.dart';
import 'package:jne_household_app/models/booking_principles.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/widgets_shared/main/datepicker.dart';
import 'package:provider/provider.dart';

void addOrEditAutoExpenseDialog(BuildContext context, int categoryId, {int? expenseId}) {
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    final FocusNode descriptionFocusNode = FocusNode();
    final FocusNode amountFocusNode = FocusNode();

    String principleMode = principleModes[2];
    String bookingPrinciple = availablePrinciples[0];
    String selectedIndex;
    int bookingDay = 1;

    final budgetState = Provider.of<BudgetState>(context, listen: false);

    AutoExpense? existingExpense;
    if (expenseId != null) {
      existingExpense = budgetState.autoExpenses.firstWhere((expense) => expense.id == expenseId);
      descriptionController.text = existingExpense.description;
      amountController.text = existingExpense.amount.toString();
      bookingPrinciple = existingExpense.bookingPrinciple;
      bookingDay = existingExpense.bookingDay;
      principleMode = existingExpense.principleMode;
      selectedIndex = existingExpense.accountId.toString();
    } else {
      selectedIndex = budgetState.bankAccounts.first.id.toString();
    }

    showDialog(
      context: context,
      builder: (context) {

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(expenseId == null ? I18n.translate("addAutoExpense") : I18n.translate("editExpense")),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: descriptionController,
                      focusNode: descriptionFocusNode,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: I18n.translate("descriptionMand")),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return I18n.translate("descRequired");
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: amountController,
                      focusNode: amountFocusNode,
                      decoration: InputDecoration(labelText: I18n.translate("budget")),
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        DecimalTextInputFormatter(decimalRange: 2),
                      ],
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
                    DropdownButtonFormField<String>(
                      value: principleMode,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          
                          setState(() {
                            principleMode = newValue;
                            bookingPrinciple = newValue == "weekly" ? availableWeekDays[0] : (newValue == "yearly" ? DateTime.now().toIso8601String(): availablePrinciples[0]);
                          });
                        }
                      },
                      items: principleModes.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(I18n.translate(value)),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        labelText: I18n.translate("interval"),
                      ),
                    ),
                    if (principleMode == "weekly" || principleMode == "monthly" )
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
                    if (principleMode == "yearly")
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(formatDate(bookingPrinciple, context)),
                        IconButton(
                          onPressed: () async {
                            bookingPrinciple = (await pickMonthDayWithDatePicker(context, providedDate: DateTime.tryParse(bookingPrinciple))).toString();
                            setState(() {});
                          },
                          icon: const Icon(Icons.calendar_month_rounded)
                        )
                      ],
                    ),
                    if (budgetState.filterBudget == "*" && budgetState.bankAccounts.length > 1)
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: I18n.translate("filterBankAccount"),
                      ),
                      value: selectedIndex,
                      items: budgetState.bankAccounts.map((entry) {
                        int index = entry.id;
                        String displayText = entry.name;
                        return DropdownMenuItem<String>(
                          value: index.toString(),
                          child: Text(displayText),
                        );
                      }).toList(),
                      onChanged: (String? filter) async {
                        setState(() => selectedIndex = filter!);
                      },
                    )
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
                      "categoryId": categoryId,
                      "amount": double.parse(amountController.text.replaceAll(",", ".")),
                      "description": descriptionController.text,
                      "bookingPrinciple": bookingPrinciple,
                      "bookingDay": bookingDay,
                      "principleMode": principleMode,
                      "receiverAccountId": -1,
                      "moneyFlow": 0,
                    };

                    if (budgetState.filterBudget != "*") {
                      selectedIndex = budgetState.filterBudget;
                    }

                    if (expenseId == null) {
                      budgetState.addAutoExpense(newAutoExpense, selectedIndex);
                    } else {
                      budgetState.updateOrDeleteAutoExpense(newAutoExpense, expenseId, selectedIndex);
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