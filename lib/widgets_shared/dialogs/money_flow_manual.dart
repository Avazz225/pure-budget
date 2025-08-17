import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/text_formatter.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/bankaccount.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/widgets_shared/dialogs/adaptive_alert_dialog.dart';
import 'package:provider/provider.dart';

void moneyFlowManual(BuildContext context, int spenderId, String spenderName) {
  final TextEditingController amountController = TextEditingController(
    text: (I18n.comma() ? "0,00" : "0.00"),
  );

  Color textColor = Colors.white;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final List<BankAccount> bankAccounts = context
              .read<BudgetState>()
              .bankAccounts
              .where((acc) => acc.id != spenderId)
              .toList();

          return AdaptiveAlertDialog(
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(I18n.translate("cancel")),
              ),
            ],
            title: Text(I18n.translate("moneyTransfer")),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: I18n.translate("moneyAmount"),
                    ),
                    inputFormatters: [
                      DecimalTextInputFormatter(decimalRange: 2),
                    ],
                    onChanged: (value) {
                      String helper = value;
                      if (helper.startsWith(".")) {
                        helper = helper.replaceFirst(".", "-");
                      }
                      if (I18n.comma()) {
                        helper = helper.replaceAll('.', ",");
                      }

                      if (helper != amountController.text) {
                        amountController.value = TextEditingValue(
                          text: helper,
                          selection: TextSelection.collapsed(offset: helper.length),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(I18n.translate("to")),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: bankAccounts.length,
                      itemBuilder: (context, index) {
                        BankAccount target = bankAccounts[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.purple[600],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              ListTile(
                                tileColor: Colors.transparent,
                                title: Text(
                                  target.name,
                                  style: TextStyle(color: textColor),
                                ),
                                trailing: IconButton(
                                  onPressed: () async {
                                    dynamic amount = double.tryParse(amountController.text.replaceAll(",", "."))!;
                                    if (amount != null && amount != 0.0) {
                                      context.read<BudgetState>().moneyFlowOnce(spenderId, spenderName, target.id, target.name, amount);
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  icon: Icon(Icons.arrow_forward_rounded, color: textColor),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
