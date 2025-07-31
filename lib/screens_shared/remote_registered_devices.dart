
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/btn_styles.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/widgets_shared/loading_animation.dart';

class RemoteRegisteredDevices extends StatefulWidget {
  final BudgetState budgetState;
  final List<Map<String, dynamic>> registeredDevices;
  final String uuid;
  const RemoteRegisteredDevices({super.key,  required this.budgetState, required this.registeredDevices, required this.uuid});

  @override
  RemoteRegisteredDevicesState createState() =>RemoteRegisteredDevicesState();
}


class RemoteRegisteredDevicesState extends State<RemoteRegisteredDevices> {
  late List<Map<String, dynamic>> registeredDevices;
  bool processing = false;

  @override
  void initState() {
    super.initState();
    registeredDevices = widget.registeredDevices
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

    Logger().debug(registeredDevices.toString(), tag: "registeredDevices");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(I18n.translate("registeredDevices")),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: registeredDevices.length,
              itemBuilder: (context, index) {
                final item = registeredDevices[index];
                final thisDevice = item['id'] == widget.uuid;
                final metadata = jsonDecode(item['deviceMetadata']);
                bool blocked = item['blocked'] == 1;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: blocked
                      ? const BorderSide(color: Colors.red, width: 1)
                      : BorderSide.none,
                  ),
                  child: ListTile(
                    title: Text(
                      metadata.containsKey("customname")
                        ? "${metadata['customname']}${(thisDevice)?" ${I18n.translate("thisDevice")}":""}"
                        : "${I18n.translate("device", placeholders: {"os": I18n.translate(metadata['platform'])})}${(thisDevice)?" ${I18n.translate("thisDevice")}":""}",
                    ),
                    subtitle: Text(item['id']),
                    trailing: (thisDevice) ? null : ElevatedButton(
                      style: (blocked) ? btnNegativeStyle : btnNeutralStyle,
                      onPressed: () async {
                        try {
                          setState(() {
                            processing = true;
                          });
                          int newStatus = (registeredDevices[index]['blocked'].toString() == "0" ) ? 1 : 0;
                          if ((await widget.budgetState.changeBlockStatus(newStatus, item['id']))) {
                            setState(() {
                              registeredDevices[index]['blocked'] = newStatus;
                            });
                          }
                        } catch (e) {
                          Logger().error("Error blocking device devices: $e", tag: "deviceManagement");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        } finally {
                          setState(() {
                            processing = false;
                          });
                        }
                      }, 
                      child: (processing) ? loadingAnimation(Colors.white) : Text(blocked ? I18n.translate("unblock") : I18n.translate("block"))
                    )
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}