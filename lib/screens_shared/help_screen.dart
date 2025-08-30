import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:jne_household_app/services/debug_screenshot_manager.dart';
import 'package:jne_household_app/keys.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  static const helpIds = [
    "cat_help_general",
    "helpOldRanges",
    "helpBusinessDay",
    "helpScanner",
    "helpScannerLoc",
    "helpExport",
    "helpExportSecurity",
    "helpDataStorage",

    "cat_help_expenses",
    "helpAdd",
    "helpEdit",
    "helpRemove",
    "helpMoveExp",
    "helpRanges",
    "helpShowRemaining",

    "cat_help_cat",
    "helpAddCat",
    "helpEditCat",
    "helpRemCat",
    "helpRemCatExpense",
    "helpCatOrder",

    "cat_help_autoexp",
    "helpAutoExp",
    "helpEditAutoExp",
    "helpRemAutoExp",
    "helpRemAutoExpOldExp",
    "helpMoveAuto",
    "helpAutoModes",
    "helpAutoChange",

    "cat_help_stats",
    "helpStatistics",
    "helpStatToSmall",
    "helpFilter",
    "helpYAxis",

    "cat_help_shared",
    "helpSharedDbGeneral",
    "helpSharedDbInvis",
    "helpSharedDbConnect",
    "helpSharedDbSec",
    "helpSharedDbKey",
    "helpSharedDbDisconnect",
    "helpSharedDbNoConnection",
    "helpSharedDbIndicator",
    "helpSharedDbResync",
    "helpRmDBSync",
    "helpRmDBRotate",
    "helpRmDBRefresh",

    "cat_help_other",
    "helpProUpgrade",

    "helpCryptic",
    "helpDev",

    "helpPrivacy"
  ];

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  Map<String, String> placeholders = {
    "autoexpenses": I18n.translate("autoexpenses"),
    "currentRange": I18n.translate("currentRange"),
    "unassigned": I18n.translate("unassigned"),
    "appName": I18n.translate("appTitle")
  };
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    if (kDebugMode && !Platform.isAndroid && !Platform.isIOS) {
      ScreenshotManager().takeScreenshot(name: "help");
    }

    final filteredIds = searchQuery.length < 3
    ? HelpScreen.helpIds
    : HelpScreen.helpIds.where((id) {
        final title = I18n.translate(id).toLowerCase();
        final answer = I18n.translate("${id}Ans").toLowerCase();
        return title.contains(searchQuery.toLowerCase()) ||
            answer.contains(searchQuery.toLowerCase()) ||
            id.startsWith("cat_help_");
      }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(I18n.translate("help")),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: I18n.translate("search"),
                prefixIcon: const Icon(Icons.search_rounded),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: filteredIds.length,
              itemBuilder: (context, index) {
                final id = filteredIds[index];
                if (!id.startsWith("cat_help_")) {
                  return Card(
                    child: ListTile(
                      title: Text(I18n.translate(id, placeholders: placeholders)),
                      subtitle: id != "helpPrivacy" ? 
                        Text(I18n.translate("${id}Ans", placeholders: placeholders))
                        :
                        Column(
                          children: [
                            Text(I18n.translate("${id}Ans")),
                            GestureDetector(
                              onTap: () async {
                                const url = privacyNoticeUrl;
                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(Uri.parse(url));
                                }
                              },
                              child: Text(
                                I18n.translate("privacyPolicy"),
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            )
                          ],
                        )
                      ,
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      I18n.translate(id, placeholders: placeholders),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [
          Text(I18n.translate("appVersion", placeholders: {"version": appVersion})),
          GestureDetector(
            onTap: () async {
              const url = privacyNoticeUrl;
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url));
              }
            },
            child: Text(
              I18n.translate("privacyPolicy"),
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          )
        ]
      ),
    );
  }
}