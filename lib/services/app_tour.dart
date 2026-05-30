import 'package:flutter/material.dart';
import 'package:jne_household_app/i18n/i18n.dart';
import 'package:showcaseview/showcaseview.dart';

/// Singleton that holds all GlobalKeys and triggers the in-app spotlight tour.
///
/// Usage:
///   1. Wrap the home screen with ShowCaseWidget.
///   2. Wrap individual widgets with Showcase(key: AppTour().keyXxx, ...).
///   3. Call AppTour().startTour(context) to launch the sequence.
class AppTour {
  static final AppTour _instance = AppTour._internal();
  factory AppTour() => _instance;
  AppTour._internal();

  // ── Keys for each tour step ────────────────────────────────────────────────
  final keyBudgetSummary  = GlobalKey();
  final keyBottomNavStats = GlobalKey();
  final keyBottomNavHome  = GlobalKey();
  final keySettingsMenu   = GlobalKey();

  /// Starts the full 4-step tour. Call after ShowCaseWidget is in the tree.
  void startTour(BuildContext context) {
    ShowCaseWidget.of(context).startShowCase([
      keyBudgetSummary,
      keyBottomNavHome,
      keyBottomNavStats,
      keySettingsMenu,
    ]);
  }

  /// Convenience wrapper — builds a Showcase around [child] with translated
  /// title and description, using sensible defaults.
  static Widget step({
    required GlobalKey stepKey,
    required String titleKey,
    required String descKey,
    required Widget child,
    TooltipPosition tooltipPosition = TooltipPosition.bottom,
  }) {
    return Builder(
      builder: (context) => Showcase(
        key: stepKey,
        title: I18n.translate(titleKey),
        description: I18n.translate(descKey),
        tooltipPosition: tooltipPosition,
        targetShapeBorder: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: child,
      ),
    );
  }
}
