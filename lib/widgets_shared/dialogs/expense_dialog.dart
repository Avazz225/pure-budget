import 'package:flutter/material.dart';
import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/helper/format_date.dart';
import 'package:jne_household_app/helper/text_formatter.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/bankaccount.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:provider/provider.dart';


Future<void> showExpenseDialog({
    required BuildContext context,
    String? category,
    int? categoryId,
    Map<String, dynamic>? expense,
    required String accountId, 
    required List<BankAccount> bankAccounts,
    required int bankAccoutCount
  }) async {
    final bool isEditing = expense != null;
    final TextEditingController amountController = TextEditingController(
      text: isEditing
          ? (I18n.comma()
              ? expense['amount'].toString().replaceAll(".", ",")
              : expense['amount'].toString())
          : '',
    );

    final TextEditingController descriptionController = TextEditingController(
      text: isEditing ? expense['description'].toString() : '',
    );

    final FocusNode descriptionFocusNode = FocusNode();
    final FocusNode amountFocusNode = FocusNode();

    final String filter = context.read<BudgetState>().filterBudget;

    DateTime selectedDate = isEditing
        ? DateTime.parse(expense['date'])
        : DateTime.now();


    String selectedIndex = (accountId != "*") ? accountId : bankAccounts.first.id.toString();

    await showDialog(
      context: context,
      builder: (context) {
        final name = (category != null && category != "__undefined_category_name__")
            ? category
            : I18n.translate("unassigned");

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
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
                    if ((accountId == "*" || (isEditing && filter == "*")) && bankAccoutCount > 1)
                    const SizedBox(height: 10),
                    if ((accountId == "*" || (isEditing && filter == "*")) && bankAccoutCount > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(I18n.translate("filterBankAccount")),
                        DropdownButton<String>(
                          value: selectedIndex,
                          items: bankAccounts.map((entry) {
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
                  ],
                )
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(I18n.translate("cancel")),
                ),
                TextButton(
                  onPressed: () async {
                    final double? amount = double.tryParse(
                      amountController.text.replaceAll(",", "."),
                    );
                    final String description = descriptionController.text;
                    final String formattedDate = formatForSqlite(selectedDate);

                    if (amount == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(I18n.translate("validAmount"))),
                      );
                      return;
                    }

                    if (isEditing) {
                      if (amount == 0) {
                        await context.read<BudgetState>().deleteExpense(
                          expense['id'],
                          formattedDate,
                          int.parse(selectedIndex)
                        );
                      } else {
                        await context.read<BudgetState>().updateExpense(
                          expense['id'],
                          expense['categoryId'],
                          amount,
                          description,
                          formattedDate,
                          int.parse(selectedIndex)
                        );
                      }
                    } else {
                      if (amount != 0 && category != null && categoryId != null) {
                        await context.read<BudgetState>().addExpense(
                          category,
                          categoryId,
                          amount,
                          description,
                          formattedDate,
                          int.parse(selectedIndex)
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(I18n.translate("validAmount"))),
                        );
                        return;
                      }
                    }

                    Navigator.of(context).pop();
                  },
                  child: Text((double.tryParse(amountController.text.replaceAll(",", "."),) != 0) 
                    ? I18n.translate("save") 
                    : I18n.translate("delete")
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }