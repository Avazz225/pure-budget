import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/free_restrictions.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/models/design_state.dart';
import 'package:jne_household_app/screens_mobile/mobile_receipt_scanner.dart';
import 'package:jne_household_app/screens_shared/customization_screen.dart';
import 'package:jne_household_app/screens_shared/help_screen.dart';
import 'package:jne_household_app/screens_mobile/mobile_in_app_purchase.dart';
import 'package:jne_household_app/widgets_mobile/home/statistics.dart';
import 'package:jne_household_app/widgets_shared/home/budget_summary.dart';
import 'package:jne_household_app/widgets_shared/main/autoexpenses.dart';
import 'package:jne_household_app/widgets_mobile/banner_ad.dart';
import 'package:jne_household_app/screens_shared/settings.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/widgets_shared/main/add_category.dart';
import 'package:jne_household_app/widgets_shared/main/bank_accounts.dart';
import 'package:jne_household_app/widgets_shared/main/category_list.dart';
import 'package:jne_household_app/widgets_shared/tri_rhombus_icon.dart';
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
    final designState = Provider.of<DesignState>(context);
    bool isDarkMode = Theme.brightnessOf(context) == Brightness.dark;

    return Scaffold(
      backgroundColor: (designState.appBackgroundSolid) ? null : Colors.transparent,
      appBar: AppBar(
        backgroundColor: (designState.appBackgroundSolid) ? null : Theme.of(context).cardColor.withValues(alpha: .5),
        title: Text("${I18n.translate('appTitle')} ${budgetState.filterBudget != "*" ? "- ${budgetState.bankAccounts.where((acc) => acc.id.toString() == budgetState.filterBudget).first.name}" : ""}"),
        actions: [
          if(budgetState.sharedDbUrl != "none")
          ...[
            if (!budgetState.syncInProgress)
            ...[
              if (budgetState.sharedDbConnected)
              IconButton(
                icon: const Icon(Icons.cloud_queue_rounded),
                onPressed: () => budgetState.syncSharedDb(manual: true),
              )
              else
              IconButton(
                icon: const Icon(Icons.cloud_off_rounded),
                onPressed: () => budgetState.syncSharedDb(manual: true),
              )
            ]
            else
            const Icon(Icons.cloud_sync_rounded),
          ], 
          if (budgetState.isPro || kDebugMode)
          IconButton(
            icon: const Icon(Icons.camera_alt_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ReceiptPage(baseCurrency: budgetState.currency, budgetState: budgetState,),
              ),
            ),
          ),
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
              } else if (value == "customization") {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CustomizationScreen(),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'help',
                child: Text(I18n.translate("help")),
              ),
              if (!getProStatus(budgetState.isPro, budgetState.isDesktopPro) || kDebugMode)
              PopupMenuItem(
                value: 'inAppPurchase',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TriRhombusIcon(
                      gap: -2.5,
                      size: 20, 
                      rotation: 90, 
                      colors: (Theme.brightnessOf(context) == Brightness.dark) ? [Colors.lightGreen, Colors.lightBlue, Colors.yellowAccent] : [Colors.pink, Colors.purple, Colors.deepOrange]
                    ),
                    const SizedBox(width: 4,),
                    Text(I18n.translate("upgradeToPro"))
                  ],
                )
              ),
              if (getProStatus(budgetState.isPro, budgetState.isDesktopPro) || kDebugMode)
              PopupMenuItem(
                value: 'customization',
                child: Text(I18n.translate("customization")),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Text(I18n.translate("settings")),
              )
            ],
          ),
        ],
      ),
      body: switch (tabindex) {
        0 => bankAccounts(context, budgetState, setState),
        1 => const StatisticsScreen(),
        3 => Column(
              children: [
                AddCategory(budgetState: budgetState, pro: getProStatus(budgetState.isPro, budgetState.isDesktopPro)),
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
            backgroundColor: Colors.transparent,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.wallet_rounded),
                label: I18n.translate("bankaccount"),
                backgroundColor: (designState.appBackgroundSolid) ? null : Theme.of(context).cardColor.withValues(alpha: .5)
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.line_axis_rounded),
                label: I18n.translate("statistics"),
                backgroundColor: (designState.appBackgroundSolid) ? null : Theme.of(context).cardColor.withValues(alpha: .5)
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_rounded),
                label: I18n.translate("start"),
                backgroundColor: (designState.appBackgroundSolid) ? null : Theme.of(context).cardColor.withValues(alpha: .5)
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.category_rounded),
                label: I18n.translate("categories"),
                backgroundColor: (designState.appBackgroundSolid) ? null : Theme.of(context).cardColor.withValues(alpha: .5)
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.autorenew_rounded),
                label: I18n.translate("fixedCost"),
                backgroundColor: (designState.appBackgroundSolid) ? null : Theme.of(context).cardColor.withValues(alpha: .5)
              ),
            ],
            currentIndex: tabindex,
            onTap: (index) {
              if (index != tabindex) {
                setState(() {
                  tabindex = index;
                });
              } else if (index == 2 && (budgetState.isPro || kDebugMode)) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ReceiptPage(baseCurrency: budgetState.currency, budgetState: budgetState,),
                  ),
                );
              }
            },
          ),
          if (!getProStatus(budgetState.isPro, budgetState.isDesktopPro))
          const MainBanner()
        ],
      ),
    );
  }
}
