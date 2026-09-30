import 'package:flutter/material.dart';

import '../models.dart';
import 'common.dart';

/// Линейный график курса во времени.
class RateChart extends StatelessWidget {
  const RateChart({super.key, required this.points});

  final List<RatePoint> points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _ChartPainter(points, scheme.primary, scheme.outlineVariant, scheme.onSurfaceVariant),
      child: const SizedBox.expand(),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.points, this.lineColor, this.gridColor, this.textColor);

  final List<RatePoint> points;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;

  static const double _left = 56;
  static const double _bottom = 20;
  static const double _top = 8;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    var min = points.first.rate;
    var max = points.first.rate;
    for (final point in points) {
      if (point.rate < min) min = point.rate;
      if (point.rate > max) max = point.rate;
    }
    // Ровная линия: даём диапазон, чтобы она прошла посередине.
    if (max - min < 1e-12) {
      min -= 1;
      max += 1;
    }

    final plot = Rect.fromLTRB(_left, _top, size.width - 4, size.height - _bottom);
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    canvas.drawLine(plot.topLeft, plot.topRight, grid);
    canvas.drawLine(plot.bottomLeft, plot.bottomRight, grid);

    Offset place(int index) {
      final x = points.length == 1
          ? plot.center.dx
          : plot.left + plot.width * index / (points.length - 1);
      final y = plot.bottom - plot.height * (points[index].rate - min) / (max - min);
      return Offset(x, y);
    }

    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(place(0).dx, place(0).dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(place(i).dx, place(i).dy);
    }
    canvas.drawPath(path, line);

    final dot = Paint()..color = lineColor;
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(place(i), 3, dot);
    }

    _label(canvas, max.toStringAsFixed(4), Offset(0, plot.top - 6));
    _label(canvas, min.toStringAsFixed(4), Offset(0, plot.bottom - 8));
    _label(canvas, formatDate(points.first.date), Offset(plot.left, plot.bottom + 4));
    final last = formatDate(points.last.date);
    _label(canvas, last, Offset(plot.right - _measure(last).width, plot.bottom + 4));
  }

  TextPainter _measure(String text) {
    return TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: textColor, fontSize: 11)),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  void _label(Canvas canvas, String text, Offset offset) {
    _measure(text).paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.points != points || old.lineColor != lineColor;
}
