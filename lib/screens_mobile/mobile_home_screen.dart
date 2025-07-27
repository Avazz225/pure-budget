import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/free_restrictions.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/screens_shared/help_screen.dart';
import 'package:jne_household_app/screens_mobile/mobile_in_app_purchase.dart';
import 'package:jne_household_app/widgets_mobile/home/statistics.dart';
import 'package:jne_household_app/widgets_shared/main/autoexpenses.dart';
import 'package:jne_household_app/widgets_mobile/banner_ad.dart';
import 'package:jne_household_app/widgets_mobile/home/budget_summary.dart';
import 'package:jne_household_app/screens_shared/settings.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/widgets_shared/main/add_category.dart';
import 'package:jne_household_app/widgets_shared/main/bank_accounts.dart';
import 'package:jne_household_app/widgets_shared/main/category_list.dart';
import 'package:provider/provider.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}


class HomeScreenState extends State<HomeScreen> {
  HomeScreenState();
  int tabindex = 2;

  @override
  Widget build(BuildContext context) {
    final budgetState = Provider.of<BudgetState>(context);
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              } else if (value == 'help') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const HelpScreen(),
                  ),
                );
              } else if (value == 'inAppPurchase') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const InAppPurchaseScreen(),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'help',
                child: Text(I18n.translate("help")),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Text(I18n.translate("settings")),
              ),
              if (!getProStatus(budgetState.isPro) || kDebugMode)
              PopupMenuItem(
                value: 'inAppPurchase',
                child: Text(I18n.translate("upgradeToPro")),
              ),
            ],
          ),
        ],
      ),
      body: switch (tabindex) {
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
                  I18n.translate("autoexpenses")
                ),
                autoExpenseList(budgetState)
              ]
            ),
        _ => const BudgetSummary(),
      },
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomNavigationBar(
            selectedItemColor: isDarkMode ? Colors.blue[100] : Colors.blue[900],
            unselectedItemColor: isDarkMode ? Colors.purple[50]: Colors.purple[900],
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.wallet_rounded),
                label: I18n.translate("bankaccount"),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.line_axis_rounded),
                label: I18n.translate("statistics"),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_rounded),
                label: I18n.translate("start"),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.category_rounded),
                label: I18n.translate("categories"),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.autorenew_rounded),
                label: I18n.translate("fixedCost"),
              ),
            ],
            currentIndex: tabindex,
            onTap: (index) {
              setState(() {
                tabindex = index;
              });
            },
          ),
          if (!getProStatus(budgetState.isPro))
          const MainBanner()
        ],
      ),
    );
  }
}
