import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/btn_styles.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/helper/free_restrictions.dart';
import 'package:jne_household_app/screens_mobile/mobile_in_app_purchase.dart';
import 'package:jne_household_app/widgets_shared/dialogs/category_add_dialog.dart';

class AddCategory extends StatelessWidget {
  final BudgetState budgetState;
  final bool pro;
  const AddCategory({super.key, required this.budgetState, required this.pro});

  @override
  Widget build(BuildContext context) {
    if ( budgetState.rawCategories.length <= maxCategories || pro) {
      return ElevatedButton(
        onPressed: () => addCategory(context),
        style: btnNeutralStyle,
        child: Text(I18n.translate("newCategory")),
      );
    } else {
      return ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.deepOrangeAccent,
          foregroundColor: Colors.white,
          child: Icon(Icons.add_rounded),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const InAppPurchaseScreen(),
          ),
        ),
        title: Text(I18n.translate("moreCat", placeholders: {"count": maxCategories.toString()})),
      );
    }
  }
}