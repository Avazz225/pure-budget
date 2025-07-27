import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';

Widget statisticsLegend(dynamic chartData, String filter, BudgetState state, Function updateFilter) {
  return Wrap(
    runSpacing: -4.0,
    children: chartData.dataRowsLegends.asMap().entries.map<Widget>((entry) {
      final int index = entry.key;
      final String legend = entry.value;
      return TextButton(
        onPressed: () {
          if (state.selectedStatisticIndex >= 2) {
            if (filter == "") {
              updateFilter(legend != I18n.translate("unassigned")? legend : "__undefined_category_name__");
            } else {
              updateFilter("");
            }
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: chartData.dataRowsColors[index],
              ),
            ),
            Text(legend)
          ],
        )
      );
    }).toList(),
  );
}