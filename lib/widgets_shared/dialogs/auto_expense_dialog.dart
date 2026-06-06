import 'package:flutter/material.dart';
import 'package:jne_household_app/services/format_date.dart';
import 'package:jne_household_app/services/text_formatter.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/autoexpenses.dart';
import 'package:jne_household_app/models/booking_principles.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/widgets_shared/decimal_amount_field.dart';
import 'package:jne_household_app/widgets_shared/dialogs/adaptive_alert_dialog.dart';
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
    final formKey = GlobalKey<FormState>();

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
            return AdaptiveAlertDialog(
              title: Text(expenseId == null ? I18n.translate("addAutoExpense") : I18n.translate("editExpense")),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
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
                          activeThumbColor: Colors.green,
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
                          activeThumbColor: Colors.green,
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
                          activeThumbColor: Colors.green,
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
                    DecimalAmountField(
                      controller: amountController,
                      focusNode: amountFocusNode,
                      labelKey: ratePayment ? "rate" : "budget",
                      textInputAction: ratePayment ? TextInputAction.next : TextInputAction.done,
                      setState: setState,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return I18n.translate("numberRequired");
                        }
                        return null;
                      },
                    ),
                    if (ratePayment && firstRateDifferent)
                    DecimalAmountField(
                      controller: firstRateAmountController,
                      focusNode: firstRateAmountFocusNode,
                      labelKey: "firstRate",
                      textInputAction: lastRateDifferent ? TextInputAction.next : TextInputAction.done,
                      setState: setState,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return I18n.translate("numberRequired");
                        }
                        return null;
                      },
                    ),
                    if (ratePayment && lastRateDifferent)
                    DecimalAmountField(
                      controller: lastRateAmountController,
                      focusNode: lastRateAmountFocusNode,
                      labelKey: "lastRate",
                      textInputAction: TextInputAction.done,
                      setState: setState,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return I18n.translate("numberRequired");
                        }
                        return null;
                      },
                    ),
                    const Divider(),
                    DropdownButtonFormField<String>(
                      initialValue: principleMode,
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
                    if (principleMode == "weekly" || principleMode == "monthly")
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
                    if (budgetState.settings.filterBudget == "*" && budgetState.bankAccounts.length > 1)
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: I18n.translate("filterBankAccount"),
                      ),
                      initialValue: selectedIndex,
                      items: budgetState.bankAccounts.map((entry) {
                        int index = entry.id!;
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
            ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(I18n.translate("cancel")),
                ),
                if (expenseId != null)
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AdaptiveAlertDialog(
                        title: Text(I18n.translate("delete")),
                        content: Text(I18n.translate("confirmDeleteAutoExpense")),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text(I18n.translate("cancel")),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: Text(I18n.translate("delete")),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true || !context.mounted) return;
                    final navigator = Navigator.of(context);
                    final toDelete = AutoExpense(
                      categoryId: categoryId,
                      amount: 0,
                      description: descriptionController.text,
                      bookingPrinciple: bookingPrinciple,
                      bookingDay: bookingDay,
                      principleMode: principleMode,
                      accountId: -1,
                      moneyFlow: false,
                      receiverAccountId: -1,
                      ratePayment: ratePayment,
                    )..id = expenseId;
                    await budgetState.updateOrDeleteAutoExpense(toDelete);
                    navigator.pop();
                  },
                  child: Text(I18n.translate("delete")),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    final navigator = Navigator.of(context);
                    if (principleWithoutDay.contains(bookingPrinciple)){
                      bookingDay = 1;
                    }


                    final newAE = AutoExpense(
                        categoryId: categoryId,
                        amount: double.parse(amountController.text.replaceAll(",", ".")),
                        description: descriptionController.text,
                        bookingPrinciple: bookingPrinciple, 
                        bookingDay: bookingDay,
                        principleMode: principleMode,
                        accountId: (budgetState.settings.filterBudget != "*") ? int.parse(budgetState.settings.filterBudget) : -1,
                        moneyFlow: false,
                        receiverAccountId: -1,
                        ratePayment: ratePayment
                      );
                      
                    if (!ratePayment) {
                      if (expenseId == null) {
                        await budgetState.addAutoExpense(newAE);
                      } else {
                        newAE.id = expenseId;
                        budgetState.updateOrDeleteAutoExpense(newAE);
                      }
                    } else {
                      newAE.rateCount = int.parse(rateAmountController.text);
                      newAE.ratePayment = true;
                      if (firstRateDifferent) {
                        newAE.firstRateAmount = double.parse(firstRateAmountController.text.replaceAll(",", "."));
                      }
                      if (lastRateDifferent) {
                        newAE.lastRateAmount = double.parse(lastRateAmountController.text.replaceAll(",", "."));
                      }

                      if (expenseId == null) {
                        await budgetState.addRateAutoExpense(newAE);
                      } else {
                        newAE.id = expenseId;
                        await budgetState.updateOrDeleteRateAutoExpense(newAE);
                      }
                    }
                    navigator.pop();
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