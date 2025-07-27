import 'package:flutter/services.dart';

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