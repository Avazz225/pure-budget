import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:jne_household_app/helper/background_gradients.dart';

class AppBackground extends StatelessWidget {
  final String? imagePath;
  final int? gradientOption;
  final bool blur;

  const AppBackground({
    super.key,
    this.imagePath,
    this.gradientOption,
    this.blur = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: (gradientOption! < gradients.length) ? gradients[gradientOption!] : null,
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
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
      ]
    );
  }
}
