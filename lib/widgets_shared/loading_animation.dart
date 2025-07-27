import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

Widget loadingAnimation(Color dotColor) {
  return LoadingAnimationWidget.progressiveDots(color: dotColor, size: 25);
}