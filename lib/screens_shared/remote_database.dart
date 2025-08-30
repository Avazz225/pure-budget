// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/btn_styles.dart';
import 'package:jne_household_app/services/remote/auth.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/screens_shared/remote_registered_devices.dart';
import 'package:jne_household_app/shared_database/encryption_handler.dart';
import 'package:jne_household_app/shared_database/shared_database.dart';
import 'package:jne_household_app/widgets_shared/dialogs/adaptive_alert_dialog.dart';
import 'package:jne_household_app/widgets_shared/dialogs/connect_shared_db_dialog.dart';
import 'package:jne_household_app/widgets_shared/dialogs/database_sources/google_drive.dart';
import 'package:jne_household_app/widgets_shared/dialogs/database_sources/i_cloud.dart';
import 'package:jne_household_app/widgets_shared/dialogs/database_sources/local_file.dart';
import 'package:jne_household_app/widgets_shared/dialogs/database_sources/one_drive.dart';
import 'package:jne_household_app/widgets_shared/dialogs/database_sources/smb.dart';
import 'package:jne_household_app/widgets_shared/dialogs/disconnect_dialog.dart';
import 'package:jne_household_app/widgets_shared/dialogs/key_sharing_dialog.dart';
import 'package:jne_household_app/widgets_shared/loading_animation.dart';
import 'package:provider/provider.dart';


const List<String> supportedTypes = [
  "rmDBgoogleDrive",
  "rmDBoneDrive",
  "rmDBsmb",
  "rmDBlocal",
  // "rmDBiCloud",
];


class RemoteDatabase extends StatefulWidget {
  final BudgetState budgetState;
  const RemoteDatabase({super.key, required this.budgetState});

  @override
  RemoteDatabaseState createState() => RemoteDatabaseState();
}


class RemoteDatabaseState extends State<RemoteDatabase> {
  RemoteDatabaseState();

  String selected = supportedTypes[0];
  String? selectedFolderId;
  String? selectedFolderName;
  String? frequencyMode;
  TextEditingController controller = TextEditingController();
  bool loading = false;
  List<String> syncFrequencies = [
    "days",
    "hours",
    "minutes",
    "seconds"
  ];
  List<String> syncModes = [
    "instant",
    "frequently",
    "manual"
  ];

  void handleConnect(String selectedPath) async {
    if (selectedPath != "none") {
      await EncryptionHelper.generateKey();
    }
    bool sharedDbExists = await checkRemoteDbExists(selectedPath);
    await connectSharedDbDialog(context, widget.budgetState, selectedPath, sharedDbExists);
  }

  String calcFrequencyMode(int seconds) {
    if (seconds % (60 * 60 * 24) == 0) {
      return "days";
    } else if (seconds % (60 * 60) == 0) {
      return "hours";
    } else if (seconds % (60) == 0) {
      return "minutes";
    } else {
      return "seconds";
    }
  }

  String calcFrequency(int seconds, String mode) {
    if (mode == "days") {
      return (seconds / (60 * 60 * 24)).round().toString();
    } else if (mode == "hours") {
      return (seconds / (60 * 60)).round().toString();
    } else if (mode == "minutes") {
      return (seconds / (60)).round().toString();
    } else {
      return (seconds).toString();
    }
  }

  void updateState(String target, dynamic value) {
    if (target == "loading") {
      setState(() {
        loading = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = Provider.of<BudgetState>(context);
    frequencyMode = calcFrequencyMode(budgetState.syncFrequency);
    controller.text = calcFrequency(budgetState.syncFrequency, frequencyMode!);

    return Scaffold(
      appBar: AppBar(
        title: Text(I18n.translate("sharedDB")),
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Column(
            spacing: 8,
            children: [
              if (budgetState.sharedDbUrl != "none")
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(I18n.translate("syncMode")),
                      DropdownButton<String>(
                        value: budgetState.syncMode,
                        items: syncModes.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry,
                            child: Text(I18n.translate(entry)),
                          );
                        }
                        ).toList(),
                        onChanged: (String? selection) async {
                          await budgetState.updateSyncMode(selection!);
                          setState(() {});
                        },
                      )
                    ],
                  ),
                )
              ),
              if (budgetState.sharedDbUrl != "none" && budgetState.syncMode == "frequently")
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(I18n.translate("syncFrequency")),
                      Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: controller,
                              onChanged: (value) async {
                                await budgetState.updateFrequency(int.parse(value), frequencyMode!);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: frequencyMode,
                            items: syncFrequencies.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry,
                                child: Text(I18n.translate(entry)),
                              );
                            }
                            ).toList(),
                            onChanged: (String? selection) async {
                              await budgetState.updateFrequency(int.parse(controller.text), selection!);
                              setState(() {
                                frequencyMode = selection;
                              });
                            },
                          )
                        ],
                      )
                    ],
                  ),
                )
              ),
              Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children:(budgetState.sharedDbUrl == "none") ?
                  [
                    DropdownButton<String>(
                      value: selected,
                      items: supportedTypes
                        .where((entry) => !((Platform.isAndroid || Platform.isIOS) && entry == "rmDBlocal"))
                        .map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry,
                            child: Text(I18n.translate(entry)),
                          );
                        }).toList(),
                      onChanged: (String? index) async {
                        setState(() {
                          selected = index!;
                        });
                      },
                    ),
                    if (selected == "rmDBlocal")
                    localFile(context, budgetState, handleConnect),
                    if (selected == "rmDBsmb")
                    smbFolderSelector(budgetState: budgetState, handleConnect: handleConnect),
                    if (selected == "rmDBiCloud")
                    iCloudSelector(context, budgetState, handleConnect),
                    if (selected == "rmDBgoogleDrive")
                    GoogleDriveSelector(budgetState: budgetState, handleConnect: handleConnect),
                    if (selected == "rmDBoneDrive")
                    OneDriveSelector(budgetState: budgetState, handleConnect: handleConnect),
                  ]
                  :
                  connected(context, budgetState, loading, updateState),
                ),
              )
            ]
          )
        )
      )
    );
  }
}

List<Widget> connected(BuildContext context, BudgetState budgetState, bool loading, Function updateState) {
  return [
    const SizedBox(height: 8,),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8), 
      child: Text(
        I18n.translate("connectedTo", placeholders: {"path": budgetState.sharedDbUrl}),
        style: Theme.of(context).textTheme.bodyLarge,
      )
    ),
    const SizedBox(height: 16,),
    ElevatedButton(
      style: btnPositiveStyle,
      onPressed: () async {
        updateState("loading", true);
        List<Map<String, dynamic>> regDev = await budgetState.getRegisteredRemoteDevices();
        String uuid = await loadKey("pureBudgetDeviceId");
        updateState("loading", false);
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => RemoteRegisteredDevices(budgetState: budgetState, registeredDevices: regDev, uuid: uuid),
        ),);
      }, 
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.list_alt_rounded),
          const SizedBox(width: 12,),
          loading ? loadingAnimation(Colors.white): Text(I18n.translate("registeredDevices"))
        ]
      )
    ),
    const SizedBox(height: 16,),
    ElevatedButton(
      style: btnNeutralStyle,
      onPressed: () async {
        String encryptionKey = await EncryptionHelper.loadKey();
        showDialog(
          context: context,
          builder: (context) => KeySharingDialog(encryptionKey: encryptionKey),
        );
      }, 
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.remove_red_eye_rounded),
          const SizedBox(width: 12,),
          Text(I18n.translate("showEncryptKey"))
        ],
      )
    ),
    const SizedBox(height: 8,),
    ElevatedButton(
      style: btnNeutralStyle,
      onPressed: () async {
        if (await keyChangeInfo(context)) {
          await budgetState.syncSharedDb(manual: true, changeKey: true);
        }
      }, 
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.rotate_right_rounded),
          const SizedBox(width: 12,),
          Text(I18n.translate("rotateEncryptKey"))
        ]
      )
    ),
    const SizedBox(height: 8,),
    ElevatedButton(
      style: btnNeutralStyle,
      onPressed: () async {
        await keyDialog(context);
        budgetState.syncSharedDb(manual: true);
      }, 
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.update_rounded),
          const SizedBox(width: 12,),
          Text(I18n.translate("updateEncryptKey"))
        ]
      )
    ),
    const SizedBox(height: 16,),
    ElevatedButton(
      style: btnNegativeStyle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.power_off_rounded),
          const SizedBox(width: 12,),
          Text(I18n.translate("disconnectSharedDb"))
        ]
      ),
      onPressed: () async {
        await disconnectDialog(context, budgetState);
      }, 
    ),
    const SizedBox(height: 8,),
  ];
}

Future<bool> keyChangeInfo(BuildContext context) async {
  bool doChange = false;

  await showDialog(
    context: context,
    builder: (context) => AdaptiveAlertDialog(
      title: Text(I18n.translate("confirmRotation")),
      content: Text(I18n.translate("rotateInfo", placeholders: {"updateEncryptKey": I18n.translate("updateEncryptKey")})),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(I18n.translate("cancel")),
        ),
        TextButton(
          onPressed: () {
            doChange = true;
            Navigator.of(context).pop();
          },
          child: Text(I18n.translate("continue")),
        ),
      ],
    )
  );

  return doChange;
}