// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/btn_styles.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:local_auth/local_auth.dart';


class KeySharingDialog extends StatefulWidget {
  final String encryptionKey;

  const KeySharingDialog({required this.encryptionKey, super.key});

  @override
  State<KeySharingDialog> createState() => _KeySharingDialogState();
}

class _KeySharingDialogState extends State<KeySharingDialog> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticated = false;
  bool _qr = true;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    try {
      bool supported = await auth.isDeviceSupported();
      bool biometricAvailable = await auth.canCheckBiometrics;

      final isBiometricAvailable = biometricAvailable || supported;
      if (isBiometricAvailable) {
        debugPrint("HERE");
        _isAuthenticated = await auth.authenticate(
          localizedReason: I18n.translate("authRequired"),
          options: const AuthenticationOptions(
            useErrorDialogs: true,
            stickyAuth: true,
          ),
        );
      } else {
        // Fallback: PC no auth required
        _isAuthenticated = true;
      }
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text( I18n.translate("authFailed", placeholders: {'error': e.toString()}))),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return AlertDialog(
        title: Text(I18n.translate("authRequired")),
        content: Text(I18n.translate("authText")),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(I18n.translate("cancel")),
          ),
        ],
      );
    }

    // key to base64
    final encodedKey = widget.encryptionKey;

    return AlertDialog(
      title: Text(I18n.translate("encryptKey")),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            ElevatedButton(
              onPressed: () => setState(() {
                _qr = !_qr;
              }), 
              style: btnNeutralStyle,
              child: Text(I18n.translate(_qr ? "showText" : "showQr"))
            ),
            const SizedBox(height: 16,),
            if (_qr)
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                backgroundColor: Colors.white,
                data: encodedKey,
                version: QrVersions.auto,
              ),
            ),
            if (!_qr)
            SizedBox(
              width: 200,
              child: Text(
                formatInBlocks(encodedKey, 4, 12),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontFamily: 'RobotoMono',
                ),
              )
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(I18n.translate("close")),
        ),
      ],
    );
  }
}

String formatInBlocks(String text, int blockSize, int lineBreakInterval) {
  final buffer = StringBuffer();
  for (int i = 0; i < text.length; i++) {
    if (i > 0) {
      if (i % lineBreakInterval == 0) {
        buffer.write('\n');
      } else if (i % blockSize == 0) {
        buffer.write(' ');
      }
    }
    buffer.write(text[i]);
  }
  return buffer.toString();
}