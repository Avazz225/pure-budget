import 'dart:ui';
import 'package:flutter/material.dart';

Widget glassButton(
  BuildContext context, 
  VoidCallback onPressed, 
  {
    String? label,
    IconData? icon,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              if (icon != null)
              Icon(icon, size: 20, color: Theme.of(context).iconTheme.color),
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