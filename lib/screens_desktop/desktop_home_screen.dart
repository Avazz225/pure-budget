import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/free_restrictions.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/screens_shared/help_screen.dart';
//import 'package:jne_household_app/widgets_desktop/banner_ad.dart';
import 'package:jne_household_app/widgets_desktop/home/statistics.dart';
import 'package:jne_household_app/widgets_shared/background_painter.dart';
import 'package:jne_household_app/widgets_shared/main/autoexpenses.dart';
import 'package:jne_household_app/widgets_desktop/home/budget_summary.dart';
import 'package:jne_household_app/screens_shared/settings.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/widgets_shared/main/add_category.dart';
import 'package:jne_household_app/widgets_shared/main/bank_accounts.dart';
import 'package:jne_household_app/widgets_shared/main/category_list.dart';
import 'package:provider/provider.dart';

class DesktopHomeScreen extends StatefulWidget {
  const DesktopHomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<DesktopHomeScreen> {
  int tabindex = 2;

  @override
  Widget build(BuildContext context) {
    final budgetState = Provider.of<BudgetState>(context);

    ButtonStyle btnStyle = ElevatedButton.styleFrom(
      foregroundColor: Theme.of(context).textTheme.bodyLarge!.color
    );

    Widget buildNavigationButton(BuildContext context,
        {required IconData icon, required String label, required int index}) {
      return TextButton.icon(
        onPressed: () {
          setState(() {
            tabindex = index;
          });
        },
        style: btnStyle,
        icon: Icon(icon, size: 24),
        label: Text(label),
      );
    }

    Widget buildActionButton(BuildContext context,
        {required String label, required VoidCallback onTap}) {
      return TextButton(
        onPressed: onTap,
        style: btnStyle,
        child: Text(label),
      );
    }


    return Scaffold(
      appBar: AppBar(
        title: Text("${I18n.translate('appTitle')} ${budgetState.filterBudget != "*" ? "- ${budgetState.bankAccounts.where((acc) => acc.id.toString() == budgetState.filterBudget).first.name}" : ""}"),
        actions: [
          if(budgetState.sharedDbUrl != "none" && budgetState.sharedDbConnected && !budgetState.syncInProgress)
          IconButton(
            icon: const Icon(Icons.cloud_queue_rounded),
            onPressed: () => budgetState.syncSharedDb(manual: true),
          ),
          if(budgetState.sharedDbUrl != "none" && !budgetState.sharedDbConnected && !budgetState.syncInProgress)
          IconButton(
            icon: const Icon(Icons.cloud_off_rounded),
            onPressed: () => budgetState.syncSharedDb(manual: true),
          ),
          if(budgetState.sharedDbUrl != "none" && budgetState.syncInProgress)
          const Icon(Icons.cloud_sync_rounded),
          const SizedBox(width: (kDebugMode) ? 40 : 16,)
        ],
      ),
      body: Row(
        children: [ 
          CustomPaint(
            painter: BackgroundPainter(isDarkMode: Theme.of(context).brightness == Brightness.dark, context: context),
            child:
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [ Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildNavigationButton(
                      context,
                      icon: Icons.home_rounded,
                      label: I18n.translate("start"),
                      index: 2,
                    ),
                    buildNavigationButton(
                      context,
                      icon: Icons.category_rounded,
                      label: I18n.translate("categories"),
                      index: 3,
                    ),
                    buildNavigationButton(
                      context,
                      icon: Icons.autorenew_rounded,
                      label: I18n.translate("fixedCost"),
                      index: 4,
                    ),
                    buildNavigationButton(
                      context,
                      icon: Icons.wallet_rounded,
                      label: I18n.translate("bankaccount"),
                      index: 0,
                    ),
                    buildNavigationButton(
                      context,
                      icon: Icons.line_axis_rounded,
                      label: I18n.translate("statistics"),
                      index: 1,
                    ),
                  ],
                ),
                // Action buttons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildActionButton(
                      context,
                      label: I18n.translate("help"),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const HelpScreen(),
                          ),
                        );
                      },
                    ),
                    buildActionButton(
                      context,
                      label: I18n.translate("settings"),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                    /*if (!budgetState.isPro || kDebugMode)
                    buildActionButton(
                      context,
                      label: I18n.translate("upgradeToPro"),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const InAppPurchaseScreen(),
                          ),
                        );
                      },
                    ),
                    */
                  ],
                ),
              ],
            ),
          ),
          // Main content area
          Expanded(
            child: switch (tabindex) {
              0 => bankAccounts(context, budgetState, setState),
              1 => const StatisticsScreen(),
              3 => Column(
                    children: [
                      AddCategory(budgetState: budgetState, pro: getProStatus(budgetState.isPro)),
                      categoryList(budgetState, setState),
                    ],
                  ),
              4 => Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(
                        style: Theme.of(context).textTheme.headlineSmall,
                        I18n.translate("autoexpenses"),
                      ),
                      autoExpenseList(budgetState),
                    ],
                  ),
              _ => const BudgetSummary(),
            },
          ),
        ],
      ),
      /*bottomNavigationBar: const MainBanner(),*/
    );
  }
}
