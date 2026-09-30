import 'models.dart';

/// Изменение меньше этого порога считается отсутствием изменений.
const double flatThreshold = 1e-9;

/// Минимум, максимум, среднее и изменение за период.
/// Для пустого набора данных возвращает null.
Stats? computeStats(List<RatePoint> points) {
  if (points.isEmpty) {
    return null;
  }

  var min = points.first.rate;
  var max = points.first.rate;
  var sum = 0.0;
  for (final point in points) {
    if (point.rate < min) min = point.rate;
    if (point.rate > max) max = point.rate;
    sum += point.rate;
  }

  final first = points.first.rate;
  final change = points.last.rate - first;
  final Trend trend;
  if (change.abs() < flatThreshold) {
    trend = Trend.flat;
  } else {
    trend = change > 0 ? Trend.up : Trend.down;
  }

  return Stats(
    min: min,
    max: max,
    average: sum / points.length,
    change: change,
    changePercent: first == 0 ? 0 : change / first * 100,
    trend: trend,
  );
}
