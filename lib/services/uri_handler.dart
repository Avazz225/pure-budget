import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/main.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/models/design_state.dart';
import 'package:jne_household_app/screens_mobile/mobile_receipt_scanner.dart';
import 'package:jne_household_app/widgets_shared/dialogs/expense_dialog.dart';

class UriHandler {
  static const platform = MethodChannel('com.jne_solutions/uri');
  final Logger _logger = Logger();

  void setupListener(BudgetState state, DesignState designState) {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'addExpense') {
        final categoryId = int.parse(call.arguments.toString());
        _logger.debug("Called addExpense with '$categoryId'", tag: "methodChannel");
        _logger.debug("Total ${state.rawCategories.length} categories available", tag: "methodChannel");
        String categoryName = state.rawCategories.where((c) => c.id == categoryId).first.name;
        _logger.debug("Called addExpense for '$categoryName'", tag: "methodChannel");

        bool res = await showExpenseDialog(
          context: navigatorKey.currentContext!, 
          categoryId: categoryId, 
          category: categoryName, 
          accountId: state.filterBudget, 
          bankAccounts: state.bankAccounts, 
          bankAccoutCount: state.bankAccounts.length,
          allowCamera: state.proStatusIsSet(mobileOnly: true)
        );
        if (res) {
          Navigator.of(navigatorKey.currentContext!).push(
            MaterialPageRoute(
              builder: (context) => ReceiptPage(
                baseCurrency: state.currency, 
                budgetState: state, 
                designState: designState, 
                overrideCatId: categoryId, 
                closeAfterSuccess: true
              ),
            ),
          );
        }
      }
    });
  }
}