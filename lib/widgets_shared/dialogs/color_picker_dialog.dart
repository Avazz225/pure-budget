import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:jne_household_app/services/brightness.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/widgets_shared/dialogs/adaptive_alert_dialog.dart';

Future <Color> openColorPickerDialog(BuildContext context, Color selectedColor) async {
  Color returnColor = selectedColor;

  await showDialog(
    context: context,
    builder: (context) {
      Color tempColor = selectedColor;
      return StatefulBuilder(
        builder: (context, setState) {
          return AdaptiveAlertDialog(
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ColorPicker(
                    enableAlpha: false,
                    labelTypes: const [],
                    pickerColor: tempColor,
                    onColorChanged: (color) {
                      setState(() {
                        tempColor = color;
                      });
                    },
                    pickerAreaHeightPercent: 0.8,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: tempColor,
                    child: Center(
                      child: Text(
                        I18n.translate("appTitle"),
                        style: TextStyle(
                          fontSize: 16,
                          color: getTextColor(tempColor, 0, context: context),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text(I18n.translate("cancel")),
                onPressed: () {
                  returnColor = selectedColor;
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text(I18n.translate("ok")),
                onPressed: () {
                  returnColor = tempColor;
                  Navigator.of(context).pop();
                }
              ),
            ],
          );
        },
      );
    },
  );

  return returnColor;
}