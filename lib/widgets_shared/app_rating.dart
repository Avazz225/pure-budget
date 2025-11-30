import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/btn_styles.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/keys.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/widgets_shared/dialogs/report_issue_dialog.dart';
import 'package:mail_sender/mail_sender.dart';
import 'package:provider/provider.dart';
import 'package:rate_my_app/rate_my_app.dart';

class RateAppLauncher extends StatefulWidget {
  final Widget child;

  const RateAppLauncher({
    super.key,
    required this.child
  });

  @override
  State<RateAppLauncher> createState() => _RateAppLauncherState();
}

class _RateAppLauncherState extends State<RateAppLauncher> {
  late RateMyApp rateMyApp;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _logger.debug("Initializing RateMyApp", tag: "RateMyApp");
    rateMyApp = RateMyApp(
      minDays: ratingMinDays,
      minLaunches: ratingMinLaunches,
      remindDays: ratingRemindDays,
      remindLaunches: ratingRemindLaunches,
      googlePlayIdentifier: androidQualifiedName,
      appStoreIdentifier: iosStoreIdentifier,
    );

    rateMyApp.init().then((_) {
      if (rateMyApp.shouldOpenDialog || kDebugMode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showRateDialog();
        });
      }
    });
  }

  void showRateDialog() {
    rateMyApp.showStarRateDialog (
      context,
      title: I18n.translate('rateApp', placeholders: {'appName': I18n.translate('appTitle')}),
      message: I18n.translate('rateAppText', placeholders: {'appName': I18n.translate('appTitle')}),
      starRatingOptions: const StarRatingOptions(),
      actionsBuilder: (context, stars) {
        return [
          ElevatedButton(
            style: btnPositiveStyle,
            onPressed: () async {
              if (stars != null && stars >= 4) {
                await rateMyApp.callEvent(RateMyAppEventType.rateButtonPressed);
                // open store listing
                await rateMyApp.launchStore();
              }

              else if (stars != null && stars < 2) {
                await rateMyApp.callEvent(RateMyAppEventType.laterButtonPressed);
                // open feedback popup
                final budgetState = Provider.of<BudgetState>(context, listen: false);
                List<String> data = await showReportIssueDialog(context, budgetState);
                if (data.length == 2) {
                  if (Platform.isAndroid || Platform.isIOS) {
                    final mailSenderPlugin = MailSender();
                    mailSenderPlugin.sendMail(
                      recipient: [reportEmail],
                      subject: data[0],
                      body: data[1]
                    );
                  }
                }
              }

              Navigator.pop<RateMyAppDialogButton>(context);
            },
            child: Text(I18n.translate('okay')),
          ),
          ElevatedButton(
            onPressed: () {
              rateMyApp.callEvent(RateMyAppEventType.laterButtonPressed);
              Navigator.pop<RateMyAppDialogButton>(context);
            },
            child: Text(I18n.translate('later')),
          ),
          ElevatedButton(
            onPressed: () {
              rateMyApp.callEvent(RateMyAppEventType.noButtonPressed);
              Navigator.pop<RateMyAppDialogButton>(context);
            },
            child: Text(I18n.translate('never')),
          )
        ];
      },
      ignoreNativeDialog: Platform.isAndroid,
      dialogStyle: const DialogStyle(
        titleAlign: TextAlign.center,
        messageAlign: TextAlign.center,
        messagePadding: EdgeInsets.only(bottom: 20),
      ),
      onDismissed: () => rateMyApp.callEvent(RateMyAppEventType.laterButtonPressed),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
