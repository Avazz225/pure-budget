import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';

Future<DateTime> pickMonthDayWithDatePicker(BuildContext context, {DateTime? providedDate}) async {
  final initialDate = providedDate ?? DateTime.now();
  final selectedDate = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
    cancelText: I18n.translate('cancel'),
    helpText: I18n.translate("selectDate"),
    confirmText: I18n.translate("ok"),
    locale: Locale(I18n.getLocaleString())
  );

  if (selectedDate != null) {
    return selectedDate;
  } else {
    return initialDate;
  }
}