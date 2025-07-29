import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jne_household_app/logger.dart';
import '../i18n/i18n.dart';

String locale = PlatformDispatcher.instance.locale.toString();

String formatDate(String? dateString, BuildContext context, {bool short=false, year=true}) {
  if (dateString == null || dateString.isEmpty) {
    return I18n.translate("noDate");
  }
  try {
    final parsedDate = DateTime.parse(dateString);

    DateFormat format = (short) ? (year) ? DateFormat.yMMMd(locale) : DateFormat.MMMd(locale) : DateFormat.MMMMd(locale);
    return format.format(parsedDate);
  } catch (e) {
    Logger().warning("Parsed invalid date: $e", tag: "dateParsing");
    return dateString;
  }
}

String shortMonthYr(DateTime date){
  DateFormat format = DateFormat.yMMM(locale);
  return format.format(date);
}