import 'package:flutter/material.dart';

import 'package:jne_household_app/i18n/i18n.dart';

class BudgetLineWidget extends StatefulWidget {
  final double totalBudget;
  final double totalSpent;
  final String currency;
  final List<double> categorySpent;
  final List<Color> segmentColors;

  const BudgetLineWidget({
    super.key,
    required this.totalBudget,
    required this.totalSpent,
    required this.currency,
    required this.categorySpent,
    required this.segmentColors,
  });

  @override
  _BudgetLineWidgetState createState() => _BudgetLineWidgetState();
}

class _BudgetLineWidgetState extends State<BudgetLineWidget>
    with SingleTickerProviderStateMixin {
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
    return Column(
      children: [
        Text(
          I18n.translate("totalSpent", placeholders: {
            "actual": widget.totalSpent.toStringAsFixed(2),
            "planned": widget.totalBudget.toStringAsFixed(2),
            "currency": widget.currency.toString()
          }),
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: BudgetLinePainter(
                  totalBudget: widget.totalBudget,
                  categorySpent: widget.categorySpent,
                  segmentColors: widget.segmentColors,
                  progress: _animation.value,
                ),
                size: const Size(double.infinity, 20),
              );
            },
          ),
        ),
      ],
    );
  }
}

class BudgetLinePainter extends CustomPainter {
  final double totalBudget;
  final List<double> categorySpent;
  final List<Color> segmentColors;
  final double progress;
  final Color baseColor;

  BudgetLinePainter({
    required this.totalBudget,
    required this.categorySpent,
    required this.segmentColors,
    this.progress = 1.0,
    this.baseColor = Colors.grey,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint basePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = baseColor.withOpacity(0.25);

    final Paint segmentPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round; // Abgerundete Enden

    // Zeichne die Basislinie mit abgerundeten Enden
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 0, size.width, size.height),
        topLeft: const Radius.circular(10),
        topRight: const Radius.circular(10),
        bottomLeft: const Radius.circular(10),
        bottomRight: const Radius.circular(10),
      ),
      basePaint,
    );

    // Berechnung der Segmente
    double totalSpent = categorySpent.fold(0, (sum, spent) => sum + spent);
    double base = totalBudget > totalSpent ? totalBudget : totalSpent;
    double startX = 0;

    for (int i = 0; i < categorySpent.length; i++) {
      double segmentWidth = (categorySpent[i] / base) * size.width * progress;
      segmentPaint.color = segmentColors[i % segmentColors.length];
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(startX, 0, segmentWidth, size.height),
          topLeft: Radius.circular(i == 0 ? 10 : 0), // Rundung nur am Anfang
          bottomLeft: Radius.circular(i == 0 ? 10 : 0),
          topRight: Radius.circular(i == categorySpent.length - 1 ? 10 : 0), // Rundung nur am Ende
          bottomRight: Radius.circular(i == categorySpent.length - 1 ? 10 : 0),
        ),
        segmentPaint,
      );
      startX += segmentWidth;
    }
  }

  @override
  bool shouldRepaint(covariant BudgetLinePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.categorySpent != categorySpent;
  }
}
