// main.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jne_household_app/services/uri_handler.dart';
import 'package:window_manager/window_manager.dart';
import 'package:jne_household_app/services/quick_actions_service.dart';
import 'package:jne_household_app/services/debug_screenshot_manager.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/models/design_state.dart';
import 'package:jne_household_app/screens_desktop/desktop_home_screen.dart';
import 'package:jne_household_app/screens_shared/introduction.dart';
import 'package:jne_household_app/widgets_shared/app_background.dart';
import 'package:jne_household_app/widgets_shared/dialogs/adaptive_alert_dialog.dart';
import 'package:jne_household_app/widgets_shared/dialogs/expense_dialog.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:jne_household_app/screens_mobile/mobile_home_screen.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/services/initialization_service.dart';
import 'package:tray_manager/tray_manager.dart';

// automatically take screenshots by using --dart-define=SCREENS=t
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // initialize logger
  final logger = Logger();
  await logger.init(minLevel: (kDebugMode) ? LogLevel.debug : LogLevel.error);
  const bool takeScreenshots = String.fromEnvironment('SCREENS', defaultValue: 'f') == "t";

  final quickActions = QuickActionsService();
  if (Platform.isIOS) {
    await quickActions.initIOS();
  }

  // initialize app
  final initializationData = await InitializationService.initializeApp();
  logger.info("Initialization finished", tag: "init");

  logger.info("Initialize quick actions", tag: "quickActions");
  await quickActions.init(
    categories: initializationData.budgetState.categories,
    sharedDbRegistered: initializationData.budgetState.sharedDbUrl != "none",
    onActionSelected: (action) async {
      if (action.startsWith("new?")) {
        final catId = int.tryParse(action.substring(4));
        logger.debug("New expense for category: $catId", tag: "quickActions");
        showExpenseDialog(
          context: navigatorKey.currentContext!,
          category: initializationData.budgetState.categories.where((c) => c.categoryId == catId).first.category,
          categoryId: catId,
          accountId: initializationData.budgetState.filterBudget,
          bankAccounts: initializationData.budgetState.bankAccounts,
          bankAccoutCount: initializationData.budgetState.bankAccounts.length,
          allowCamera: initializationData.budgetState.proStatusIsSet(mobileOnly: true)
        );
      } else {
        switch (action) {
          case 'sync':
            logger.debug("Sync to remote", tag: "quickActions");
            initializationData.budgetState.syncSharedDb(manual: true);
            break;
          case 'open_budget':
            logger.debug("Open app", tag: "quickActions");
            await windowManager.ensureInitialized();
            await windowManager.show();
            await windowManager.focus();
            break;
          case 'exit':
            trayManager.destroy();
            exit(0);
          default:
            logger.warning("Unknown action: $action", tag: "quickActions");
        }
      }
    }
  );
  logger.info("Initialization of quick actions finished", tag: "quickActions");
  
  UriHandler().setupListener(initializationData.budgetState, initializationData.designState);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    if (!kDebugMode || !takeScreenshots && Platform.isWindows) {
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BudgetState>.value(
              value: initializationData.budgetState,
            ),
            ChangeNotifierProvider<DesignState>.value(
              value: initializationData.designState,
            ),
          ],
          child: HouseholdBudgetApp(lockApp: initializationData.budgetState.lockApp),
        )
      );
    } else {
      runApp(
        ScreenshotManager()
          .wrapWithScreenshot(
            child: MultiProvider(
            providers: [
              ChangeNotifierProvider<BudgetState>.value(
                value: initializationData.budgetState,
              ),
              ChangeNotifierProvider<DesignState>.value(
                value: initializationData.designState,
              ),
            ],
            child: HouseholdBudgetApp(lockApp: initializationData.budgetState.lockApp),
          ),
        )
      );
    }
  });
}

class HouseholdBudgetApp extends StatefulWidget {
  final bool lockApp;

  const HouseholdBudgetApp({super.key, required this.lockApp});

  @override
  State<HouseholdBudgetApp> createState() => _HouseholdBudgetAppState();
}


class _HouseholdBudgetAppState extends State<HouseholdBudgetApp> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _authenticate(widget.lockApp);
  }

  Future<void> _authenticate(bool authRequired) async {
    try {
      bool supported = await auth.isDeviceSupported();
      bool biometricAvailable = await auth.canCheckBiometrics;
      final isBiometricAvailable = (biometricAvailable || supported) && authRequired;

      if (isBiometricAvailable) {
        _isAuthenticated = await auth.authenticate(
          localizedReason: I18n.translate("authRequired"),
          options: const AuthenticationOptions(
            useErrorDialogs: true,
            stickyAuth: true,
          ),
        );
      } else {
        _isAuthenticated = true;
      }
      setState(() {});
    } catch (e) {
      Logger().warning("User authentication failed: $e", tag: "auth");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text( I18n.translate("authFailed", placeholders: {'error': e.toString()}))),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetState = Provider.of<BudgetState>(context);
    final designState = Provider.of<DesignState>(context);
    
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: I18n.translate("appTitle"),
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: I18n.getLocales(),
      home: budgetState.isSetupComplete ?
        (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS) ?
        AppWithOptionalBackground(background: (designState.appBackgroundSolid) ? null : AppBackground(imagePath: designState.customBackgroundPath, gradientOption: designState.appBackground, blur: designState.customBackgroundBlur, blurIntensity: designState.blurIntensity,), child: const DesktopHomeScreen())
        :
        (_isAuthenticated) ?
        AppWithOptionalBackground(background: (designState.appBackgroundSolid) ? null : AppBackground(imagePath: designState.customBackgroundPath, gradientOption: designState.appBackground, blur: designState.customBackgroundBlur, blurIntensity: designState.blurIntensity,), child: const HomeScreen())
        :
        AdaptiveAlertDialog(
          title: Text(I18n.translate("authRequired")),
          content: Text(I18n.translate("authTextApp", placeholders: {"appName": I18n.translate("appTitle")})),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(I18n.translate("cancel")),
            ),
          ],
        )
        :
        const AppSetupScreen(),
    );
  }
}

class AppWithOptionalBackground extends StatelessWidget {
  final Widget child;
  final Widget? background;

  const AppWithOptionalBackground({
    super.key,
    required this.child,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (background != null) background!,
        Positioned.fill(child: child),
      ],
    );
  }
}
