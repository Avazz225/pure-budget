import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/background_gradients.dart';

class AppBackground extends StatelessWidget {
  final String? imagePath;
  final int? gradientOption;
  final bool blur;
  final double blurIntensity;
  final Map<String, dynamic> customGradient;

  const AppBackground({
    super.key,
    this.imagePath,
    this.gradientOption,
    this.blur = false,
    this.blurIntensity = 1.0,
    required this.customGradient
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.brightnessOf(context) == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: (gradientOption != -1) ? (gradientOption! < gradients.length) ? gradients[gradientOption!].withOpacity((isDark) ? .5 : 1) : null : gradientBuilder(customGradient),
            image: imagePath != "none"
                ? DecorationImage(
                    image: FileImage(File(imagePath!)),
                    fit: BoxFit.cover,
                  )
                : null,
          )
        ),
        if (blur)
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurIntensity, sigmaY: blurIntensity),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
      ]
    );
  }
}

dynamic gradientBuilder(Map<String, dynamic> customGradient) {
  int type = customGradient["type"] ?? 0;
  List<Color> colors = customGradient["colors"] ?? [Colors.blue, Colors.purple];

  List<dynamic> conf = switch (type) {
    0 => [Alignment.centerLeft, Alignment.centerRight],
    1 => [Alignment.topLeft, Alignment.bottomRight],
    2 => [Alignment.topCenter, Alignment.bottomCenter],
    3 => [Alignment.topRight, Alignment.bottomLeft],
    4 => [0.125],
    5 => [0.375],
    6 => [0.625],
    7 => [0.875],
    8 => [0.95],
    int() => [Alignment.topLeft, Alignment.bottomRight],
  };

  switch (type) {
    case <4:
      return LinearGradient(
        colors: colors,
        begin: conf[0],
        end: conf[1]
      );
    case <9:
      return RadialGradient(
        colors: colors,
        radius: conf[0],
        focalRadius: 2.0 
      );
  }
}