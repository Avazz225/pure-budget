import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/keys.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/services/report_issue.dart';

Future<List<String>> showReportIssueDialog(BuildContext context, BudgetState state) async {
  final TextEditingController controller = TextEditingController();

  List<String> result = await showDialog(
    context: context,
    builder: (context) {
      bool showMailData = false;
      List<String> data = [];

      return StatefulBuilder(
        builder: (context, setState) {
          if (!showMailData) {
            // normale Eingabeansicht
            return AlertDialog(
              title: Text(I18n.translate("report")),
              content: TextField(
                controller: controller,
                minLines: 3,
                maxLines: 20,
                decoration: InputDecoration(
                  hintText: I18n.translate("reportDesc"),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop([""]),
                  child: Text(I18n.translate("cancel")),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (Platform.isAndroid || Platform.isIOS) {
                      Navigator.of(context).pop(
                          reportIssueMailData(state, controller.text));
                    } else {
                      // Daten vorbereiten und Dialog umbauen
                      setState(() {
                        data = reportIssueMailData(state, controller.text);
                        showMailData = true;
                      });
                    }
                  },
                  child: Text(I18n.translate("reportSend")),
                ),
              ],
            );
          } else {
            return AlertDialog(
              title: Text(I18n.translate("report")),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      I18n.translate("reportHelp"),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    buildCopyBox(context, I18n.translate("recipient"), reportEmail),
                    buildCopyBox(context, I18n.translate("subject"), data[0]),
                    buildCopyBox(context, I18n.translate("body"), data[1]),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop([""]),
                  child: Text(I18n.translate("close")),
                ),
              ],
            );
          }
        },
      );
    },
  );

  return result;
}

Widget buildCopyBox(context, String label, String value) {
  return GestureDetector(
    onTap: () {
      Clipboard.setData(ClipboardData(text: value));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$label ${I18n.translate("copied")}")),
      );
    },
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    ),
  );
}