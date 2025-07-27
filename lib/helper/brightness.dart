import 'package:flutter/material.dart';

Color getTextColor(Color backgroundColor) {
  double luminance = backgroundColor.computeLuminance();
  return luminance > 0.5 ? Colors.black : Colors.white;
}