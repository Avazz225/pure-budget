import 'package:flutter/material.dart';
import 'package:jne_household_app/services/brightness.dart';
import 'package:jne_household_app/services/text_formatter.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/screens_shared/settings.dart';
import 'package:jne_household_app/widgets_shared/dialogs/adaptive_alert_dialog.dart';
import 'package:jne_household_app/widgets_shared/dialogs/color_picker_dialog.dart';
import 'package:provider/provider.dart';

Future<void> addCategory(context) async {
    String name = '';
    double budget = 0.0;
    Color selectedColor = availableColors.first;
    final FocusNode descriptionFocusNode = FocusNode();
    final FocusNode amountFocusNode = FocusNode();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AdaptiveAlertDialog(
              title: Text(I18n.translate("newCategory")),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: I18n.translate("name")),
                      focusNode: descriptionFocusNode,
                      textInputAction: TextInputAction.next,
                      onChanged: (value) {
                        name = value;
                      },
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: I18n.translate("budget")),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      focusNode: amountFocusNode,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        DecimalTextInputFormatter(decimalRange: 2),
                      ],
                      onChanged: (value) {
                        budget = double.tryParse(value.replaceAll(",", ".")) ?? 0.0;
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(I18n.translate("pickColor")),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 4.0),
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: availableColors.map((color) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedColor = color;
                              });
                            },
                            child: CircleAvatar(
                              backgroundColor: color,
                              child: selectedColor == color ? const Icon(Icons.check, color: Colors.white) : null,
                            ),
                          );
                        }).toList() + [
                          GestureDetector(
                            onTap: () async {
                              Color temp = await openColorPickerDialog(context, selectedColor);
                              setState(() {
                                selectedColor = temp;
                              });
                            },
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: selectedColor,
                              child: Icon(Icons.color_lens_rounded, color: getTextColor(selectedColor, 0, context: context)),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                )
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(I18n.translate("cancel")),
                ),
                TextButton(
                  onPressed: () {
                    if (name.isNotEmpty && budget > 0) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  child: Text(I18n.translate("save")),
                ),
              ],
            );
          },
        );
      }
    );

    if (name.isNotEmpty && budget > 0) {
      final budgetState = Provider.of<BudgetState>(context, listen: false);
      final newCategory = {
        'name': name,
        'budget': budget,
        'color': selectedColor.value.toRadixString(16),
        'raw_color': selectedColor
      };
      await budgetState.insertCategory(newCategory);
    }
  }