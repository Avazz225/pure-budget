import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/debug_screenshot_manager.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/design_state.dart';
import 'package:jne_household_app/widgets_shared/home/budget_arc.dart';
import 'package:provider/provider.dart';
import 'package:jne_household_app/widgets_shared/home/budget_dropdown.dart';
import 'package:jne_household_app/widgets_shared/home/category_list.dart';
import 'package:jne_household_app/widgets_shared/home/budget_line.dart';
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
    final designState = Provider.of<DesignState>(context);
    final currency = budgetState.currency;
    final List<double> categorySpent = budgetState.categories.map((c) => c.spent).toList();
    final double totalSpent = categorySpent.fold(0.0, (sum, spent) => sum + spent);

    if (kDebugMode && !Platform.isAndroid && !Platform.isIOS) {
      ScreenshotManager().takeScreenshot(name: "main");
    }

    return Column(
      children: [
        BudgetDropdown(
          budgetRanges: budgetState.budgetRanges,
          updateRangeSelection: budgetState.updateRangeSelection,
          selectedIndex: budgetState.range,
          designState: designState,
        ),
        if (designState.arcStyle == 2 || !designState.layoutMainVertical)
        Container(
            decoration: BoxDecoration(
              color: (designState.customBackgroundPath != "none") ? Theme.of(context).cardColor.withValues(alpha: .5) : null,
              borderRadius: const BorderRadius.all(Radius.circular(8))
            ),
            child: Text(
            I18n.translate("totalSpent", placeholders: {"actual": totalSpent.toStringAsFixed(2), "planned": budgetState.totalBudget.toStringAsFixed(2), "currency": currency.toString()}),
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          )
        ),
        if (designState.layoutMainVertical)
        ...[
          if (designState.arcStyle == 0)
          BudgetArcWidget(
            totalBudget: budgetState.totalBudget,
            totalSpent: totalSpent,
            currency: budgetState.currency,
            categorySpent: categorySpent,
            segmentColors: budgetState.categories.map((c) => c.color).toList(),
            showText: designState.layoutMainVertical,
            isVertical: !designState.layoutMainVertical,
          ),
          if (designState.arcStyle == 1)
          BudgetLineWidget(
            totalBudget: budgetState.totalBudget,
            totalSpent: totalSpent,
            currency: budgetState.currency,
            categorySpent: categorySpent,
            segmentColors: budgetState.categories.map((c) => c.color).toList(),
            showText: designState.layoutMainVertical,
            isVertical: !designState.layoutMainVertical,
          ),
          const SizedBox(height: 4, width: 4,),
          categoryList(currency, budgetState, context)
        ],
        if (!designState.layoutMainVertical)
        ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (designState.arcStyle == 0)
              SizedBox(
                height: MediaQuery.of(context).size.height - 140,
                child: BudgetArcWidget(
                  totalBudget: budgetState.totalBudget,
                  totalSpent: totalSpent,
                  currency: budgetState.currency,
                  categorySpent: categorySpent,
                  segmentColors: budgetState.categories.map((c) => c.color).toList(),
                  showText: designState.layoutMainVertical,
                  isVertical: !designState.layoutMainVertical,
                )
              )
              ,
              if (designState.arcStyle == 1)
              SizedBox(
                height: MediaQuery.of(context).size.height - 140,
                child: BudgetLineWidget(
                  totalBudget: budgetState.totalBudget,
                  totalSpent: totalSpent,
                  currency: budgetState.currency,
                  categorySpent: categorySpent,
                  segmentColors: budgetState.categories.map((c) => c.color).toList(),
                  showText: designState.layoutMainVertical,
                  isVertical: !designState.layoutMainVertical,
                )
              ),
              Expanded(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 140,
                  child: categoryList(currency, budgetState, context, isVertical: false)
                )
              ),
              const SizedBox(width: 8,)
            ],
          )
        ],
      ],
    );
  }
}
