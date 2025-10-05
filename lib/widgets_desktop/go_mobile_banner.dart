import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/keys.dart';
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: .5),
        ),
        child: Column(
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
                axisAlignment: -1.0,
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
      ),
    );
  }
}
