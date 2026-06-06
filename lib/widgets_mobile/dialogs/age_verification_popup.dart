import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';

void ageVerificationStatus(BuildContext context, bool isDenied) {
  showDialog(
    context: context,
    barrierDismissible: false,
    fullscreenDialog: true,
    useSafeArea: false,
    builder: (context) {
      return PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(I18n.translate("ageVerification")),
          content: Text(isDenied
              ? I18n.translate("ageVerificationDeniedMessage")
              : I18n.translate("ageVerificationRequiredMessage")),
        )
      );
    },
  );
}