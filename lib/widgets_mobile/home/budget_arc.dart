import 'package:flutter/material.dart';
import 'dart:math';

import 'package:jne_household_app/i18n/i18n.dart';

class BudgetArcWidget extends StatefulWidget {
  final double totalBudget;
  final double totalSpent;
  final String currency;
  final List<double> categorySpent;
  final List<Color> segmentColors;

  const BudgetArcWidget({
    super.key,
    required this.totalBudget,
    required this.totalSpent,
    required this.currency,
    required this.categorySpent,
    required this.segmentColors,
  });

  @override
  _BudgetArcWidgetState createState() => _BudgetArcWidgetState();
}

class _BudgetArcWidgetState extends State<BudgetArcWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double arcWidth = MediaQuery.of(context).size.width * 0.8;
    return Column(
      children: [
        Text(
          I18n.translate("totalSpent", placeholders: {"actual": widget.totalSpent.toStringAsFixed(2), "planned": widget.totalBudget.toStringAsFixed(2), "currency": widget.currency.toString()}),
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: arcWidth,
          height: arcWidth / 2,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: BudgetArcPainter(
                  totalBudget: widget.totalBudget,
                  categorySpent: widget.categorySpent,
                  segmentColors: widget.segmentColors,
                  progress: _animation.value,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class BudgetArcPainter extends CustomPainter {
  final double totalBudget;
  final List<double> categorySpent;
  final List<Color> segmentColors;
  final double progress;
  final Color baseColor;

  BudgetArcPainter({
    required this.totalBudget,
    required this.categorySpent,
    required this.segmentColors,
    this.progress = 1.0,
    this.baseColor = Colors.grey,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20.0
      ..color = Colors.black.withOpacity(0.1) // Schattenfarbe
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10); // Weicher Schatten

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20.0
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 20;

    double startAngle = pi + 0.1;
    double maxAngle = pi - 0.2;

    // Schatten für den Hintergrundbogen
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      maxAngle,
      false,
      shadowPaint,
    );

    // Basisbogen zeichnen
    basePaint.color = baseColor.withOpacity(0.25);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      maxAngle,
      false,
      basePaint,
    );

    // Berechnung für Segmente
    double totalSpent = categorySpent.fold(0, (sum, spent) => sum + spent);
    double base = max(totalBudget, totalSpent);

    for (int i = 0; i < categorySpent.length; i++) {
      double sweepAngle = (categorySpent[i] / base) * maxAngle * progress;
      basePaint.color = segmentColors[i % segmentColors.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        basePaint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant BudgetArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.categorySpent != categorySpent;
  }
}
