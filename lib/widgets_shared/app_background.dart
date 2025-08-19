import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/background_gradients.dart';

class AppBackground extends StatelessWidget {
  final String? imagePath;
  final int? gradientOption;
  final bool blur;
  final double blurIntensity;

  const AppBackground({
    super.key,
    this.imagePath,
    this.gradientOption,
    this.blur = false,
    this.blurIntensity = 1.0
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.brightnessOf(context) == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: (gradientOption! < gradients.length) ? gradients[gradientOption!].withOpacity((isDark) ? .5 : 1) : null,
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
