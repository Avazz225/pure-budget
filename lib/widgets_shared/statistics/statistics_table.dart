import 'package:flutter/material.dart';
import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/helper/brightness.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:path/path.dart';

Widget statisticsTable(Map<String, List<Map<String, dynamic>>> tableData, BuildContext context) {
  final List<String> headers = [I18n.translate("month"), I18n.translate("moneyAmount"), I18n.translate("prevMonth"), I18n.translate("prevYear")];
  final List<String> indexes = ["current_date", "current_amount", "prev_month_amount", "prev_year_amount"];

  return Expanded(
    child: Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: (tableData.keys.contains("all")) ?
          table(headers, indexes, tableData['all']!)
          :
          groupedTables(headers, indexes, tableData)
        ),
      ),
    ),
  );
}

Widget groupedTables(List<String> headers, List<String> indexes, Map<String, List<Map<String, dynamic>>> tableData) {
  return Column(
    children: tableData.entries.toList().reversed.map((entry) {
      String category = entry.key;
      List<Map<String, dynamic>> data = entry.value;
      Color color = hexToColor(data[0]["color"]);

      return ExpansionTile(
        title: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8)
          ),
          child: Text(
            (category != "__undefined_category_name__")? category : I18n.translate("unassigned"),
            style: TextStyle(color: getTextColor(color, 0, context)),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: table(headers, indexes, data),
          ),
        ],
      );
    }).toList(),
  );
}

Widget table(List<String> headers, List<String> indexes, List<Map<String, dynamic>> tableData) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columns: headers
          .map((header) => DataColumn(label: Text(header)))
          .toList(),
      rows: tableData.map(
        (row) => DataRow(
          cells: indexes
            .map((index) => DataCell(
              Text(
                style: TextStyle(
                  color: (index == "prev_month_amount" || index == "prev_year_amount") ? (row[index].contains("-") || row[index].contains("(0.00") || row[index].contains("(0,00")) ? Colors.green : Colors.red : null,
                ),
                row[index]))
              )
            .toList(),
        ),
      )
      .toList(),
    )
  );
}