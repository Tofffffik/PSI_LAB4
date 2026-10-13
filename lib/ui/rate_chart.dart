import 'package:flutter/material.dart';

import '../models.dart';
import 'common.dart';

/// Линейный график курса во времени с градиентной заливкой под линией.
class RateChart extends StatelessWidget {
  const RateChart({super.key, required this.points, required this.color});

  final List<RatePoint> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _ChartPainter(points, color, scheme.outlineVariant, scheme.onSurfaceVariant, scheme.surfaceContainerLow),
      child: const SizedBox.expand(),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.points, this.lineColor, this.gridColor, this.textColor, this.background);

  final List<RatePoint> points;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;
  final Color background;

  static const double _left = 56;
  static const double _bottom = 22;
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

    // Три горизонтальные линии сетки: максимум, середина, минимум.
    final grid = Paint()
      ..color = gridColor.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = plot.top + plot.height * i / 2;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
    }

    Offset place(int index) {
      final x = points.length == 1
          ? plot.center.dx
          : plot.left + plot.width * index / (points.length - 1);
      final y = plot.bottom - plot.height * (points[index].rate - min) / (max - min);
      return Offset(x, y);
    }

    final line = Path()..moveTo(place(0).dx, place(0).dy);
    for (var i = 1; i < points.length; i++) {
      line.lineTo(place(i).dx, place(i).dy);
    }

    final area = Path.from(line)
      ..lineTo(place(points.length - 1).dx, plot.bottom)
      ..lineTo(place(0).dx, plot.bottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lineColor.withValues(alpha: 0.35), lineColor.withValues(alpha: 0.0)],
        ).createShader(plot),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Последняя точка — выделенный кружок.
    final last = place(points.length - 1);
    canvas.drawCircle(last, 6, Paint()..color = background);
    canvas.drawCircle(last, 4.5, Paint()..color = lineColor);

    _label(canvas, max.toStringAsFixed(4), Offset(0, plot.top - 7));
    _label(canvas, ((max + min) / 2).toStringAsFixed(4), Offset(0, plot.center.dy - 7));
    _label(canvas, min.toStringAsFixed(4), Offset(0, plot.bottom - 7));
    _label(canvas, formatDate(points.first.date), Offset(plot.left, plot.bottom + 6));
    final lastDate = formatDate(points.last.date);
    _label(canvas, lastDate, Offset(plot.right - _measure(lastDate).width, plot.bottom + 6));
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
  bool shouldRepaint(_ChartPainter old) =>
      old.points != points || old.lineColor != lineColor || old.background != background;
}
