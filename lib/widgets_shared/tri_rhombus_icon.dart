import 'package:flutter/material.dart';

/// Icon aus 3 gewölbten Rauten (konkave Kanten).
class TriRhombusIcon extends StatelessWidget {
  final List<Color> colors;   // colors
  final double size;          // total size
  final double concavity;     // 0..1 (0 = straight, 1 = kokave)
  final double gap;           // rhombus spacing
  final double rotation;      // rotation in deg

  const TriRhombusIcon({
    super.key,
    required this.colors,
    this.size = 96,
    this.concavity = 0.25,
    this.gap = 6,
    this.rotation = 0,
  }) : assert(colors.length == 3, 'colors needs exactly 3 values');

    @override
    Widget build(BuildContext context) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _TriRhombusPainter(
            colors: colors,
            concavity: concavity.clamp(0.0, 1.0),
            gap: gap,
            rotationRad: rotation * 3.141592653589793 / 180.0,
          ),
        ),
      );
    }
}

class _TriRhombusPainter extends CustomPainter {
  final List<Color> colors;
  final double concavity; // 0..1
  final double gap;
  final double rotationRad;

  _TriRhombusPainter({
    required this.colors,
    required this.concavity,
    required this.gap,
    required this.rotationRad,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationRad);
    canvas.translate(-center.dx, -center.dy);

    final single = size.shortestSide * 0.42;

    final top    = center + const Offset(0, -1) * (single + gap) * 0.75;
    final bl     = center + const Offset(-1.5, 0.5) * (single + gap) * 0.75;
    final br     = center + const Offset( 1.5, 0.5) * (single + gap) * 0.75;

    // Zeichenreihenfolge (unten zuerst für leichte Überlappung)
    _drawDiamond(canvas, Rect.fromCenter(center: bl, width: single-1, height: single-1), colors[1]);
    _drawDiamond(canvas, Rect.fromCenter(center: br, width: single+1, height: single+1), colors[2]);
    _drawDiamond(canvas, Rect.fromCenter(center: top, width: single, height: single), colors[0]);

    canvas.restore();
  }

  void _drawDiamond(Canvas canvas, Rect rect, Color color) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path  = _concaveDiamond(rect, concavity);
    canvas.drawPath(path, paint);
  }

  /// Baut eine Raute mit konkaven Seiten:
  /// Wir verbinden jeweils die Eckpunkte N->E->S->W->N
  /// und ziehen die Kontrollpunkte in Richtung Zentrum (concavity steuert die Stärke).
  Path _concaveDiamond(Rect r, double t) {
    final c  = r.center;
    final hw = r.width  / 2;
    final hh = r.height / 2;

    final n = Offset(c.dx,      c.dy - hh);
    final e = Offset(c.dx + hw, c.dy);
    final s = Offset(c.dx,      c.dy + hh);
    final w = Offset(c.dx - hw, c.dy);

    Offset ctrl(Offset a, Offset b) {
      final mid = Offset((a.dx + b.dx)/2, (a.dy + b.dy)/2);
      // Kontrollpunkt Richtung Zentrum verschieben (konkav)
      return Offset.lerp(mid, c, t) ?? mid;
    }

    final path = Path()..moveTo(n.dx, n.dy);
    path.quadraticBezierTo(ctrl(n, e).dx, ctrl(n, e).dy, e.dx, e.dy);
    path.quadraticBezierTo(ctrl(e, s).dx, ctrl(e, s).dy, s.dx, s.dy);
    path.quadraticBezierTo(ctrl(s, w).dx, ctrl(s, w).dy, w.dx, w.dy);
    path.quadraticBezierTo(ctrl(w, n).dx, ctrl(w, n).dy, n.dx, n.dy);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _TriRhombusPainter old) {
    return old.colors != colors ||
          old.concavity != concavity ||
          old.gap != gap ||
          old.rotationRad != rotationRad;
  }
}
