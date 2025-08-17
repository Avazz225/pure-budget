// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/btn_styles.dart';
import 'package:jne_household_app/services/remote/smb_server.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/widgets_shared/dialogs/adaptive_alert_dialog.dart';
import 'package:smb_connect/smb_connect.dart';

class smbFolderSelector extends StatefulWidget {
  final BudgetState budgetState;
  final Function handleConnect;
  const smbFolderSelector({super.key, required this.budgetState, required this.handleConnect});

  @override
  smbFolderSelectorState createState() => smbFolderSelectorState();
}


class smbFolderSelectorState extends State<smbFolderSelector> {
  final TextEditingController controller = TextEditingController();
  final TextEditingController hostController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController domainController = TextEditingController();
  final TextEditingController folderController = TextEditingController();
  String? selectedFolder;

  Future<void> authenticateAndSelectFolder() async {
    try {
      final host = hostController.text;
      final username = usernameController.text;
      final password = passwordController.text;
      final domain = domainController.text;
      final initialFolder = folderController.text;

      if (host.isEmpty || username.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(I18n.translate("error_allRequiredFields"))),
        );
        return;
      }

      final smbServer = SMBServer();
      await smbServer.init(host: host, username: username, password: password, domain: domain);

      // Funktion, um Inhalte eines Ordners anzuzeigen
      Future<void> browseFolder(String folderPath) async {
        try {
          List<SmbFile> files = await smbServer.readDirectory(folderPath);

          if (files.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(I18n.translate("error_noFolders", placeholders: {'path': folderPath}))),
            );
            return;
          }

          showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return AdaptiveAlertDialog(
                title: Text(I18n.translate("remote_select")),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: files.length + 1,
                    itemBuilder: (BuildContext context, int index) {
                      if (index == 0) {
                        // "Go up" Pfeil
                        return ListTile(
                          leading: const Icon(Icons.arrow_upward),
                          title: Text(I18n.translate("back")),
                          onTap: () async {
                            Navigator.pop(dialogContext);
                            String parentPath = getParentPath(folderPath);
                            await browseFolder(parentPath);
                          },
                        );
                      }
                      final item = files[index - 1];
                      return ListTile(
                        leading: const Icon(Icons.folder_rounded),
                        title: Text(item.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.task_alt_rounded),
                          onPressed: () {
                            selectedFolder = item.path;
                            controller.text = item.path;
                            Navigator.pop(dialogContext);
                          },
                        ),
                        onTap: () async {
                          Navigator.pop(dialogContext);
                          await browseFolder(item.path);
                        },
                        onLongPress: () {
                          selectedFolder = item.path;
                          controller.text = item.path;
                          Navigator.pop(dialogContext);
                        },
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(I18n.translate("cancel")),
                  ),
                ],
              );
            },
          );
        } catch (e) {
          Logger().info("Could not browse folder: $e", tag: "smbServer");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(I18n.translate("error_folderBrowse", placeholders: {"error": e.toString()}))),
          );
        }
      }

      await browseFolder(initialFolder.isNotEmpty ? initialFolder : "/");
    } catch (e) {
      Logger().error("Connection failed: $e", tag: "smbServer");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(I18n.translate("error_connection", placeholders: {"type": "SMB Server", "error": e.toString()}))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: hostController,
          decoration: InputDecoration(labelText: I18n.translate("smb_host")),
          onChanged: (value) => {
            hostController.text = value
          },
        ),
        const SizedBox(height: 8),
        TextField(
          controller: usernameController,
          decoration: InputDecoration(labelText: I18n.translate("username")),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: passwordController,
          decoration: InputDecoration(labelText: I18n.translate("password")),
          obscureText: true,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: domainController,
          decoration: InputDecoration(labelText: I18n.translate("domain_optional")),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: folderController,
          decoration: InputDecoration(labelText: I18n.translate("folder_optional")),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: I18n.translate("folder_selected"),
                ),
                onChanged: (text) {
                  controller.text = text;
                }
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: authenticateAndSelectFolder,
              icon: Icon(Icons.folder_open, semanticLabel: I18n.translate("browse_server")),
            ),
          ],
        ),
        const SizedBox(height: 8,),
        ElevatedButton(
          style: btnNeutralStyle,
          onPressed: () => widget.handleConnect("smb://$selectedFolder"), 
          child: Text(I18n.translate("continue"))
        )
      ],
    ),
  );
}
}

String getParentPath(String currentPath) {
  if (currentPath == "/" || currentPath.isEmpty) {
    return "/";
  }
  return currentPath.substring(0, currentPath.lastIndexOf("/"));
}