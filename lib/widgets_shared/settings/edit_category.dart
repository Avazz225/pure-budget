import 'package:flutter/material.dart';
import 'package:jne_household_app/services/brightness.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/models/category.dart';
import 'package:jne_household_app/screens_shared/settings.dart';
import 'package:jne_household_app/widgets_shared/dialogs/adaptive_alert_dialog.dart';
import 'package:jne_household_app/widgets_shared/dialogs/color_picker_dialog.dart';
import 'package:provider/provider.dart';

void editCategory(context, Category category, bool assigned, Function setState, String currentAccount) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController nameController = TextEditingController(text: category.name);
        final TextEditingController budgetController = TextEditingController(text: I18n.comma()?category.budget.toString().replaceAll(".", ","):category.budget.toString());
        Color selectedColor = category.color;

        return StatefulBuilder(
          builder: (context, setState) {
            return AdaptiveAlertDialog(
              title: Text(I18n.translate("editCategory")),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    assigned ?
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: I18n.translate("name")),
                    )
                    : 
                    const SizedBox.shrink(),
                    assigned ?
                    TextField(
                      controller: budgetController,
                      decoration: InputDecoration(labelText: "${I18n.translate("budget")} - ${currentAccount.replaceAll("\n", "")}"),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        setState(() {
                          if (I18n.comma()){
                            budgetController.text = value.replaceAll('.', ",");
                          }

                          budgetController.selection = TextSelection.fromPosition(
                            TextPosition(offset: budgetController.text.length),
                          );
                        });
                      },
                    )
                    :
                    const SizedBox.shrink(),
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
                              child: selectedColor == color ? const Icon(Icons.check_rounded, color: Colors.white) : null,
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
                  onPressed: () async {
                    final updatedCategory = Category(
                      id: category.id,
                      name: nameController.text,
                      budget: double.tryParse(budgetController.text.replaceAll(",", ".")) ?? category.budget,
                      color: selectedColor,
                      position: category.position
                    );
                    final partialBudgetState = Provider.of<BudgetState>(context, listen: false);
                    if (updatedCategory.budget != 0.0 || updatedCategory.id == -1){
                      await partialBudgetState.updateRawCategory(updatedCategory);
                    } else {
                      await partialBudgetState.deleteRawCategory(category.id, category.name);
                    }
                    
                    Navigator.of(context).pop(true);
                  },
                  child: Text(category.id != -1 ? (double.tryParse(budgetController.text.replaceAll(",", ".")) == 0.0) ? I18n.translate("delete") : I18n.translate("save") : I18n.translate("save")),
                ),
              ],
            );
          },
        );
      }
    );
  }