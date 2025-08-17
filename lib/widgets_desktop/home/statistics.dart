
// ignore_for_file: library_private_types_in_public_api

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_charts/flutter_charts.dart';
import 'package:jne_household_app/services/debug_screenshot_manager.dart';
import 'package:jne_household_app/services/statistics.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/models/design_state.dart';
import 'package:jne_household_app/widgets_shared/stacked_icons.dart';
import 'package:jne_household_app/widgets_shared/statistics/statistics_graph.dart';
import 'package:jne_household_app/widgets_shared/statistics/statistics_legend.dart';
import 'package:jne_household_app/widgets_shared/statistics/statistics_table.dart';
import 'package:provider/provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final List<String> chartModes = ["month_total", "history_months", "month_by_cat", "history_by_cat"];
  String filter = "";
  bool init = true;
  double width = 0.0;
  bool table = false;

  void updateFilter(String newFilter) {
    setState(() {
      filter = newFilter;
    });
  }

  void updateWidth(double newWidth) {
    setState(() {
      width = newWidth;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<BudgetState>(context);
    state.getStatistics(chartModes[state.selectedStatisticIndex]);
    bool isDarkMode = Theme.brightnessOf(context) == Brightness.dark;

    ChartData chartData = getChartData(context, state, chartModes[state.selectedStatisticIndex], filter);
    Map<String, List<Map<String, dynamic>>> tableData = getTableData(state, chartModes[state.selectedStatisticIndex]);

    if (init) {
      width = MediaQuery.of(context).size.width * 0.8;
      init = false;
    }

    Color selectedItemColor = isDarkMode ? Colors.blue[100]! : Colors.blue[900]!;
    Color unselectedItemColor = isDarkMode ? Colors.purple[50]!: Colors.purple[900]!;

    final designState = Provider.of<DesignState>(context);

    return Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if ((state.selectedStatisticIndex == 2 || state.selectedStatisticIndex == 0) || !table)
              Card(
                child: Column(
                  children: [
                    Text(
                      I18n.translate("legend"),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    statisticsLegend(chartData, filter, state, updateFilter)
                  ],
                ),
              ),
              if (state.selectedStatisticIndex == 1 || state.selectedStatisticIndex == 3)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    spacing: 4,
                    children: [
                      Text(
                        I18n.translate("showTable"),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Switch(
                        value: table,
                        onChanged: (value) {
                          setState(() {
                            table = value;
                          });
                          if (kDebugMode&& !Platform.isAndroid && !Platform.isIOS){
                            if (state.selectedStatisticIndex == 1 && table) {
                              ScreenshotManager().takeScreenshot(name: "statisticsTable");
                            } else if (state.selectedStatisticIndex == 3 && !table) {
                              ScreenshotManager().takeScreenshot(name: "statisticsGraph");
                            }
                          }
                        },
                        activeColor: Colors.green,
                      )
                    ],
                  ),
                ),
              )
            ]
          ),
          ((state.selectedStatisticIndex == 1 || state.selectedStatisticIndex == 3) && table) ?
          statisticsTable(tableData, context)
          :
          statisticsGraph(chartData, width, context, updateWidth),
          BottomNavigationBar(
            backgroundColor: Colors.transparent,
            selectedItemColor: selectedItemColor,
            unselectedItemColor: unselectedItemColor,
            currentIndex: state.selectedStatisticIndex,
            onTap: (index) async {
              await state.getStatistics(chartModes[index]);
              setState(() {
                state.selectedStatisticIndex = index;
                filter = "";
                init = true;
              });
              if (kDebugMode&& !Platform.isAndroid && !Platform.isIOS){
                if (index == 1 && table) {
                  ScreenshotManager().takeScreenshot(name: "statisticsTable");
                } else if (index == 3 && !table) {
                  ScreenshotManager().takeScreenshot(name: "statisticsGraph");
                }
              }
            },
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.calendar_month_rounded),
                label: I18n.translate(chartModes[0]),
                backgroundColor: (designState.appBackgroundSolid) ? null : Theme.of(context).cardColor.withValues(alpha: .5)
              ),
              BottomNavigationBarItem(
                icon: stackedIcons(24, 0.8, Icons.table_chart_rounded, Icons.show_chart_rounded, table, (state.selectedStatisticIndex == 1) ? selectedItemColor : unselectedItemColor),
                label: I18n.translate(chartModes[1]),
                backgroundColor: (designState.appBackgroundSolid) ? null : Theme.of(context).cardColor.withValues(alpha: .5)
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.category_rounded),
                label: I18n.translate(chartModes[2]),
                backgroundColor: (designState.appBackgroundSolid) ? null : Theme.of(context).cardColor.withValues(alpha: .5)
              ),
              BottomNavigationBarItem(
                icon: stackedIcons(24, 0.8, Icons.table_view_rounded, Icons.stacked_line_chart_rounded, table, (state.selectedStatisticIndex == 3) ? selectedItemColor : unselectedItemColor),
                label: I18n.translate(chartModes[3]),
                backgroundColor: (designState.appBackgroundSolid) ? null : Theme.of(context).cardColor.withValues(alpha: .5)
              ),
            ],
          ),
        ]
    );
  }
}