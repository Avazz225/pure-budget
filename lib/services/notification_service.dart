import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone_latest/flutter_native_timezone_latest.dart';
import 'package:jne_household_app/database_helper.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/keys.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/reminder_settings.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  final Logger _logger = Logger();

  Future<void> init() async {
    if (_initialized) return;

    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
      tzdata.initializeTimeZones();
      final String timeZoneName = await FlutterNativeTimezoneLatest.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    WindowsInitializationSettings windowsInit = WindowsInitializationSettings(appName: I18n.translate("appTitle"), appUserModelId: appUserModelId, guid: guid, iconPath: 'assets/icon.ico');
    InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iosInit, macOS: iosInit, windows: windowsInit);

    await _plugin.initialize(initSettings);
    _initialized = true;

    final settings = await loadReminder();
    if (settings != null) {
      await scheduleReminder(settings);
      _logger.debug("Scheduled reminder, time: ${settings.time}", tag: "notification");
    } else {
      final defaultSettings = ReminderSettings.defaultDaily();
      await scheduleReminder(defaultSettings);
      _logger.debug("Scheduled reminder with default settings", tag: "notification");
    }
  }

  NotificationDetails _buildDetails() {
    const android = AndroidNotificationDetails(
      'pure_budget_reminder_channel',
      'PureBudgetReminder',
      channelDescription: 'Reminder for Pure Budget to track expenses',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const ios = DarwinNotificationDetails();
    return const NotificationDetails(android: android, iOS: ios, macOS: ios);
  }

  Future<void> showTestNotification() async {
    _plugin.show(0, "test", "testBody", _buildDetails());
  }

  Future<void> listScheduledNotification() async {
    final pending = await _plugin.pendingNotificationRequests();

    for (final n in pending) {
  
      _logger.debug("Scheduled ID=${n.id}, title=${n.title}, body=${n.body}, payload: ${n.payload}", tag: "notification");
    }
  }

  Future<void> scheduleReminder(ReminderSettings settings) async {
    await init();
    await cancelAllReminders();

    if (!settings.enabled) return;

    String title = I18n.translate("reminderTitle");
    String body = I18n.translate("reminderText");

    if (Platform.isAndroid) {
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    }

    for (final day in settings.days) {
      final id = 100 + day.index;
      final scheduled = _nextInstanceOfWeekdayTime(day, settings.time);
      _logger.debug("Scheduling reminder for $day at ${settings.time}, scheduled time: $scheduled", tag: "notification");

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        _buildDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }

    _logger.debug("Set new reminders", tag: "notification");

    await DatabaseHelper().updateSettings("reminder", settings.toString());
  }

  Future<ReminderSettings?> loadReminder() async {
    return await DatabaseHelper().loadReminder();
  }

  Future<void> getPendingReminders() async {
    final pending = await _plugin.pendingNotificationRequests();

    for (final n in pending) {
      _logger.debug("Reminder ID=${n.id}, title=${n.title}, body=${n.body}", tag: "notification");
    }
  }

  Future<void> cancelAllReminders() async {
    await _plugin.cancelAll();
    _logger.debug("Cancelled all reminders", tag: "notification");
  }

  tz.TZDateTime _nextInstanceOfWeekdayTime(WeekDay weekday, TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    final targetWeekday = weekday.index + 1;

    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    while (scheduled.weekday != targetWeekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
}
