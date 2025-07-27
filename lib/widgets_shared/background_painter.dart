import 'package:flutter/material.dart';

class DynamicBackgroundScreen extends StatefulWidget {
  const DynamicBackgroundScreen({super.key});

  @override
  _DynamicBackgroundScreenState createState() => _DynamicBackgroundScreenState();
}

class _DynamicBackgroundScreenState extends State<DynamicBackgroundScreen> {
  late Brightness currentBrightness;

  @override
  void initState() {
    super.initState();
    currentBrightness = MediaQueryData.fromView(WidgetsBinding.instance.window).platformBrightness;
    WidgetsBinding.instance.addObserver(_PlatformBrightnessObserver(_onBrightnessChange));
  }

  void _onBrightnessChange(Brightness brightness) {
    setState(() {
      currentBrightness = brightness;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_PlatformBrightnessObserver(_onBrightnessChange));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomPaint(
        painter: BackgroundPainter(isDarkMode: currentBrightness == Brightness.dark, context: context),
        child: Center(
          child: Text(
            "Hello, Dynamic Background!",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final bool isDarkMode;
  final BuildContext context;

  BackgroundPainter({required this.isDarkMode, required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    // Hintergrundfarbe füllen
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Verlauf zeichnen
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        colors: isDarkMode ? [Colors.blue, Colors.purple] : [Colors.blue[400]!, Colors.purple[200]!],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.3)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.2,
        size.width,
        size.height * 0.3,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, gradientPaint);
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) {
    return oldDelegate.isDarkMode != isDarkMode;
  }
}

class _PlatformBrightnessObserver extends WidgetsBindingObserver {
  final void Function(Brightness) onBrightnessChange;

  _PlatformBrightnessObserver(this.onBrightnessChange);

  @override
  void didChangePlatformBrightness() {
    final brightness = WidgetsBinding.instance.window.platformBrightness;
    onBrightnessChange(brightness);
  }
}
