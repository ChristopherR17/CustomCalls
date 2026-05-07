import 'dart:math';
import 'package:flutter/material.dart';

abstract class Drawable {
  final String id;
  bool selected;

  Drawable({required this.id, this.selected = false});

  void draw(Canvas canvas);
  bool containsPoint(Offset point);
  void updateFromMap(Map<String, dynamic> values);
}

void drawSelectionBox(Canvas canvas, Rect rect) {
  final selectionPaint = Paint()
    ..color = Colors.blueAccent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  canvas.drawRect(rect.inflate(6), selectionPaint);
}

Color? parseDrawableColor(dynamic value) {
  if (value == null) return null;
  if (value is Color) return value;

  final text = value.toString().trim().toLowerCase();
  if (text.isEmpty || text == 'none' || text == 'null' || text == 'transparent') {
    return text == 'transparent' ? Colors.transparent : null;
  }

  const namedColors = {
    'black': Colors.black,
    'negro': Colors.black,
    'negre': Colors.black,
    'white': Colors.white,
    'blanco': Colors.white,
    'blanc': Colors.white,
    'red': Colors.red,
    'rojo': Colors.red,
    'vermell': Colors.red,
    'blue': Colors.blue,
    'azul': Colors.blue,
    'blau': Colors.blue,
    'green': Colors.green,
    'verde': Colors.green,
    'verd': Colors.green,
    'yellow': Colors.yellow,
    'amarillo': Colors.yellow,
    'groc': Colors.yellow,
    'orange': Colors.orange,
    'naranja': Colors.orange,
    'taronja': Colors.orange,
    'purple': Colors.purple,
    'morado': Colors.purple,
    'lila': Colors.purple,
    'pink': Colors.pink,
    'rosa': Colors.pink,
    'grey': Colors.grey,
    'gray': Colors.grey,
    'gris': Colors.grey,
    'brown': Colors.brown,
    'marron': Colors.brown,
    'marró': Colors.brown,
    'cyan': Colors.cyan,
  };

  if (namedColors.containsKey(text)) return namedColors[text];

  var hex = text.replaceAll('#', '').replaceAll('0x', '');
  if (hex.length == 6) hex = 'ff$hex';
  if (hex.length == 8) {
    final intValue = int.tryParse(hex, radix: 16);
    if (intValue != null) return Color(intValue);
  }

  return null;
}

double? parseDrawableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().replaceAll(',', '.'));
}

class Line extends Drawable {
  Offset start;
  Offset end;
  Color color;
  double strokeWidth;

  Line({
    required super.id,
    required this.start,
    required this.end,
    this.color = Colors.black,
    this.strokeWidth = 2,
    super.selected,
  });

  @override
  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, end, paint);

    if (selected) {
      drawSelectionBox(canvas, Rect.fromPoints(start, end));
    }
  }

  @override
  bool containsPoint(Offset point) {
    final distanceToLine = _distancePointToSegment(point, start, end);
    return distanceToLine <= max(8, strokeWidth + 5);
  }

  double _distancePointToSegment(Offset p, Offset a, Offset b) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    if (dx == 0 && dy == 0) return (p - a).distance;

    final t = ((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / (dx * dx + dy * dy);
    final clampedT = t.clamp(0.0, 1.0);
    final projection = Offset(a.dx + clampedT * dx, a.dy + clampedT * dy);
    return (p - projection).distance;
  }

  @override
  void updateFromMap(Map<String, dynamic> values) {
    final startX = parseDrawableDouble(values['startX'] ?? values['x1']);
    final startY = parseDrawableDouble(values['startY'] ?? values['y1']);
    final endX = parseDrawableDouble(values['endX'] ?? values['x2']);
    final endY = parseDrawableDouble(values['endY'] ?? values['y2']);
    final newColor = parseDrawableColor(values['color'] ?? values['strokeColor']);
    final newStrokeWidth = parseDrawableDouble(values['strokeWidth'] ?? values['width']);

    if (startX != null) start = Offset(startX, start.dy);
    if (startY != null) start = Offset(start.dx, startY);
    if (endX != null) end = Offset(endX, end.dy);
    if (endY != null) end = Offset(end.dx, endY);
    if (newColor != null) color = newColor;
    if (newStrokeWidth != null) strokeWidth = max(1, newStrokeWidth);
  }
}

class RectangleShape extends Drawable {
  Offset topLeft;
  Offset bottomRight;
  Color strokeColor;
  Color? fillColor;
  double strokeWidth;
  Color? gradientStartColor;
  Color? gradientEndColor;

  RectangleShape({
    required super.id,
    required this.topLeft,
    required this.bottomRight,
    this.strokeColor = Colors.black,
    this.fillColor,
    this.strokeWidth = 2,
    this.gradientStartColor,
    this.gradientEndColor,
    super.selected,
  });

  Rect get rect => Rect.fromPoints(topLeft, bottomRight);

  @override
  void draw(Canvas canvas) {
    final currentRect = rect;

    if (gradientStartColor != null && gradientEndColor != null) {
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientStartColor!, gradientEndColor!],
        ).createShader(currentRect);
      canvas.drawRect(currentRect, fillPaint);
    } else if (fillColor != null) {
      final fillPaint = Paint()
        ..color = fillColor!
        ..style = PaintingStyle.fill;
      canvas.drawRect(currentRect, fillPaint);
    }

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRect(currentRect, strokePaint);

    if (selected) {
      drawSelectionBox(canvas, currentRect);
    }
  }

  @override
  bool containsPoint(Offset point) {
    return rect.inflate(max(6, strokeWidth)).contains(point);
  }

  @override
  void updateFromMap(Map<String, dynamic> values) {
    final topLeftX = parseDrawableDouble(values['topLeftX'] ?? values['x']);
    final topLeftY = parseDrawableDouble(values['topLeftY'] ?? values['y']);
    final bottomRightX = parseDrawableDouble(values['bottomRightX']);
    final bottomRightY = parseDrawableDouble(values['bottomRightY']);
    final width = parseDrawableDouble(values['width']);
    final height = parseDrawableDouble(values['height']);
    final newStroke = parseDrawableColor(values['strokeColor'] ?? values['borderColor'] ?? values['color']);
    final newFill = parseDrawableColor(values['fillColor']);
    final newStrokeWidth = parseDrawableDouble(values['strokeWidth']);
    final newGradientStart = parseDrawableColor(values['gradientStartColor'] ?? values['gradientStart']);
    final newGradientEnd = parseDrawableColor(values['gradientEndColor'] ?? values['gradientEnd']);

    if (topLeftX != null) topLeft = Offset(topLeftX, topLeft.dy);
    if (topLeftY != null) topLeft = Offset(topLeft.dx, topLeftY);
    if (bottomRightX != null) bottomRight = Offset(bottomRightX, bottomRight.dy);
    if (bottomRightY != null) bottomRight = Offset(bottomRight.dx, bottomRightY);
    if (width != null) bottomRight = Offset(topLeft.dx + width, bottomRight.dy);
    if (height != null) bottomRight = Offset(bottomRight.dx, topLeft.dy + height);
    if (newStroke != null) strokeColor = newStroke;
    if (newFill != null) fillColor = newFill;
    if (newStrokeWidth != null) strokeWidth = max(1, newStrokeWidth);
    if (newGradientStart != null) gradientStartColor = newGradientStart;
    if (newGradientEnd != null) gradientEndColor = newGradientEnd;
  }
}

class CircleShape extends Drawable {
  Offset center;
  double radius;
  Color strokeColor;
  Color? fillColor;
  double strokeWidth;

  CircleShape({
    required super.id,
    required this.center,
    required this.radius,
    this.strokeColor = Colors.black,
    this.fillColor,
    this.strokeWidth = 2,
    super.selected,
  });

  @override
  void draw(Canvas canvas) {
    if (fillColor != null) {
      final fillPaint = Paint()
        ..color = fillColor!
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, fillPaint);
    }

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, strokePaint);

    if (selected) {
      drawSelectionBox(canvas, Rect.fromCircle(center: center, radius: radius));
    }
  }

  @override
  bool containsPoint(Offset point) {
    return (point - center).distance <= radius + max(6, strokeWidth);
  }

  @override
  void updateFromMap(Map<String, dynamic> values) {
    final x = parseDrawableDouble(values['x'] ?? values['centerX']);
    final y = parseDrawableDouble(values['y'] ?? values['centerY']);
    final newRadius = parseDrawableDouble(values['radius']);
    final newStroke = parseDrawableColor(values['strokeColor'] ?? values['borderColor'] ?? values['color']);
    final newFill = parseDrawableColor(values['fillColor']);
    final newStrokeWidth = parseDrawableDouble(values['strokeWidth']);

    if (x != null) center = Offset(x, center.dy);
    if (y != null) center = Offset(center.dx, y);
    if (newRadius != null) radius = max(1, newRadius);
    if (newStroke != null) strokeColor = newStroke;
    if (newFill != null) fillColor = newFill;
    if (newStrokeWidth != null) strokeWidth = max(1, newStrokeWidth);
  }
}

class TextElement extends Drawable {
  String text;
  Offset position;
  Color color;
  double fontSize;
  bool bold;
  String? fontFamily;

  TextElement({
    required super.id,
    required this.text,
    required this.position,
    this.color = Colors.black,
    this.fontSize = 18,
    this.bold = false,
    this.fontFamily,
    super.selected,
  });

  Size _layoutText(Canvas canvas, {bool paint = false}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontFamily: fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    if (paint) textPainter.paint(canvas, position);
    return textPainter.size;
  }

  Rect get bounds {
    final estimatedWidth = text.length * fontSize * 0.62;
    return Rect.fromLTWH(position.dx, position.dy, estimatedWidth, fontSize * 1.3);
  }

  @override
  void draw(Canvas canvas) {
    final size = _layoutText(canvas, paint: true);
    if (selected) {
      drawSelectionBox(canvas, position & size);
    }
  }

  @override
  bool containsPoint(Offset point) {
    return bounds.inflate(8).contains(point);
  }

  @override
  void updateFromMap(Map<String, dynamic> values) {
    final newText = values['text'] ?? values['content'];
    final x = parseDrawableDouble(values['x']);
    final y = parseDrawableDouble(values['y']);
    final newColor = parseDrawableColor(values['color']);
    final newFontSize = parseDrawableDouble(values['fontSize'] ?? values['size']);
    final newBold = values['bold'];
    final newFontFamily = values['fontFamily'] ?? values['font'];

    if (newText != null) text = newText.toString();
    if (x != null) position = Offset(x, position.dy);
    if (y != null) position = Offset(position.dx, y);
    if (newColor != null) color = newColor;
    if (newFontSize != null) fontSize = max(6, newFontSize);
    if (newBold != null) bold = newBold == true || newBold.toString().toLowerCase() == 'true' || newBold.toString().toLowerCase() == 'bold';
    if (newFontFamily != null) fontFamily = newFontFamily.toString();
  }
}
