// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/btn_styles.dart';
import 'package:jne_household_app/helper/remote/i_cloud_connector.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/budget_state.dart';

Padding iCloudSelector(
    BuildContext context, BudgetState budgetState, Function handleFolderSet) {
  final TextEditingController controller = TextEditingController();
  ICloudConnector? connector;
  String? selectedFolderId;

  Future<void> authenticateICloud() async {
    try {
      connector = ICloudConnector();
      await connector!.init();

    } catch (e) {
      Logger().error("Authentication failed: $e", tag: "iCloud");
    }
  }

  Future<void> openDriveFolderSelector() async {
    if (connector == null) {
      await authenticateICloud();
    }

    try {
      String? currentFolderId = "";
      String? currentFolderName = "Root";

      while (true) {
        final folders = await connector!.readDirectory(currentFolderId ?? "");

        if (folders.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(I18n.translate("error_noFolders", placeholders: {"path": currentFolderName!}))),
          );
          return;
        }

        final selected = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text(I18n.translate("remote_select")),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  itemCount: folders.length,
                  itemBuilder: (BuildContext context, int index) {
                    final folder = folders[index];
                    return ListTile(
                      title: Text(folder['name'] ?? I18n.translate("unnamedFolder")),
                      onTap: () {
                        // Öffnen des Ordners
                        Navigator.pop(dialogContext, {
                          "id": folder['id'],
                          "name": folder['name'],
                          "action": "navigate",
                        });
                      },
                      onLongPress: () {
                        // Ordnerauswahl bei Long Press
                        Navigator.pop(dialogContext, {
                          "id": folder['id'],
                          "name": folder['name'],
                          "action": "select",
                        });
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: () {
                          // Ordnerauswahl durch Button
                          Navigator.pop(dialogContext, {
                            "id": folder['id'],
                            "name": folder['name'],
                            "action": "select",
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, null),
                  child: Text(I18n.translate("cancel")),
                ),
              ],
            );
          },
        );

        // Wenn der Benutzer die Auswahl abbricht, beenden
        if (selected == null) {
          return;
        }

        // Überprüfen, ob die Aktion "navigate" oder "select" ist
        if (selected["action"] == "select") {
          selectedFolderId = selected["id"];
          controller.text = selected["name"] ?? "Unnamed Folder";
          return; // Auswahl abgeschlossen
        } else if (selected["action"] == "navigate") {
          currentFolderId = selected["id"];
          currentFolderName = selected["name"];
        }
      }
    } catch (e) {
      Logger().info("Could not browse folder: $e", tag: "iCloud");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(I18n.translate("error_folderBrowse", placeholders: {"error": e.toString()}))),
      );
    }
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: I18n.translate("selectOrEnterDriveFolder"),
                ),
                onChanged: (text) {
                  controller.text = text;
                },
                onSubmitted: (text) async {
                  await handleFolderSet("icloud://$text");
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => authenticateICloud(),
              icon: Icon(Icons.login, semanticLabel: I18n.translate("authenticate")),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: openDriveFolderSelector,
              icon: Icon(Icons.folder_open, semanticLabel: I18n.translate("browseDrive")),
            ),
          ],
        ),
        const SizedBox(height: 8,),
        ElevatedButton(
          style: btnNeutralStyle,
          onPressed: () => handleFolderSet("icloud://$selectedFolderId"),
          child: Text(I18n.translate("continue"))
        )
      ],
    ),
  );
}