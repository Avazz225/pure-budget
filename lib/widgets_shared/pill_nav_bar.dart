import 'package:flutter/material.dart';
import 'package:jne_household_app/models/design_state.dart';
import 'package:jne_household_app/widgets_shared/glass_surface.dart';
import 'package:provider/provider.dart';

/// A floating, fully rounded ("pill shaped") navigation bar — the new default
/// `navBarStyle` look. Built on Material 3's [NavigationBar], which already
/// renders a pill-shaped ([StadiumBorder]) selection indicator behind the
/// active destination; this just floats it in a rounded translucent container
/// and (Pro + Liquid Glass) blurs whatever sits behind it via [glassBlurWrap].
Widget pillNavBar(
  BuildContext context, {
  required List<NavigationDestination> destinations,
  required int selectedIndex,
  required ValueChanged<int> onDestinationSelected,
}) {
  final designState = Provider.of<DesignState>(context);
  const radius = 32.0;

  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: glassBlurWrap(
        context,
        NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 64,
            backgroundColor: (designState.appBackgroundSolid) ? Theme.of(context).cardColor : Theme.of(context).cardColor.withValues(alpha: .4),
            indicatorShape: const StadiumBorder(),
            indicatorColor: Colors.transparent,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final color = states.contains(WidgetState.selected)
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: .55);
              return TextStyle(color: color, fontSize: 12);
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final color = states.contains(WidgetState.selected)
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: .55);
              return IconThemeData(color: color);
            }),
          ),
          child: NavigationBar(
            destinations: destinations,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          ),
        ),
        borderRadius: radius,
      ),
    ),
  );
}
