// main.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jne_household_app/logger.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/screens_desktop/desktop_home_screen.dart';
import 'package:jne_household_app/screens_shared/introduction.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:jne_household_app/screens_mobile/mobile_home_screen.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/services/initialization_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // initialize logger
  final logger = Logger();
  await logger.init(minLevel: (kDebugMode) ? LogLevel.debug : LogLevel.error);

  // initialize app
  final initializationData = await InitializationService.initializeApp();
  logger.info("Initialization finished", tag: "init");

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(
      ChangeNotifierProvider(
        create: (context) => initializationData.budgetState,
        child: HouseholdBudgetApp(lockApp: initializationData.budgetState.lockApp),
      ),
    );
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
    
    return MaterialApp(
      title: I18n.translate("appTitle"),
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: I18n.getLocales(),
      home: budgetState.isSetupComplete ?
        (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS) ?
        const DesktopHomeScreen()
        :
        (_isAuthenticated) ?
        const HomeScreen() 
        :
        AlertDialog(
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
