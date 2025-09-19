import 'dart:convert';

import 'package:flutter/material.dart';

enum WeekDay { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

class ReminderSettings {
  bool enabled;
  TimeOfDay time;
  Set<WeekDay> days;

  ReminderSettings({
    required this.enabled,
    required this.time,
    required this.days,
  });

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'hour': time.hour,
    'minute': time.minute,
    'days': days.map((d) => d.index).toList(),
  };

  @override
  String toString() => json.encode(toJson());

  factory ReminderSettings.fromJson(Map<String, dynamic> json) => ReminderSettings(
      enabled: (json['enabled'] ?? true) as bool,
      time: TimeOfDay(
        hour: (json['hour'] ?? 19) as int,
        minute: (json['minute'] ?? 0) as int,
      ),
      days: (json['days'] as List<dynamic>?)
              ?.map((i) => WeekDay.values[i as int])
              .toSet() ??
          {
            WeekDay.monday,
            WeekDay.tuesday,
            WeekDay.wednesday,
            WeekDay.thursday,
            WeekDay.friday,
            WeekDay.saturday,
            WeekDay.sunday,
          },
    );


  factory ReminderSettings.defaultDaily() => ReminderSettings(
    enabled: true,
    time: const TimeOfDay(hour: 19, minute: 0),
    days: {
      WeekDay.monday,
      WeekDay.tuesday,
      WeekDay.wednesday,
      WeekDay.thursday,
      WeekDay.friday,
      WeekDay.saturday,
      WeekDay.sunday,
    },
  );
}
