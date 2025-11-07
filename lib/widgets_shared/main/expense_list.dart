import 'package:flutter/material.dart';
import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/models/design_state.dart';
import 'package:jne_household_app/models/expense.dart';
import 'package:jne_household_app/screens_mobile/mobile_receipt_scanner.dart';
import 'package:jne_household_app/services/format_date.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/bankaccount.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/widgets_shared/dialogs/expense_dialog.dart';
import 'package:jne_household_app/widgets_shared/dialogs/move_dialog.dart';
import 'package:provider/provider.dart';

class ExpenseList extends StatefulWidget {
  final int categoryId;
  final String category;
  final String currency;
  final BudgetState state;
  final String name;

  const ExpenseList({
    required this.categoryId,
    required this.category,
    required this.currency,
    required this.state,
    super.key, 
    required this.name,
  });

  @override
  _ExpenseListState createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList> {
  late Future<List<Expense>> _expensesFuture;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _loadExpenses() {
    _expensesFuture = DatabaseHelper().getExpenses(widget.categoryId, widget.state.settings.filterBudget, widget.state.budgetRanges[widget.state.range], widget.state.bankAccounts);
  }

  void _refreshExpenses() {
    _loadExpenses();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    String filterBudget = widget.state.settings.filterBudget;
    List<BankAccount> accounts = widget.state.bankAccounts;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () async {
                      bool res = await  showExpenseDialog(
                        context: context, 
                        category: widget.category, 
                        categoryId: widget.categoryId, 
                        accountId: widget.state.settings.filterBudget, 
                        bankAccounts: widget.state.bankAccounts, 
                        bankAccoutCount: widget.state.bankAccounts.length,
                        allowCamera: widget.state.proStatusIsSet(mobileOnly: true),
                        overrideBankAccount: widget.state.categories.where((c) => c.categoryId == widget.categoryId).first.overrideBankAccount,
                      );
                      if (res) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ReceiptPage(baseCurrency: widget.state.settings.currency, budgetState: widget.state, designState: context.read<DesignState>(), overrideCatId: widget.categoryId, closeAfterSuccess: true),
                          ),
                        );
                      } else {
                        _refreshExpenses();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ]
              )
            ],
          ),
        ),
    
        Expanded(
          child: FutureBuilder<List<Expense>>(
            future: _expensesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasData) {
                final expenses = snapshot.data!.reversed.toList();
                final now = DateTime.now();
                final futureExpenses = expenses.where((exp) => exp.date.isAfter(now)).toList();
                final pastExpenses = expenses.where((exp) => exp.date.isBefore(now)).toList();
                final itemCount = (futureExpenses.isNotEmpty ? futureExpenses.length + 1 : 0) +
                    (pastExpenses.isNotEmpty ? pastExpenses.length + (futureExpenses.isNotEmpty ? 1 : 0) : 0);

                if (expenses.isEmpty) {
                  return Center(child: Text(I18n.translate("noExpenses")));
                }

                return ListView.builder(
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (futureExpenses.isNotEmpty && index == 0) {
                      return Text(
                        I18n.translate("planned"),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      );
                    }
                    if (index <= futureExpenses.length && futureExpenses.isNotEmpty) {
                      final expense = futureExpenses[index - 1];
                      return _buildExpenseTile(expense, filterBudget, accounts);
                    }
                    if (index == futureExpenses.length + 1 && pastExpenses.isNotEmpty && futureExpenses.isNotEmpty) {
                      return const Divider();
                    }
                    final expense = pastExpenses[index - (futureExpenses.isNotEmpty ? futureExpenses.length + 2 : 0)];
                    return _buildExpenseTile(expense, filterBudget, accounts);
                  },
                );
              } else {
                return Center(child: Text(I18n.translate("errorExpenses")));
              }
            },
          ),
        )
      ]
    );
  }

  Card _buildExpenseTile(Expense expense, String filterBudget, List<BankAccount> accounts) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(expense.description != "" ? expense.description : I18n.translate("expense")),
        subtitle: Text(
          formatDate(formatForSqlite(expense.date), context) + (expense.autoId == -1 ? "" : " ${I18n.translate("automatic")}")
          + (filterBudget == "*" ? " - ${accounts.where((acc) => acc.id== expense.accountId).first.name}" : "")
          ,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              I18n.translate("expenseAmount", placeholders: {"amount": expense.amount.toStringAsFixed(2), "currency": widget.currency}),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded),
              onPressed: () async {
                await showMoveDialog(context: context, categoryId: widget.categoryId, accountId: expense.accountId,targetId: expense.id!, autoExpense: false);
                _refreshExpenses();
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () async {
                await showExpenseDialog(
                  context: context, 
                  category: widget.category, 
                  categoryId: widget.categoryId, 
                  expense: expense, 
                  accountId: expense.accountId.toString(), 
                  bankAccounts: accounts, 
                  bankAccoutCount: accounts.length,
                  overrideBankAccount: widget.state.categories.where((c) => c.categoryId == widget.categoryId).first.overrideBankAccount,
                );
                _refreshExpenses();
              },
            ),
          ],
        ),
      )
    );
  }
}