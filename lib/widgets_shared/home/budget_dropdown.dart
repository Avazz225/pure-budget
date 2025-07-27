import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/format_date.dart';
import 'package:jne_household_app/i18n/i18n.dart';

class BudgetDropdown extends StatelessWidget {
  final List<Map<String, DateTime>> budgetRanges;
  final Function(int) updateRangeSelection;
  final int selectedIndex;

  const BudgetDropdown({
    super.key,
    required this.budgetRanges,
    required this.updateRangeSelection,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      hint: Text(I18n.translate("selectRange")),
      value: selectedIndex,
      items: budgetRanges.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, DateTime> range = entry.value;
        String displayText = (index == 0) 
          ? I18n.translate("currentRange") 
          : "${formatDate(range['start']!.toIso8601String(), context, short: true)} - ${formatDate(range['end']!.toIso8601String(), context, short: true)}";
        return DropdownMenuItem<int>(
          value: index,
          child: Text(displayText),
        );
      }).toList(),
      onChanged: (int? selectedIndex) async {
        if (selectedIndex != null) {
          Future.microtask(() async {
            await updateRangeSelection(selectedIndex);
          });
        }
      },
    );
  }
}