import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/services/notification_service.dart';
import 'package:jne_household_app/widgets_shared/settings/reminder.dart';

class SettingsNotificationsScreen extends StatelessWidget {
  const SettingsNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(I18n.translate("settingsCategoryNotifications")),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Column(
          children: [
            const ReminderSettingsWidget(),
            if (kDebugMode)
            ...[
              ElevatedButton(onPressed: () => NotificationService().showTestNotification(), child: const Text("DEBUG: Show test notification")),
              ElevatedButton(onPressed: () => NotificationService().listScheduledNotification(), child: const Text("DEBUG: List scheduled notifications")),
            ]
          ]
        )
      ),
    );
  }
}
