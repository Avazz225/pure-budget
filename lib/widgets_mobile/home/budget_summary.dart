import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jne_household_app/widgets_shared/home/budget_dropdown.dart';
import 'package:jne_household_app/widgets_shared/home/category_list.dart';
import 'package:jne_household_app/widgets_mobile/home/budget_arc.dart';
import 'package:jne_household_app/models/budget_state.dart';


class BudgetSummary extends StatefulWidget { 
  const BudgetSummary({super.key});

  @override
  State<BudgetSummary> createState() => _BudgetSummaryState();
}

class _BudgetSummaryState extends State<BudgetSummary> {

  @override
  Widget build(BuildContext context) {
    final budgetState = Provider.of<BudgetState>(context);
    final currency = budgetState.currency;
    final List<double> categorySpent = budgetState.categories.map((c) => c.spent).toList();
    final double totalSpent = categorySpent.fold(0.0, (sum, spent) => sum + spent);

    return Column(
      children: [
        BudgetDropdown(
          budgetRanges: budgetState.budgetRanges, 
          updateRangeSelection: budgetState.updateRangeSelection,
          selectedIndex: budgetState.range
        ),
        BudgetArcWidget(
          totalBudget: budgetState.totalBudget,
          totalSpent: totalSpent,
          currency: budgetState.currency,
          categorySpent: categorySpent,
          segmentColors: budgetState.categories.map((c) => c.color).toList(),
        ),
        const SizedBox(height: 4),
        categoryList(currency, budgetState, context)
      ],
    );
  }
}
