import 'package:jne_household_app/models/booking_principles.dart';

DateTime nthBusinessDay(int year, int month, [int dayCount = 1]) {
  if (dayCount < 1) {
    throw ArgumentError("Der Wert für 'dayCount' muss mindestens 1 sein.");
  }
  
  DateTime currentDate = DateTime(year, month, 1);
  int businessDays = 0;

  while (businessDays < dayCount) {
    if (currentDate.weekday < 6) { // Montag bis Freitag sind Werktage
      businessDays++;
    }
    if (businessDays < dayCount) {
      currentDate = currentDate.add(const Duration(days: 1));
    }
  }
  return currentDate;
}

DateTime nthLastBusinessDay(int year, int month, [int dayCount = 1]) {
  if (dayCount < 1) {
    throw ArgumentError("Der Wert für 'dayCount' muss mindestens 1 sein.");
  }
  
  DateTime currentDate = (month == 12)
      ? DateTime(year + 1, 1, 0)
      : DateTime(year, month + 1, 0);

  int businessDays = 0;
  
  while (businessDays < dayCount) {
    if (currentDate.weekday < 6) {
      businessDays++;
    }
    if (businessDays < dayCount) {
      currentDate = currentDate.subtract(const Duration(days: 1));
    }
  }
  return currentDate;
}

DateTime nthDay(int year, int month, [int dayCount = 1]) {
  if (dayCount < 1) {
    throw ArgumentError("Der Wert für 'dayCount' muss mindestens 1 sein.");
  }
  return DateTime(year, month, dayCount);
}

DateTime nthLastDay(int year, int month, [int dayCount = 1]) {
  if (dayCount < 1) {
    throw ArgumentError("Der Wert für 'dayCount' muss mindestens 1 sein.");
  }
  
  DateTime lastDay = (month == 12) ? DateTime(year + 1, 1, 0) : DateTime(year, month + 1, 0);
  return lastDay.subtract(Duration(days: dayCount - 1));
}

bool isSameDay(DateTime d1, DateTime d2) {
  return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
}

List<Map<String, DateTime>> getMultipleRanges(Map<String, dynamic> resetInfo, int count, DateTime firstDate) {
  DateTime today = DateTime.now();
  bool include = true;

  List<Map<String, DateTime>> result = [];

  for (int i = 0; i < count; i++) {
    if (!include) break;

    DateTime targetDay = subtractMonths(today, i);
    Map<String, DateTime> range = getDateRangeForPrinciple(
      resetInfo,
      year: targetDay.year,
      month: targetDay.month,
      now: targetDay,
    );

    if (dateInOrAfterRange(firstDate, range['end']!)) {
      result.add(range);
    } else {
      include = false;
    }
  }

  return result;
}

DateTime subtractMonths(DateTime date, int months) {
  int year = date.year;
  int month = date.month - months;
  while (month <= 0) {
    year--;
    month += 12;
  }
  int day = date.day;
  int lastDayOfMonth = DateTime(year, month + 1, 0).day;
  if (day > lastDayOfMonth) {
    day = lastDayOfMonth;
  }
  return DateTime(year, month, day);
}

Map<String, DateTime> getDateRangeForPrinciple(Map<String, dynamic> resetInfo, {int? year, int? month, DateTime? now}) {
  DateTime today = now ?? DateTime.now();
  int targetYear = year ?? today.year;
  int targetMonth = month ?? today.month;

  String principle = resetInfo['principle'];
  int day = resetInfo['day'];

  if (principleWithoutDay.contains(principle)) {
    day = 1;
  }

  switch (principle) {
    case 'monthStart':
    case 'nthDayOfMonth':
      DateTime targetDate = nthDay(targetYear, targetMonth, day);
      return isSameDay(today, targetDate) || today.isAfter(targetDate)
          ? {'start': targetDate, 'end': nthDay(targetYear, targetMonth + 1, day)}
          : {'start': nthDay(targetYear, targetMonth - 1, day), 'end': targetDate};
    
    case 'monthEnd':
    case 'nthLastDayOfMonth':
      DateTime targetDate = nthLastDay(targetYear, targetMonth, day);
      return isSameDay(today, targetDate) || today.isBefore(targetDate)
          ? {'start': nthLastDay(targetYear, targetMonth - 1, day), 'end': targetDate}
          : {'start': targetDate, 'end': nthLastDay(targetYear, targetMonth + 1, day)};
    
    case 'firstBusinessDayOfMonth':
    case 'nthBusinessDayOfMonth':
      DateTime targetDate = nthBusinessDay(targetYear, targetMonth, day);
      return isSameDay(today, targetDate) || today.isAfter(targetDate)
          ? {'start': targetDate, 'end': nthBusinessDay(targetYear, targetMonth + 1, day)}
          : {'start': nthBusinessDay(targetYear, targetMonth - 1, day), 'end': targetDate};
    
    case 'lastBusinessDayOfMonth':
    case 'nthLastBusinessDayOfMonth':
      DateTime targetDate = nthLastBusinessDay(targetYear, targetMonth, day);
      return isSameDay(today, targetDate) || today.isBefore(targetDate)
          ? {'start': nthLastBusinessDay(targetYear, targetMonth - 1, day), 'end': targetDate}
          : {'start': targetDate, 'end': nthLastBusinessDay(targetYear, targetMonth + 1, day)};
    
    default:
      throw ArgumentError("Ungültiges Prinzip: $principle");
  }
}

DateTime getDateForPrinciple(String principle, int day, int targetYear, int targetMonth) {
  if (principleWithoutDay.contains(principle)) {
    day = 1;
  }

  switch (principle) {
    case 'monthStart':
    case 'nthDayOfMonth':
      return nthDay(targetYear, targetMonth, day);
    
    case 'monthEnd':
    case 'nthLastDayOfMonth':
      return nthLastDay(targetYear, targetMonth, day);
    
    case 'firstBusinessDayOfMonth':
    case 'nthBusinessDayOfMonth':
      return nthBusinessDay(targetYear, targetMonth, day);
    
    case 'lastBusinessDayOfMonth':
    case 'nthLastBusinessDayOfMonth':
      return nthLastBusinessDay(targetYear, targetMonth, day);
    
    default:
      throw ArgumentError("Ungültiges Prinzip: $principle");
  }
}

bool dateInOrAfterRange(DateTime date, DateTime rangeEnd) {
  return !rangeEnd.isBefore(date) && !date.isAtSameMomentAs(rangeEnd);
}

bool dateBeforRange(DateTime date, DateTime rangeStart) {
  return date.isBefore(rangeStart);
}