import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:jne_household_app/models/budget_state.dart';
import 'package:jne_household_app/models/design_state.dart';
import 'package:provider/provider.dart';

/// Whether the Pro-only `liquidGlassMode` design option is active and should
/// currently have a visible effect (the app background must be translucent —
/// a blur over a solid background would be pointless).
bool _liquidGlassActive(BuildContext context, {bool requireTranslucentBackground = true}) {
  final designState = Provider.of<DesignState>(context);
  final budgetState = Provider.of<BudgetState>(context, listen: false);
  return designState.liquidGlassMode
      && budgetState.proStatusIsSet(simplePro: true)
      && (!requireTranslucentBackground || !designState.appBackgroundSolid);
}

/// Whether [GlassCard] currently renders its glass look (Pro + enabled).
/// Callers that add their own translucency/blur on top of a [GlassCard]
/// should check this and skip it — stacking multiple [BackdropFilter]s
/// compounds into a washed-out, overly bright result.
bool glassCardActive(BuildContext context) {
  final designState = Provider.of<DesignState>(context);
  final budgetState = Provider.of<BudgetState>(context, listen: false);
  return designState.liquidGlassMode && budgetState.proStatusIsSet(simplePro: true);
}

/// Wraps [child] in a backdrop blur when "liquid glass" mode is active,
/// otherwise returns [child] unchanged. Useful for navigation chrome
/// (app bars, bottom navigation bars) that sits on a translucent background.
Widget glassBlurWrap(BuildContext context, Widget child, {double borderRadius = 0}) {
  if (!_liquidGlassActive(context)) return child;

  return ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: child,
    ),
  );
}

/// Wraps [child] in a translucent, blurred "liquid glass" surface.
/// Building block for the Pro-only `liquidGlassMode` design option.
///
/// If [tint] is given, the glass is coloured with it (e.g. a category colour)
/// instead of the neutral white — "tinted glass" look.
Widget glassSurface(
  BuildContext context, {
  required Widget child,
  double borderRadius = 16,
  Color? tint,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Container(
        decoration: BoxDecoration(
          color: tint?.withValues(alpha: .22) ?? Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: tint?.withValues(alpha: .4) ?? Colors.white.withValues(alpha: 0.25)),
        ),
        child: child,
      ),
    ),
  );
}

/// `flexibleSpace` for an [AppBar] that adds a "liquid glass" blur behind the
/// translucent app bar background — only when `liquidGlassMode` is enabled
/// (Pro) and the app background isn't solid (otherwise there's nothing to blur).
Widget? glassAppBarFlexibleSpace(BuildContext context) {
  if (!_liquidGlassActive(context)) return null;

  return ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Container(color: Colors.transparent),
    ),
  );
}

/// Drop-in replacement for [Card] that renders as a [glassSurface] when the
/// user has enabled the Pro-only `liquidGlassMode` design option, and falls
/// back to a regular [Card] otherwise.
class GlassCard extends StatelessWidget {
  final Widget child;
  final double? elevation;
  final EdgeInsetsGeometry? margin;
  final ShapeBorder? shape;
  final Color? color;
  final Color? tint;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.elevation,
    this.margin,
    this.shape,
    this.color,
    this.tint,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final designState = Provider.of<DesignState>(context);
    final budgetState = Provider.of<BudgetState>(context, listen: false);
    final useGlass = designState.liquidGlassMode && budgetState.proStatusIsSet(simplePro: true);
    // Cards don't depend on the app background being translucent — they get
    // their glass look from being placed over whatever surface they sit on.

    if (!useGlass) {
      return Card(elevation: elevation, margin: margin, shape: shape, color: color, child: child);
    }

    return Container(
      // Match Card's default margin (EdgeInsets.all(4.0)) so spacing to
      // neighbouring tiles and the screen edge stays identical to non-glass mode.
      margin: margin ?? const EdgeInsets.all(4),
      child: glassSurface(context, borderRadius: borderRadius, tint: tint, child: child),
    );
  }
}
