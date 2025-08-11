import 'package:flutter/material.dart';

import 'package:jne_household_app/i18n/i18n.dart';

class BudgetLineWidget extends StatefulWidget {
  final double totalBudget;
  final double totalSpent;
  final String currency;
  final List<double> categorySpent;
  final List<Color> segmentColors;
  final bool showText;
  final bool isVertical;

  const BudgetLineWidget({
    super.key,
    required this.totalBudget,
    required this.totalSpent,
    required this.currency,
    required this.categorySpent,
    required this.segmentColors,
    required this.showText,
    required this.isVertical
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
    if (!widget.isVertical){
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
                    isVertical: widget.isVertical
                  ),
                  size: const Size(double.infinity, 20),
                );
              },
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: BudgetLinePainter(
                    totalBudget: widget.totalBudget,
                    categorySpent: widget.categorySpent,
                    segmentColors: widget.segmentColors,
                    progress: _animation.value,
                    isVertical: widget.isVertical
                  ),
                  size: const Size(20, double.infinity),
                );
              },
            ),
          ),
        ]
      );
    }
  }
}

class BudgetLinePainter extends CustomPainter {
  final double totalBudget;
  final List<double> categorySpent;
  final List<Color> segmentColors;
  final double progress;
  final Color baseColor;
  final bool isVertical;

  BudgetLinePainter({
    required this.totalBudget,
    required this.categorySpent,
    required this.segmentColors,
    this.progress = 1.0,
    this.baseColor = Colors.grey,
    required this.isVertical
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint basePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = baseColor.withOpacity(0.25);

    final Paint segmentPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    // Basislinie zeichnen mit abgerundeten Ecken
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

    if (!isVertical) {
      double startX = 0;

      // Finde Index des letzten Segments mit Ausgaben > 0
      int lastNonZeroIndex = categorySpent.lastIndexWhere((spent) => spent > 0);

      for (int i = 0; i < categorySpent.length; i++) {
        double segmentWidth = (categorySpent[i] / base) * size.width * progress;
        if (segmentWidth <= 0) continue; // Segment mit 0 Breite überspringen

        segmentPaint.color = segmentColors[i % segmentColors.length];
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(startX, 0, segmentWidth, size.height),
            topLeft: Radius.circular(i == 0 ? 10 : 0), // Rundung links nur beim ersten Segment
            bottomLeft: Radius.circular(i == 0 ? 10 : 0),
            topRight: Radius.circular(i == lastNonZeroIndex ? 10 : 0), // Rundung rechts nur beim letzten nicht-null Segment
            bottomRight: Radius.circular(i == lastNonZeroIndex ? 10 : 0),
          ),
          segmentPaint,
        );
        startX += segmentWidth;
      }
    } else {
      double startY = size.height;
      int lastNonZeroIndex =
          categorySpent.lastIndexWhere((spent) => spent > 0);

      for (int i = 0; i < categorySpent.length; i++) {
        double segmentHeight =
            (categorySpent[i] / base) * size.height * progress;
        if (segmentHeight <= 0) continue;

        segmentPaint.color = segmentColors[i % segmentColors.length];
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(
                0, startY - segmentHeight, size.width, segmentHeight),
            topLeft: Radius.circular(i == lastNonZeroIndex ? 10 : 0),
            topRight: Radius.circular(i == lastNonZeroIndex ? 10 : 0),
            bottomLeft: Radius.circular(i == 0 ? 10 : 0),
            bottomRight: Radius.circular(i == 0 ? 10 : 0),
          ),
          segmentPaint,
        );
        startY -= segmentHeight;
      }
    }
  }

  @override
  bool shouldRepaint(covariant BudgetLinePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.categorySpent != categorySpent ||
        oldDelegate.isVertical != isVertical;
  }
}
