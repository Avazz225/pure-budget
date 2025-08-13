import 'dart:ui';
import 'package:flutter/material.dart';

Widget glassButton(
  BuildContext context, 
  VoidCallback onPressed, 
  {
    String? label,
    IconData? icon,
    Widget? customWidget,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
              Icon(icon, size: 20, color: Theme.of(context).iconTheme.color),
              if (customWidget != null)
              customWidget,
              if (icon != null && label != null)
              const SizedBox(width: 8),
              if (label != null)
              Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget flatButton(
  BuildContext context, 
  VoidCallback onPressed, 
  {
    String? label,
    IconData? icon,
    Widget? customWidget,
  }
) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.transparent, // transparent oder z.B. Theme.of(context).colorScheme.surface
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, size: 20, color: Theme.of(context).iconTheme.color),
            if (customWidget != null)
              customWidget,
            if (icon != null && label != null)
              const SizedBox(width: 8),
            if (label != null)
              Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
          ],
        ),
      ),
    ),
  );
}