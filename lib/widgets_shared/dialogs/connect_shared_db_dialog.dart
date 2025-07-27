// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/btn_styles.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/shared_database/encryption_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';


Future<void> connectSharedDbDialog(BuildContext context, BudgetState budgetState, selectedPath, sharedDbExists) async {
  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(I18n.translate("connectToSharedDb")),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    I18n.translate(sharedDbExists ? "sharedDbAlreadyExists" : "newSharedDb")
                  ),
                  const SizedBox(height: 16,),
                  ElevatedButton(
                    style: btnNeutralStyle,
                    onPressed: () async {
                      if(sharedDbExists) {
                        if (!(await keyDialog(context))) {
                          Navigator.of(context).pop();
                        }
                      }
                      bool result = await budgetState.updateSharedDbUrl(selectedPath ?? "none");
                      
                      if (!result) {
                        await showDialog(context: context, builder: (context) {
                          return AlertDialog(
                            title: Text(I18n.translate("sDbConnectionFail")),
                            content: Text(I18n.translate("sDbConnectionFailedInfo")),
                          );
                        });
                      }
                      Navigator.of(context).pop();
                    }, 
                    child: Text(I18n.translate("connect"))
                  )
                ],
              )
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(I18n.translate("cancel")),
              ),
            ],
          );
        },
      );
    }
  );
}

Future<bool> keyDialog(BuildContext context) async {
  String keyInput = '';
  bool qrScanActive = false;
  TextEditingController _controller = TextEditingController();

  String formatInput(String input) {
    // Entferne alle bestehenden Leerzeichen
    final cleaned = input.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(cleaned[i]);
    }
    return buffer.toString();
  }

  return await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(I18n.translate("keyInputInfo")),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(I18n.translate("onlyIfNew")),
                  const SizedBox(height: 16,),
                  if (qrScanActive)
                    SizedBox(
                      height: 250,
                      child: MobileScanner(
                        onDetect: (barcode) async {
                          final String code = barcode.barcodes.first.displayValue!;
                          debugPrint(code);
                          await EncryptionHelper.saveKey(code);
                          Navigator.of(context).pop(true);
                        },
                      ),
                    ),
                  if (!qrScanActive)
                    Column(
                      children: [
                        TextField(
                          controller: _controller,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            fontFamily: 'RobotoMono',
                          ),
                          onChanged: (value) {
                            final rawValue = value.replaceAll(' ', '');
                            final formattedValue = formatInput(rawValue);

                            // Verhindert Cursor-Springen
                            final oldSelection = _controller.selection.baseOffset;
                            int offset = (oldSelection == formattedValue.length - 1) ? formattedValue.length.clamp(0, formattedValue.length) : oldSelection;
                            _controller.value = TextEditingValue(
                              text: formattedValue,
                              selection: TextSelection.collapsed(
                                  offset: offset),
                            );

                            setState(() {
                              keyInput = rawValue;
                            });
                          },
                          decoration: InputDecoration(
                            labelText: I18n.translate("keyInput"),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (Platform.isAndroid || Platform.isIOS || kDebugMode)
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              qrScanActive = true;
                            });
                          },
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          label: Text(I18n.translate("scanQrCode")),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text(I18n.translate("cancel")),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (keyInput.isNotEmpty) {
                    await EncryptionHelper.saveKey(keyInput.replaceAll(" ", ""));
                  }
                  Navigator.of(context).pop(true);
                },
                child: Text(I18n.translate("continue")),
              ),
            ],
          );
        },
      );
    },
  );
}