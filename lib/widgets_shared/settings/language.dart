import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';

class Language extends StatelessWidget {
  final BudgetState budgetState;
  Language({super.key, required this.budgetState});

  final Map<String, String> availableLanguages = {
    "auto": I18n.translate("automaticBlank"),
    "de": "Deutsch",
    "en": "English",
    "es": "Español",
    "fr": "Français",
    "it": "Italiano",
    "pl": "Polski",
    "pt_br": "Português (Brasil)",
    "pt": "Português (Portugal)",
    "ru": "Русский",
    "tr": "Türkçe",
    "hi": "हिन्दी",
    "ja": "日本語",
    "ko": "한국어",
    "zh": "中文",
    "klingon": "tlhIngan Hol",
    "elbian": "Edhellen (Sindarin)"
  };
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              I18n.translate("language"),
              style: Theme.of(context).textTheme.bodyLarge,
            )
          ),
          DropdownButton<String>(
            value: budgetState.language,
            items: availableLanguages.entries.map((entry) {
              String index = entry.key;
              String displayText = entry.value;
              return DropdownMenuItem<String>(
                value: index,
                child: Text(displayText),
              );
            }).toList(),
            onChanged: (String? selectedLanguage) async {
              if (selectedLanguage != null) {
                Future.microtask(() async {
                  await budgetState.updateLanguage(selectedLanguage);
                });
              }
            },
          )
        ],
      )
    );
  }
}