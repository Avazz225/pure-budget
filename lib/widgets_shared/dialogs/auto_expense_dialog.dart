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
    final TextEditingController rateAmountController = TextEditingController();
    final TextEditingController firstRateAmountController = TextEditingController();
    final TextEditingController lastRateAmountController = TextEditingController();

    final FocusNode descriptionFocusNode = FocusNode();
    final FocusNode amountFocusNode = FocusNode();
    final FocusNode rateAmountFocusNode = FocusNode();
    final FocusNode firstRateAmountFocusNode = FocusNode();
    final FocusNode lastRateAmountFocusNode = FocusNode();

    String principleMode = principleModes[2];
    String bookingPrinciple = availablePrinciples[0];
    String selectedIndex;
    int bookingDay = 1;
    bool ratePayment = false;
    bool firstRateDifferent = false;
    bool lastRateDifferent = false;

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
      ratePayment = existingExpense.ratePayment;
      if (ratePayment) {
        rateAmountController.text = existingExpense.rateCount.toString();
        if (existingExpense.firstRateAmount != null) {
          firstRateDifferent = true;
          firstRateAmountController.text = existingExpense.firstRateAmount.toString();
        }
        if (existingExpense.lastRateAmount != null) {
          lastRateDifferent = true;
          lastRateAmountController.text = existingExpense.lastRateAmount.toString();
        }
      }
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            I18n.translate("ratePayment"),
                          )
                        ),
                        Switch(
                          activeColor: Colors.green,
                          value: ratePayment, 
                          onChanged: (value) {
                            setState(() {
                              ratePayment = value;
                            });
                          }
                        )
                      ],
                    ),
                    if (ratePayment)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            I18n.translate("firstRateDifferent"),
                          )
                        ),
                        Switch(
                          activeColor: Colors.green,
                          value: firstRateDifferent, 
                          onChanged: (value) {
                            setState(() {
                              firstRateDifferent = value;
                            });
                          }
                        )
                      ],
                    ),
                    if (ratePayment)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            I18n.translate("lastRateDifferent"),
                          )
                        ),
                        Switch(
                          activeColor: Colors.green,
                          value: lastRateDifferent, 
                          onChanged: (value) {
                            setState(() {
                              lastRateDifferent = value;
                            });
                          }
                        )
                      ],
                    ),
                    const Divider(),
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
                    if (ratePayment)
                    TextFormField(
                      controller: rateAmountController,
                      focusNode: rateAmountFocusNode,
                      decoration: InputDecoration(labelText: I18n.translate("rateCount")),
                      textInputAction: (firstRateDifferent || lastRateDifferent) ?  TextInputAction.next : TextInputAction.done,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        DecimalTextInputFormatter(decimalRange: 0),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return I18n.translate("numberRequired");
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: amountController,
                      focusNode: amountFocusNode,
                      decoration: InputDecoration(labelText: I18n.translate((ratePayment) ? "rate" : "budget")),
                      textInputAction: (ratePayment) ?  TextInputAction.next : TextInputAction.done,
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
                    if (ratePayment && firstRateDifferent)
                    TextFormField(
                      controller: firstRateAmountController,
                      focusNode: firstRateAmountFocusNode,
                      decoration: InputDecoration(labelText: I18n.translate("firstRate")),
                      textInputAction: lastRateDifferent ?  TextInputAction.next : TextInputAction.done,
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
                            firstRateAmountController.text = value.replaceAll('.', ",");
                          }
                          firstRateAmountController.selection = TextSelection.fromPosition(
                            TextPosition(offset: firstRateAmountController.text.length),
                          );
                        });
                      },
                    ),
                    if (ratePayment && lastRateDifferent)
                    TextFormField(
                      controller: lastRateAmountController,
                      focusNode: lastRateAmountFocusNode,
                      decoration: InputDecoration(labelText: I18n.translate("lastRate")),
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
                            lastRateAmountController.text = value.replaceAll('.', ",");
                          }
                          lastRateAmountController.selection = TextSelection.fromPosition(
                            TextPosition(offset: lastRateAmountController.text.length),
                          );
                        });
                      },
                    ),
                    const Divider(),
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
                    Map<String, dynamic> newAutoExpense = {
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

                    if (!ratePayment) {
                      if (expenseId == null) {
                        budgetState.addAutoExpense(newAutoExpense, selectedIndex);
                      } else {
                        budgetState.updateOrDeleteAutoExpense(newAutoExpense, expenseId, selectedIndex);
                      }
                    } else {
                      newAutoExpense['rateCount'] = int.parse(rateAmountController.text);
                      newAutoExpense['ratePayment'] = 1;
                      if (firstRateDifferent) {
                        newAutoExpense['firstRateAmount'] = double.parse(firstRateAmountController.text.replaceAll(",", "."));
                      }
                      if (lastRateDifferent) {
                        newAutoExpense['lastRateAmount'] = double.parse(lastRateAmountController.text.replaceAll(",", "."));
                      }

                      if (expenseId == null) {
                        budgetState.addRateAutoExpense(newAutoExpense, selectedIndex);
                      } else {
                        budgetState.updateOrDeleteRateAutoExpense(newAutoExpense, expenseId, selectedIndex);
                      }
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