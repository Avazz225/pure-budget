
import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/models/interval.dart';
import 'package:jne_household_app/services/format_date.dart';
import 'package:jne_household_app/widgets_shared/dialogs/adaptive_alert_dialog.dart';

void selectInterval(BuildContext context, BudgetState budgetState) {
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AdaptiveAlertDialog(
            title: Text(I18n.translate("selectInterval")),
            content: IntervalPicker(
              selectedIndex: budgetState.range,
              budgetRanges: budgetState.budgetRanges,
              onIntervalSelected: (int index) {
                setState(() {
                  budgetState.updateRangeSelection(index);
                });
                Navigator.of(context).pop();
              },
            ),
          );
        },
      );
    },
  );
}

class IntervalPicker extends StatelessWidget {
  final int selectedIndex;
  final List<PBInterval> budgetRanges;
  final Function(int) onIntervalSelected;

  const IntervalPicker({
    super.key,
    required this.selectedIndex,
    required this.budgetRanges,
    required this.onIntervalSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: RadioGroup<int>(
        groupValue: selectedIndex,
        onChanged: (int? value) {
          if (value != null) {
            onIntervalSelected(value);
          }
        },
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: budgetRanges.length,
          itemBuilder: (context, index) {
            final range = budgetRanges[index];
            final displayText = (index == 0)
                ? I18n.translate("currentRange")
                : "${formatDate(range.start.toIso8601String(), context, short: true)} - ${formatDate(range.end.toIso8601String(), context, short: true)}";
            return RadioListTile<int>(
              title: Text(displayText),
              value: index,
            );
          },
        ),
      ),
    );
  }
}