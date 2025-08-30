import 'package:flutter/material.dart';

Color getTextColor(Color backgroundColor, int tileStyle, {dynamic context}) {
  if (tileStyle == 0) {
    double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  } else {
    return (MediaQuery.of(context!).platformBrightness == Brightness.light) ? Colors.black : Colors.white;
  }
}