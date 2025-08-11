// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/brightness.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/models/category.dart';
import 'package:jne_household_app/widgets_shared/dialogs/adaptive_alert_dialog.dart';
import 'package:provider/provider.dart';

Future<void> showMoveDialog({
  required BuildContext context,
  required int categoryId,
  required int targetId,
  required bool autoExpense, 
  required accountId,
}) async {
  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final List<Category> categories = context.read<BudgetState>().rawCategories;
          return AdaptiveAlertDialog(
            title: Text(I18n.translate("moveExpense")),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(I18n.translate("cancel")),
              ),
            ],
            content: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              width: MediaQuery.of(context).size.width * 0.8,
              child: ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  Category item = categories[index];
                  bool unassigned = item.name == "__undefined_category_name__";
                  Color textColor = getTextColor(item.color, 0, context);

                  if (categoryId != item.id) {
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: item.color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          ListTile(
                            tileColor: Colors.transparent,
                            title: Text(
                              (!unassigned) ? item.name : I18n.translate("unassigned"),
                              style: TextStyle(color: textColor),
                            ),
                            trailing: IconButton(
                              onPressed: () async {
                                context.read<BudgetState>().moveItem(targetId, item.id, accountId, autoExpense);
                                Navigator.of(context).pop();
                              },
                              icon: Icon(Icons.arrow_forward_rounded, color: textColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ),
          );
        },
      );
    },
  );
}
