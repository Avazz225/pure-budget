import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/btn_styles.dart';
import 'package:jne_household_app/services/remote/google_drive_connector.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/widgets_shared/dialogs/adaptive_alert_dialog.dart';

class GoogleDriveSelector extends StatefulWidget {
  final BudgetState budgetState;
  final Function handleConnect;
  const GoogleDriveSelector({super.key, required this.budgetState, required this.handleConnect});

  @override
  GoogleDriveSelectorState createState() => GoogleDriveSelectorState();
}


class GoogleDriveSelectorState extends State<GoogleDriveSelector> {

  GoogleDriveConnector? connector;
  String? selectedFolderId;
  String? selectedFolderName;


  Future<void> authenticateGoogleDrive() async {
    try {
      connector = GoogleDriveConnector();
      await connector!.init();

    } catch (e) {
      Logger().error("Authentication failed: $e", tag: "googleDrive");
    }
  }

  Future<void> openDriveFolderSelector() async {
    if (connector == null) {
      await authenticateGoogleDrive();
    }

    try {
      String? currentFolderId = ""; // Root-Ordner starten
      String? currentFolderName = "Root";

      while (true) {
        final folders = await connector!.readDirectory(currentFolderId ?? "");

        if (folders.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(I18n.translate("error_noFolders", placeholders: {"path": currentFolderName!}))),
          );
          return;
        }

        // Dialog anzeigen, um Ordner auszuwählen
        final selected = await showDialog<Map<String, String?>>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AdaptiveAlertDialog(
              title: Text(I18n.translate("remote_select")),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  itemCount: folders.length,
                  itemBuilder: (BuildContext context, int index) {
                    final folder = folders[index];
                    return ListTile(
                      title: Text(folder.name ?? I18n.translate("unnamedFolder")),
                      subtitle: folder.ownedByMe! ? null : Text(I18n.translate("owner", placeholders: {"email": folder.owners!.first.emailAddress.toString()})),
                      onTap: () {
                        // Öffnen des Ordners
                        Navigator.pop(dialogContext, {
                          "id": folder.id,
                          "name": folder.name,
                          "action": "navigate",
                        });
                      },
                      onLongPress: () {
                        // Ordnerauswahl bei Long Press
                        Navigator.pop(dialogContext, {
                          "id": folder.id,
                          "name": folder.name,
                          "action": "select",
                        });
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: () {
                          // Ordnerauswahl durch Button
                          Navigator.pop(dialogContext, {
                            "id": folder.id,
                            "name": folder.name,
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
          setState(() {
            selectedFolderId = selected["id"];
            selectedFolderName = selected["name"] ?? I18n.translate("unnamedFolder");
          });
          return; // Auswahl abgeschlossen
        } else if (selected["action"] == "navigate") {
          currentFolderId = selected["id"];
          currentFolderName = selected["name"];
        }
      }
    } catch (e) {
      Logger().info("Could not browse folder: $e", tag: "googleDrive");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(I18n.translate("error_folderBrowse", placeholders: {"error": e.toString()}))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      children: [
        Text(
          style: Theme.of(context).textTheme.bodyLarge,
          I18n.translate("selectedFolder", placeholders: {"folder": selectedFolderName ?? ""})
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          style: (selectedFolderId != null) ? btnPositiveStyle : btnNeutralStyle,
          onPressed: openDriveFolderSelector,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(I18n.translate("selectDriveFolder")),
              Icon(Icons.folder_open, semanticLabel: I18n.translate("browseDrive"))
            ],
          ),
        ),
        const SizedBox(height: 8,),
        ElevatedButton(
          style: (selectedFolderId != null) ? btnNeutralStyle : btnNegativeStyle,
          onPressed: () {
            if (selectedFolderId != null) {
              widget.handleConnect("gdrive://$selectedFolderId");
            }
          },
          child: Text(I18n.translate("continue"))
        )
      ],
    ),
  );
  }
}
