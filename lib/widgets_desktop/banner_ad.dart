// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:jne_household_app/keys.dart';

class MainBanner extends StatefulWidget {
  const MainBanner({super.key});

  @override
  MainBannerState createState() => MainBannerState();
}

class MainBannerState extends State<MainBanner> {
  late InAppWebViewController _webViewController;

  final String adWebsiteUrl = desktopAdWebsiteUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri.uri(Uri.parse(adWebsiteUrl))),
        onWebViewCreated: (controller) {
          _webViewController = controller;
        },
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          transparentBackground: true,
        ),
      ),
    );
  }
}
