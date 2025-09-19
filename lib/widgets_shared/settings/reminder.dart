import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/btn_styles.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/reminder_settings.dart';
import 'package:jne_household_app/services/notification_service.dart';

class ReminderSettingsWidget extends StatefulWidget {
  const ReminderSettingsWidget({super.key});

  @override
  State<ReminderSettingsWidget> createState() => _ReminderSettingsWidgetState();
}

class _ReminderSettingsWidgetState extends State<ReminderSettingsWidget> {
  bool _enabled = false;
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);
  Set<WeekDay> _days = {};

  final _service = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final loaded = await _service.loadReminder();
    setState(() {
      if (loaded != null) {
        _enabled = loaded.enabled;
        _time = loaded.time;
        _days = loaded.days;
      } else {
        final def = ReminderSettings.defaultDaily();
        _enabled = def.enabled;
        _time = def.time;
        _days = def.days;
      }
    });
  }

  Future<void> _pickTime() async {
    final newTime = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (newTime != null) {
      setState(() => _time = newTime);
    }
  }

  Future<void> _saveSettings() async {
    final settings = ReminderSettings(
      enabled: _enabled,
      time: _time,
      days: _days,
    );
    await _service.scheduleReminder(settings);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(I18n.translate("reminderSaved"))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  I18n.translate("activateReminder"),
                  style: Theme.of(context).textTheme.bodyLarge
                ),
                Switch(
                  value: _enabled,
                  onChanged: (val) => setState(() => _enabled = val),
                  activeColor: Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(I18n.translate("time", placeholders: {"time": _time.format(context)})),
                TextButton(
                  onPressed: _enabled ? _pickTime : null,
                  style: btnNeutralStyle,
                  child: Text(I18n.translate("change")),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 6,
              children: WeekDay.values.map((day) {
                final selected = _days.contains(day);
                return FilterChip(
                  label: Text(_dayToText(day)),
                  selected: selected,
                  onSelected: _enabled
                      ? (sel) {
                          setState(() {
                            if (sel) {
                              _days.add(day);
                            } else {
                              _days.remove(day);
                            }
                          });
                        }
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save_rounded),
                style: btnPositiveStyle,
                label: Text(I18n.translate("save")),
                onPressed: _saveSettings,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dayToText(WeekDay d) {
    switch (d) {
      case WeekDay.monday:
        return I18n.translate("mon");
      case WeekDay.tuesday:
        return I18n.translate("tue");
      case WeekDay.wednesday:
        return I18n.translate("wed");
      case WeekDay.thursday:
        return I18n.translate("thu");
      case WeekDay.friday:
        return I18n.translate("fri");
      case WeekDay.saturday:
        return I18n.translate("sat");
      case WeekDay.sunday:
        return I18n.translate("sun");
    }
  }
}
