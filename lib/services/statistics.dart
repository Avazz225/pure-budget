import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/services/format_date.dart';
import 'package:flutter_charts/flutter_charts.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';

Map<String, List<Map<String, dynamic>>> getTableData(BudgetState state, String type) {
  if (!["history_months", "history_by_cat"].contains(type)){
    return {"": [{}]};
  }

  String currency = state.currency;
  List<Map<String, dynamic>> data = state.statistics;

  if (type == "history_months") {
    return {"all": prepareTableData(data, currency)};
  } else {
    Map<String, List<Map<String, dynamic>>> result = {};
    Map<String, List<Map<String, dynamic>>> grouped = groupByCategory(data);
    for (String entry in grouped.keys) {
      result[entry] = prepareTableData(grouped[entry]!, currency);
    }
    return result;
  }
}

Map<String, List<Map<String, dynamic>>> groupByCategory(List<Map<String, dynamic>> data) {
  Map<String, List<Map<String, dynamic>>> groupedData = {};

  for (var item in data) {
    String category = item["category"];
    if (!groupedData.containsKey(category)) {
      groupedData[category] = [];
    }
    groupedData[category]!.add(item);
  }

  return groupedData;
}


List<Map<String, dynamic>> prepareTableData(List<Map<String, dynamic>> data, String currency) {
  List<Map<String, dynamic>> results = [];

  for (int i = 0; i < data.length; i++) {
    String currentDate = data[i]["date"];
    double currentAmount = data[i]["amount"];

    double? prevMonthAmount = i > 0 ? data[i - 1]["amount"] : null;
    double? prevMonthChange = (prevMonthAmount != null)
        ? ((currentAmount - prevMonthAmount) / prevMonthAmount) * 100
        : null;

    String prevYearDate = getPrevYearDate(currentDate);
    double? prevYearAmount = data
        .firstWhere(
          (entry) => entry["date"] == prevYearDate,
          orElse: () => data.first,
        )["amount"];
    double? prevYearChange = (prevYearAmount != null)
        ? ((currentAmount - prevYearAmount) / prevYearAmount) * 100
        : null;

    String prevMonth = I18n.translate(
      "tableChange",
      placeholders: {
        "amountAsPercent": prevMonthChange != null
            ? prevMonthChange.toStringAsFixed(2)
            : "0.00",
        "amounAbsolute": (prevMonthAmount != null
            ? (currentAmount - prevMonthAmount).toStringAsFixed(2)
            : "0.00"),
        "currency": currency,
      },
    );

    String prevYr = I18n.translate(
      "tableChange",
      placeholders: {
        "amountAsPercent": prevYearChange != null
            ? prevYearChange.toStringAsFixed(2)
            : "0.00",
        "amounAbsolute": (prevYearAmount != null
            ? (currentAmount - prevYearAmount).toStringAsFixed(2)
            : "0.00"),
        "currency": currency,
      },
    );

    if (I18n.comma()) {
      prevMonth = prevMonth.replaceAll(".", ",");
      prevYr = prevYr.replaceAll(".", ",");
    }

    results.add({
      "current_date": currentDate,
      "current_amount": I18n.translate("tableAbs", placeholders: {"amount": currentAmount.toStringAsFixed(2), "currency": currency}),
      "prev_month_amount": prevMonth,
      "prev_year_amount": prevYr,
      "color": data[i]["color"]
    });
  }

  return results;
}

String getPrevYearDate(String currentDate) {
  List<String> parts = currentDate.split(" ");
  String currentMonth = parts[0];
  int currentYear = int.parse(parts[1]);

  return "$currentMonth ${currentYear - 1}";
}

ChartData getChartData(BuildContext context, BudgetState state, String type, String filter) {
  final bool intramonth = (type != "history_months" && type != "history_by_cat");
  final bool showTotal = (type != "history_by_cat" && type != "month_by_cat");

  ChartOptions chartOptions = ChartOptions(
    yContainerOptions: YContainerOptions(
      yLabelUnits: state.currency
    ),
    iterativeLayoutOptions: const IterativeLayoutOptions(),
    lineChartOptions: const LineChartOptions(
      hotspotInnerRadius: 0,
      hotspotOuterRadius: 0,
    ),
    legendOptions: const LegendOptions(
      isLegendContainerShown: false
    )
  );

  Map<String, Map<String, double>> groupedData = {};
  final Map<String, DateTime> targetRange = state.budgetRanges[state.range];

  for (var expense in state.statistics) {
    if (filter == "") {
      final date = (intramonth) ? expense['date'].split(' ')[0] : expense['date'];
      final category = expense['category'] ?? I18n.translate("total");

      groupedData.putIfAbsent(date, () => {});
      groupedData[date]![category] = (groupedData[date]![category] ?? 0) + expense['amount'];
    } else if (filter != "" && expense['category'] == filter) {
      final date = (intramonth) ? expense['date'].split(' ')[0] : expense['date'];
      final category = expense['category'] ?? I18n.translate("total");

      groupedData.putIfAbsent(date, () => {});
      groupedData[date]![category] = (groupedData[date]![category] ?? 0) + expense['amount'];
    }
  }

  if (intramonth) {
    groupedData = processIntramonth(groupedData, targetRange);
  }

  List<List<double>> dataRows = [];
  final List<String> xUserLabels = groupedData.keys.toList();
  final categories = groupedData.values
      .expand((categories) => categories.keys)
      .toSet()
      .toList();

  for (final category in categories) {
    dataRows.add(xUserLabels
      .map((date) => groupedData[date]?[category] ?? 0.0)
      .toList());
  }

  List<String> dataRowsLegends = categories;
  if (showTotal){
    dataRowsLegends.add(I18n.translate("budgetPerMonth"));
  }

  List<Color> dataRowsColors;
  
  if (!showTotal) {
    dataRowsColors = extractColorsInOrder(state.statistics, dataRowsLegends);
  } else if (dataRowsLegends.length == 2) {
    dataRowsColors = [Colors.blue, Colors.red[300]!];
  } else {
    dataRowsColors = [Colors.red[300]!];
  }

  if (dataRows.isNotEmpty) {
    dataRows = prepareDataRows(dataRows, state.totalBudget, intramonth, showTotal);
  } else {
    dataRows = List.generate(
      dataRowsColors.length,
      (_) => List.filled(xUserLabels.length, state.totalBudget), // Erstellt eine Liste mit Nullen
    );
  }

  int index = dataRowsLegends.indexWhere((item) => item == "__undefined_category_name__");
  if (index != -1) {
    dataRowsLegends[index] = I18n.translate("unassigned");
  }

  if ((type == "history_by_cat" && filter != "") || type == "history_months") {
    dataRowsColors.add((dataRowsColors[0] != Colors.green[600]!) ?Colors.green : Colors.blue);
    dataRowsLegends.add(I18n.translate("floatingMean"));
    dataRows.add(calculateMean(dataRows[0]));
  }

  if (!showTotal && filter != "") {
    dataRowsColors.add(Colors.red[300]!);
    dataRowsLegends.add(I18n.translate("budgetPerMonth"));
    dataRows.add(List.filled(dataRows[0].length, state.getCategoryBudget(filter)));
  }

  return ChartData(
    dataRows: dataRows,
    chartOptions: chartOptions,
    xUserLabels: xUserLabels.map((date) => formatDate(date, context, short: true, year: false)).toList(),
    dataRowsLegends: dataRowsLegends,
    dataRowsColors: dataRowsColors,
  );
}

List<double> calculateMean(List<double> dataRow) {
  List<double> runningMean = [];

  for (int i = 0; i < dataRow.length; i++) {
    int start = (i - 2 >= 0) ? i - 2 : 0;
    List<double> window = dataRow.sublist(start, i + 1);
    double mean = window.reduce((a, b) => a + b) / window.length;
    runningMean.add(mean);
  }

  return runningMean;
}

Map<String, Map<String, double>> processIntramonth(Map<String, Map<String, double>> groupedData, Map<String, DateTime> targetRange) {
  DateTime start = targetRange['start']!;
  DateTime end = targetRange['end']!;

  while (start.isBefore(end)) {
    final dateKey = start.toIso8601String().split('T')[0]; // Format: YYYY-MM-DD
    groupedData.putIfAbsent(dateKey, () => {}); // Add an empty map for missing dates
    start = start.add(const Duration(days: 1));
  }

  return Map.fromEntries(
    groupedData.entries.toList()
    ..sort((a, b) => DateTime.parse(a.key).compareTo(DateTime.parse(b.key))),
  );
}

List<Color> extractColorsInOrder(List<Map<String, dynamic>> data, List<String> order) {
  // Mapping von Kategorie zu Farbe erstellen
  Map<String, Color> categoryColorMap = {
    for (var item in data) if (item['category'] != null) item['category']: hexToColor(item['color'] ?? "#878787")
  };
  // Farben in der gewünschten Reihenfolge extrahieren
  return order.map((category) => categoryColorMap[category] ?? Colors.grey[700]!).toList();
}

List<List<double>> prepareDataRows(List<List<double>> dataRows, double totalBudget, bool addUp, bool showTotal) {
  List<List<double>> cumulativeDataRows = [];

  for (var row in dataRows) {
    List<double> cumulativeRow = [];
    double cumulativeSum = 0;

    for (var value in row) {
      if (addUp) {
        cumulativeSum += value;
      } else {
        cumulativeSum = value;
      }
      cumulativeRow.add(cumulativeSum);
    }

    cumulativeDataRows.add(cumulativeRow);
  }

  if (showTotal){
    cumulativeDataRows.add(List<double>.filled(cumulativeDataRows[0].length, totalBudget));
  }

  return cumulativeDataRows;
}