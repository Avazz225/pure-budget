import 'package:flutter/material.dart';
import 'dart:math';

import 'package:jne_household_app/i18n/i18n.dart';
import 'package:jne_household_app/models/design_state.dart';
import 'package:provider/provider.dart';

class BudgetArcWidget extends StatefulWidget {
  final double totalBudget;
  final double totalSpent;
  final String currency;
  final List<double> categorySpent;
  final List<Color> segmentColors;
  final bool showText;
  final bool isVertical;

  const BudgetArcWidget({
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
    final designState = Provider.of<DesignState>(context);
    double arcWidth = MediaQuery.of(context).size.width * designState.arcWidth;
    
    if (!widget.isVertical){
      if (arcWidth > 600) {
        arcWidth = 600;
      }
      if (designState.arcPercent > 50.0) {
        designState.arcPercent = 50.0;
      }
      return Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: (designState.customBackgroundPath != "none") ? Theme.of(context).cardColor.withValues(alpha: .5) : null,
              borderRadius: const BorderRadius.all(Radius.circular(8))
            ),
            child: Text(
              I18n.translate("totalSpent", placeholders: {"actual": widget.totalSpent.toStringAsFixed(2), "planned": widget.totalBudget.toStringAsFixed(2), "currency": widget.currency.toString()}),
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: arcWidth,
            height: arcWidth * (designState.arcPercent / 100),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: BudgetArcPainter(
                    totalBudget: widget.totalBudget,
                    categorySpent: widget.categorySpent,
                    segmentColors: widget.segmentColors,
                    progress: _animation.value,
                    rounded: designState.arcSegmentsRounded,
                    arcPercent: designState.arcPercent / 100,
                    context: context,
                    coloredBg: designState.appBackgroundSolid
                  ),
                );
              },
            ),
          ),
        ],
      );
    } else {
      if (arcWidth > 400) {
        arcWidth = 400;
      }
      return Row(
        children: [
          SizedBox(
            width: arcWidth,
            height: arcWidth * (designState.arcPercent / 100),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: BudgetArcPainter(
                    totalBudget: widget.totalBudget,
                    categorySpent: widget.categorySpent,
                    segmentColors: widget.segmentColors,
                    progress: _animation.value,
                    rounded: designState.arcSegmentsRounded,
                    arcPercent: designState.arcPercent / 100,
                    context: context,
                    coloredBg: designState.appBackgroundSolid
                  ),
                );
              },
            ),
          ),
        ]
      );
    }
  }
}

class BudgetArcPainter extends CustomPainter {
  final double totalBudget;
  final List<double> categorySpent;
  final List<Color> segmentColors;
  final double progress;
  final Color baseColor;
  final bool rounded;
  final double arcPercent;
  final BuildContext context;
  final bool coloredBg;

  BudgetArcPainter({
    required this.totalBudget,
    required this.categorySpent,
    required this.segmentColors,
    required this.rounded,
    this.progress = 1.0,
    this.baseColor = Colors.grey,
    required this.arcPercent,
    required this.context,
    required this.coloredBg
  });

@override
void paint(Canvas canvas, Size size) {
  final shadowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 20.0
    ..color = (coloredBg)?Colors.black.withAlpha(25) : Theme.of(context).cardColor.withValues(alpha: .5)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

  final basePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 20.0
    ..strokeCap = (rounded) ? StrokeCap.round : StrokeCap.butt;

  final center = Offset(size.width / 2, size.width / 2);
  final radius = size.width / 2 - 20;

  final totalAngle = 2 * pi * arcPercent;

  final startAngle = -pi / 2 - totalAngle / 2  + ((rounded) ? 0.1 : 0);
  final maxAngle = totalAngle - ((rounded) ? 0.2 : 0);

  // Schatten
  canvas.drawArc(
    Rect.fromCircle(center: center, radius: radius),
    startAngle,
    maxAngle,
    false,
    shadowPaint,
  );

  // Basisbogen
  basePaint.color = baseColor.withOpacity(0.25);
  canvas.drawArc(
    Rect.fromCircle(center: center, radius: radius),
    startAngle,
    maxAngle,
    false,
    basePaint,
  );

  // Segmente zeichnen
  double totalSpent = categorySpent.fold(0, (sum, spent) => sum + spent);
  double base = max(totalBudget, totalSpent);

  double currentAngle = startAngle;
  for (int i = 0; i < categorySpent.length; i++) {
    double sweepAngle = (categorySpent[i] / base) * maxAngle * progress;
    basePaint.color = segmentColors[i % segmentColors.length];
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      currentAngle,
      sweepAngle,
      false,
      basePaint,
    );
    currentAngle += sweepAngle;
  }
}

  @override
  bool shouldRepaint(covariant BudgetArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.categorySpent != categorySpent;
  }
}
