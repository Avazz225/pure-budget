import 'package:flutter/material.dart';

class SolidColorPainter extends CustomPainter {
  final Color color;
  SolidColorPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}