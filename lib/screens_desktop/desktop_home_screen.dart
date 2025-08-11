import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/free_restrictions.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/models/design_state.dart';
import 'package:jne_household_app/screens_shared/customization_screen.dart';
import 'package:jne_household_app/screens_shared/help_screen.dart';
import 'package:jne_household_app/widgets_desktop/home/statistics.dart';
import 'package:jne_household_app/widgets_shared/background_painter.dart';
import 'package:jne_household_app/widgets_shared/buttons.dart';
import 'package:jne_household_app/widgets_shared/main/autoexpenses.dart';
import 'package:jne_household_app/widgets_shared/home/budget_summary.dart';
import 'package:jne_household_app/screens_shared/settings.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/widgets_shared/main/add_category.dart';
import 'package:jne_household_app/widgets_shared/main/bank_accounts.dart';
import 'package:jne_household_app/widgets_shared/main/category_list.dart';
import 'package:jne_household_app/widgets_shared/solid_color_painter.dart';
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
    final designState = Provider.of<DesignState>(context);
    final buttonBuilder = (designState.mainMenuStyle == 0) ? glassButton : flatButton;

    Widget buildNavigationButton(BuildContext context,
        {required IconData icon, required String label, required int index}) {
      return buttonBuilder(
        context,
        () {
          setState(() {
            tabindex = index;
          });
        },
        label: label,
        icon: icon,
      );
    }

    Widget buildActionButton(BuildContext context, {
      required String label,
      required VoidCallback onTap,
    }) {
      return buttonBuilder(context, onTap, label: label);
    }


    return Scaffold(
      backgroundColor: (designState.appBackgroundSolid) ? null : Colors.transparent,
      appBar: AppBar(
        backgroundColor: (designState.appBackgroundSolid) ? null : Theme.of(context).cardColor.withValues(alpha: .5),
        title: Text("${I18n.translate('appTitle')} ${budgetState.filterBudget != "*" ? "- ${budgetState.bankAccounts.where((acc) => acc.id.toString() == budgetState.filterBudget).first.name}" : ""}"),
        actions: [
          if(budgetState.sharedDbUrl != "none" && budgetState.sharedDbConnected && !budgetState.syncInProgress)
          buttonBuilder(
            context,
            () {
              budgetState.syncSharedDb(manual: true);
            },
            icon: Icons.cloud_queue_rounded
          ),
          if(budgetState.sharedDbUrl != "none" && !budgetState.sharedDbConnected && !budgetState.syncInProgress)
          buttonBuilder(
            context,
            () {
              budgetState.syncSharedDb(manual: true);
            },
            icon: Icons.cloud_off_rounded,
          ),
          if(budgetState.sharedDbUrl != "none" && budgetState.syncInProgress)
          buttonBuilder(
            context,
            () {},
            icon: Icons.cloud_sync_rounded
          ),
          const SizedBox(width: 16,)
        ],
      ),
      body: Row(
        children: [
          CustomPaint(
            painter: (designState.appBackgroundSolid) ? BackgroundPainter(isDarkMode: Theme.of(context).brightness == Brightness.dark, context: context) : SolidColorPainter(Theme.of(context).cardColor.withValues(alpha: .5)),
            child:
              Padding(
                padding: const EdgeInsetsGeometry.all(4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [ Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 4,
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 4,
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
                        label: I18n.translate("customization"),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CustomizationScreen(),
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
                      const SizedBox(height: 0,),
                    ],
                  ),
                ],
              ),
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
    );
  }
}
