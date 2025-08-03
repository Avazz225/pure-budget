import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerPage extends StatelessWidget {
  final Function(String) onCodeScanned;

  const ScannerPage({super.key, required this.onCodeScanned});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(I18n.translate("scanQrCode"))),
      body: MobileScanner(
        onDetect: (barcode) {
          final String? code = barcode.barcodes.first.displayValue;
          if (code != null && code.isNotEmpty) {
            onCodeScanned(code);
          }
        },
      ),
    );
  }
}