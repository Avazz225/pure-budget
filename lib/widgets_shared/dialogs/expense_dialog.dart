import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/models/expense.dart';
import 'package:jne_household_app/services/format_date.dart';
import 'package:jne_household_app/services/text_formatter.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/bankaccount.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/widgets_shared/dialogs/adaptive_alert_dialog.dart';
import 'package:provider/provider.dart';


Future<bool> showExpenseDialog({
    required BuildContext context,
    String? category,
    int? categoryId,
    Expense? expense,
    required String accountId, 
    required List<BankAccount> bankAccounts,
    required int bankAccoutCount,
    String? defaultVal,
    bool allowCamera = false,
    int? overrideBankAccount,
  }) async {
    final bool isEditing = expense != null;
    
    if (!isEditing) {
      expense = Expense({
        "accountId": accountId,
        "categoryId": categoryId,
        "description": '',
        "date": formatForSqlite(DateTime.now()),
        "amount": '',
        "auto": 0,
        "autoId": -1
      });
    }

    final TextEditingController amountController = TextEditingController(
      text: isEditing
          ? (I18n.comma()
              ? expense.amount.toString().replaceAll(".", ",")
              : expense.amount.toString())
          : 
          (defaultVal != null) ?
          (I18n.comma()
              ? defaultVal.replaceAll(".", ",")
              : defaultVal.toString())
          : '',
    );

    final TextEditingController descriptionController = TextEditingController(
      text: isEditing ? expense.description.toString() : '',
    );

    final FocusNode descriptionFocusNode = FocusNode();
    final FocusNode amountFocusNode = FocusNode();

    final String filter = context.read<BudgetState>().settings.filterBudget;

    bool openCamera = false;

    DateTime selectedDate = expense.date;

    String selectedIndex = (accountId != "*") ? accountId : bankAccounts.first.id.toString();

    List<BankAccount> filteredAccounts = [];
    if (accountId != "*" || filter != "*") {
      if (bankAccounts.where((acc) => acc.id.toString() == accountId).first.isCreditCard) {
        int mainId = bankAccounts.where((acc) => acc.id.toString() == accountId).first.refillsFrom;
        filteredAccounts = bankAccounts.where((acc) => (acc.isCreditCard) ? (acc.refillsFrom == mainId) : (acc.id == mainId)).toList();
      } else {
        filteredAccounts = bankAccounts.where((acc) => (acc.isCreditCard) ? (acc.refillsFrom.toString() == accountId) : (acc.id.toString() == accountId)).toList();
      }
    } else {
      filteredAccounts = bankAccounts;
    }

    if (!isEditing && (overrideBankAccount != null && bankAccounts.where((acc) => acc.id == overrideBankAccount).isNotEmpty)) {
      selectedIndex = overrideBankAccount.toString();
    }

    await showDialog(
      context: context,
      builder: (context) {
        final name = (category != null && category != "__undefined_category_name__")
            ? category
            : I18n.translate("unassigned");

        return StatefulBuilder(
          builder: (context, setState) {
            return AdaptiveAlertDialog(
              title: Text(
                isEditing
                    ? I18n.translate("editExpense")
                    : I18n.translate("addExpense", placeholders: {"category": name}),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      focusNode: amountFocusNode,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: I18n.translate("moneyAmount")),
                      autofocus: true,
                      inputFormatters: [
                        DecimalTextInputFormatter(decimalRange: 2),
                      ],
                      onChanged: (value) {
                        setState(() {
                          String helper = value;
                          if (helper.startsWith(".")) {
                            helper = helper.replaceFirst(".", "-");
                          }
                          if (I18n.comma()) {
                            helper = helper.replaceAll('.', ",");
                          }

                          amountController.text = helper;

                          amountController.selection = TextSelection.fromPosition(
                            TextPosition(offset: amountController.text.length),
                          );
                        });
                      },
                    ),
                    TextField(
                      controller: descriptionController,
                      focusNode: descriptionFocusNode,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(labelText: I18n.translate("description")),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${I18n.translate("date")}: ${formatDate(selectedDate.toIso8601String(), context)}"),
                        IconButton(
                          icon: const Icon(Icons.calendar_today_rounded),
                          onPressed: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              cancelText: I18n.translate('cancel'),
                              helpText: I18n.translate("selectDate"),
                              confirmText: I18n.translate("ok"),
                              locale: Locale(I18n.getLocaleString())
                            );
                            if (pickedDate != null && pickedDate != selectedDate) {
                              setState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    if (filteredAccounts.length > 1)
                    ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(I18n.translate("filterBankAccount")),
                          DropdownButton<String>(
                            value: selectedIndex,
                            items: bankAccounts.map((entry) {
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
                          )
                        ],
                      ),
                    ]
                  ],
                )
              ),
              actions: [
                if ((allowCamera) && (Platform.isAndroid || Platform.isIOS))
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      openCamera=true;
                    });
                  },
                  icon: const Icon(Icons.camera_alt_rounded)
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(I18n.translate("cancel")),
                ),
                if (isEditing)
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AdaptiveAlertDialog(
                        title: Text(I18n.translate("delete")),
                        content: Text(I18n.translate("confirmDeleteExpense")),
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
                    await context.read<BudgetState>().deleteExpense(expense!);
                    navigator.pop();
                  },
                  child: Text(I18n.translate("delete")),
                ),
                FilledButton(
                  onPressed: () async {
                    final double? amount = double.tryParse(
                      amountController.text.replaceAll(",", "."),
                    );

                    if (amount == null || amount == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(I18n.translate("validAmount"))),
                      );
                      return;
                    }
                    expense!.description = descriptionController.text;
                    expense.date = selectedDate;
                    expense.amount = amount;
                    expense.accountId = int.parse(selectedIndex);

                    final navigator = Navigator.of(context);
                    if (isEditing) {
                      await context.read<BudgetState>().saveExpense(expense);
                    } else {
                      await context.read<BudgetState>().saveExpense(expense);
                    }
                    navigator.pop();
                  },
                  child: Text(I18n.translate("save")),
                ),
              ],
            );
          },
        );
      },
    );
    return openCamera;

  }