import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jne_household_app/i18n/i18n.dart';

// Applies locale-aware decimal formatting to a TextEditingController.
// Call from TextFormField.onChanged to swap '.' ↔ ',' and keep the cursor at end.
void applyDecimalFormatting(String value, TextEditingController controller, void Function(void Function()) setState) {
  setState(() {
    if (I18n.comma()) {
      controller.text = value.replaceAll('.', ',');
    }
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
  });
}

// Shows a localised SnackBar on any BuildContext.
extension ContextSnackBar on BuildContext {
  void showSnackBar(String messageKey, {Map<String, String>? placeholders}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(I18n.translate(messageKey, placeholders: placeholders))),
    );
  }
}

class DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalRange;

  DecimalTextInputFormatter({required this.decimalRange});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // Erlaube nur Zahlen, Punkt und Komma
    if (!RegExp(r'^[0-9.,-]*$').hasMatch(text)) {
      // Ungültige Zeichen => Rückgabe alter Wert (also nicht löschen)
      return oldValue;
    }

    // Ersetze Komma durch Punkt für einfachere Prüfung
    String normalizedText = text.replaceAll(',', '.');

    // Falls mehr als ein Punkt vorkommt => nicht erlauben
    if ('.'.allMatches(normalizedText).length > 1) {
      return oldValue;
    }

    // Prüfe auf Nachkommastellen
    if (normalizedText.contains('.')) {
      int index = normalizedText.indexOf('.');
      String decimalPart = normalizedText.substring(index + 1);
      if (decimalPart.length > decimalRange) {
        // Zu viele Nachkommastellen => nicht erlauben
        return oldValue;
      }
    }

    // Alles okay, neuen Wert übernehmen
    return newValue;
  }
}