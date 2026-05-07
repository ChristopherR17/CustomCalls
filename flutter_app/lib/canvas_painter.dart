import 'package:flutter/rendering.dart';
import 'drawable.dart';

class CanvasPainter extends CustomPainter {
  final List<Drawable> drawables;

  CanvasPainter({required this.drawables});

  @override
  void paint(Canvas canvas, Size size) {
    for (final drawable in drawables) {
      drawable.draw(canvas);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
