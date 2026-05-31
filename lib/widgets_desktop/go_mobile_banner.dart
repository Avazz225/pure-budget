import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/keys.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/models/design_state.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class GoMobileBanner extends StatefulWidget {
  const GoMobileBanner({
    super.key,
  });

  @override
  State<GoMobileBanner> createState() => _GoMobileBannerState();
}

class _GoMobileBannerState extends State<GoMobileBanner> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final designState = context.watch<DesignState>();
    final budgetState = context.read<BudgetState>();
    final canDismiss = budgetState.proStatusIsSet(desktop: true);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: .5),
        ),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  I18n.translate("goMobile"),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(I18n.translate("mobileAd")),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => SizeTransition(
                    sizeFactor: animation,
                    alignment: Alignment.topCenter,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: _hovering
                      ? Padding(
                          key: const ValueKey('icons'),
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Image.asset(
                                  'assets/icons/Download_on_the_App_Store_Badge_US-UK_RGB_blk_092917.png',
                                  height: 48,
                                ),
                                tooltip: I18n.translate("openVersion",
                                    placeholders: {
                                      "platform": I18n.translate("ios")
                                    }),
                                onPressed: () =>
                                    launchUrl(Uri.parse(appStoreLink)),
                              ),
                              IconButton(
                                icon: Image.asset(
                                  'assets/icons/GetItOnGooglePlay_Badge_Web_color_English.png',
                                  height: 48,
                                ),
                                tooltip: I18n.translate("openVersion",
                                    placeholders: {
                                      "platform": I18n.translate("android")
                                    }),
                                onPressed: () =>
                                    launchUrl(Uri.parse(playStoreLink)),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(key: ValueKey('empty')),
                ),
              ],
            ),
            // Dismiss button — only visible to Pro desktop users
            if (canDismiss)
              Tooltip(
                message: I18n.translate("dismissBannerForever"),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => designState.updateGoMobileBannerDismissed(true),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
