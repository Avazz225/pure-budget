import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';

class I18n {
  static Locale defaultLocale = const Locale("en");
  static String language = "";
  static bool commaAsSeparator = false;
  static Map<String, String> _localizedStrings = {};
  static List<String> moneyVars = ["amount", "planned", "actual"];
  // variants have to be listed before the base language is
  static List<String> providedLanguages = [
    "de",
    "en",
    "es",
    "fr",
    "hi",
    "it",
    "ja",
    "ko",
    "pl",
    "pt_br",
    "pt",
    "ru",
    "tr",
    "zh",
    "klingon",
    "elbian"
  ];
  
  static List<String> commaLang = [
    "de",
    "es",
    "fr",
    "hi",
    "it",
    "pl",
    "pt",
    "ru",
    "tr"
  ];

  static Future<void> load(String languageCode, {Locale ?locale}) async {
    if (locale != null) {
      defaultLocale = locale;
    }

    if (!providedLanguages.any((lang) => languageCode.startsWith(lang))){
      language = "en";
    } else {
      language = providedLanguages.where((lang) => languageCode.startsWith(lang)).toList()[0];
    }
    
    commaAsSeparator = commaLang.contains(language);
    String jsonString = await rootBundle.loadString('lib/i18n/$language.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
  }

  static bool comma() {
    return commaAsSeparator;
  }

  static List<String> getProvidedLangs() {
    providedLanguages.sort();
    return providedLanguages;
  }

  static String translate(String key, {Map<String, String>? placeholders}) {
    String translation = _localizedStrings[key] ?? key;

    if (placeholders != null) {
      placeholders.forEach((placeholder, value) {
        if (commaAsSeparator && moneyVars.contains(placeholder)){
          value = value.replaceAll(".", ",");
        }
        translation = translation.replaceAll('{$placeholder}', value);
      });
    }
    return translation;
  }

  static String getLocaleString() {
    if (language == "klingon" || language == "elbian") return "en";
    return language.substring(0, 2);
  }

  static List<Locale> getLocales() {
    List<Locale> localeList = [];

    for (String lang in providedLanguages) {
      if (lang != "klingon" && lang != "elbian" && !lang.contains("_")) localeList.add(Locale(lang));
    }

    return localeList;
  }
}