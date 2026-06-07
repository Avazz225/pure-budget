import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/screens_shared/customization_screen.dart';
import 'package:jne_household_app/screens_shared/settings/settings_about.dart';
import 'package:jne_household_app/screens_shared/settings/settings_accounts.dart';
import 'package:jne_household_app/screens_shared/settings/settings_general.dart';
import 'package:jne_household_app/screens_shared/settings/settings_notifications.dart';
import 'package:jne_household_app/screens_shared/settings/settings_sync.dart';
import 'package:jne_household_app/screens_shared/settings/settings_support.dart';
import 'package:jne_household_app/widgets_shared/settings/settings_category_tile.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = Provider.of<BudgetState>(context);
    final showAccountsCategory = budgetState.bankAccounts.length > 1 || Platform.isAndroid || Platform.isIOS;
    final showNotificationsCategory = !Platform.isWindows;
    final showAppearanceCategory = (Platform.isAndroid || Platform.isIOS)
        ? budgetState.proStatusIsSet()
        : (budgetState.settings.isDesktopPro || kDebugMode);

    return Scaffold(
      appBar: AppBar(
        title: Text(I18n.translate("appSettings")),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Column(
          children: [
            SettingsCategoryTile(
              icon: Icons.tune_rounded,
              title: I18n.translate("settingsCategoryGeneral"),
              onTap: () => _push(context, const SettingsGeneralScreen()),
            ),
            if (showAccountsCategory)
            SettingsCategoryTile(
              icon: Icons.account_balance_rounded,
              title: I18n.translate("settingsCategoryAccounts"),
              onTap: () => _push(context, const SettingsAccountsScreen()),
            ),
            if (showAppearanceCategory)
            SettingsCategoryTile(
              icon: Icons.palette_rounded,
              title: I18n.translate("settingsCategoryAppearance"),
              onTap: () => _push(context, const CustomizationScreen()),
            ),
            if (showNotificationsCategory)
            SettingsCategoryTile(
              icon: Icons.notifications_rounded,
              title: I18n.translate("settingsCategoryNotifications"),
              onTap: () => _push(context, const SettingsNotificationsScreen()),
            ),
            SettingsCategoryTile(
              icon: Icons.sync_rounded,
              title: I18n.translate("settingsCategorySync"),
              onTap: () => _push(context, const SettingsSyncScreen()),
            ),
            SettingsCategoryTile(
              icon: Icons.help_rounded,
              title: I18n.translate("settingsCategorySupport"),
              onTap: () => _push(context, const SettingsSupportScreen()),
            ),
            SettingsCategoryTile(
              icon: Icons.info_rounded,
              title: I18n.translate("settingsCategoryAbout"),
              onTap: () => _push(context, const SettingsAboutScreen()),
            ),
          ]
        )
      ),
    );
  }
}
