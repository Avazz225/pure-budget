import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

Widget stackedIcons (double size, double modifier, IconData first, IconData second, bool firstLeading, Color color) {
  return SizedBox(
    height: size,
    width: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Icon(
              (firstLeading) ? first : second,
              size: size * modifier,
              color: color,
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Icon(
              (firstLeading) ? second : first,
              size: size * (1 - (modifier / 2)),
              color: color.withAlpha(150),
            ),
          ),
        ),
      ],
    ),
  );
}