import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/widgets_shared/loading_animation.dart';

Future<Map<String, dynamic>> showCustomDeviceNameDialog({
  required BuildContext context,
  required BudgetState budgetState,
  required uuid,
  required Map<String, dynamic> metadata
}) async {
  final TextEditingController controller = TextEditingController(text: metadata['customname'] ?? "");
  final FocusNode controllerFocusNode = FocusNode();
  bool processing = false;

  final result = await showDialog(
    context: context, 
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(I18n.translate("editCustomName")),
            content: TextField(
              controller: controller,
              focusNode: controllerFocusNode,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: I18n.translate("customName")),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(I18n.translate("cancel")),
              ),
              TextButton(
                onPressed: () async {
                  if (!processing) {
                    setState(() {
                      processing = true;
                    });
                    final updatedMetadata = {
                      ...metadata,
                      'customname': controller.text.trim(),
                    };

                    if (await budgetState.updateRemoteDeviceMetadata(uuid, updatedMetadata)){
                      Navigator.of(context).pop(updatedMetadata);
                    }
                  }
                },
                child: (processing) ? loadingAnimation((Theme.of(context).colorScheme.brightness == Brightness.dark ) ? Colors.white : Colors.black) : Text(I18n.translate("save"))
              ),
            ]
          ); 
        }
      );
    }
  );
  return result ?? metadata;
}