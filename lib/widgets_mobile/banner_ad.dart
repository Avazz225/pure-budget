import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:jne_household_app/consent_manager.dart';
import 'dart:io';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:flutter/foundation.dart';
import 'package:jne_household_app/keys.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/widgets_mobile/overlay_helper.dart';

class MainBanner extends StatefulWidget {
  const MainBanner({super.key});

  @override
  MainBannerState createState() => MainBannerState();
}

class MainBannerState extends State<MainBanner> {
  final _consentManager = ConsentManager();
  var _isMobileAdsInitializeCalled = false;
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isBlocked = false;

  final String _adUnitId = Platform.operatingSystem == "android" ? androidAppUnitId : iosAppUnitId;

  @override
  void initState() {
    super.initState();

    _consentManager.gatherConsent((consentGatheringError) {
      if (consentGatheringError != null) {
        // Consent not obtained in current session.
        Logger().debug(
          "${consentGatheringError.errorCode}: ${consentGatheringError.message}",
          tag: "bannerAd"
        );
      }

      // Check if a privacy options entry point is required.
      _getIsPrivacyOptionsRequired();

      // Attempt to initialize the Mobile Ads SDK.
      _initializeMobileAdsSDK();
    });

    // This sample attempts to load ads using consent obtained in the previous session.
    _initializeMobileAdsSDK();
  }

  @override
  Widget build (BuildContext context) {
    return Stack(
      children: [
        if (_bannerAd != null && _isLoaded && !_isBlocked)
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
          ),
        if (!_isLoaded && !_isBlocked)
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 50,
                color: Colors.indigo[900],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      I18n.translate("adLoading"),
                      textAlign: TextAlign.center,
                    ),
                  ]
                )
              ),
            ),
          ),
        if (!_isLoaded && _isBlocked)
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 50,
                color: Colors.indigo[900],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      I18n.translate("adError"),
                      textAlign: TextAlign.center,
                    ),
                  ]
                )
              ),
            ),
          ),
      ],
    );
  }

  /// Loads and shows a banner ad.
  ///
  /// Dimensions of the ad are determined by the width of the screen.
  void _loadAd() async {
    // Only load an ad if the Mobile Ads SDK has gathered consent aligned with
    // the app's configured messages.
    var canRequestAds = await _consentManager.canRequestAds();
    if (!canRequestAds) {
      return;
    }

    if (!mounted) {
      return;
    }

    // Get an AnchoredAdaptiveBannerAdSize before loading the ad.
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.sizeOf(context).width.truncate(),
    );

    if (size == null) {
      // Unable to get width of anchored banner.
      return;
    }

    if (kDebugMode) {
      MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: ["525CB608F91AC3F1FE28085F51467095"], // Deine ID aus dem Log
        ),
      );
    }

    BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
            _isBlocked = false;
            OverlayHelper.removeOverlay();
          });
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (ad, err) {
          _isBlocked = true;
          //OverlayHelper.showOverlay(context);
          ad.dispose();
        },
      ),
    ).load();
  }

  /// Redraw the app bar actions if a privacy options entry point is required.
  void _getIsPrivacyOptionsRequired() async {
    if (await _consentManager.isPrivacyOptionsRequired()) {
      setState(() {

      });
    }
  }

  /// Initialize the Mobile Ads SDK if the SDK has gathered consent aligned with
  /// the app's configured messages.
  void _initializeMobileAdsSDK() async {
    if (_isMobileAdsInitializeCalled) {
      return;
    }

    if (await _consentManager.canRequestAds()) {
      _isMobileAdsInitializeCalled = true;

      // Initialize the Mobile Ads SDK.
      MobileAds.instance.initialize();

      // Load an ad.
      _loadAd();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}

// prod-id android: ca-app-pub-9051906478229407/4391337422
