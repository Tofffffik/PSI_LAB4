import 'package:currency_trends/models.dart';
import 'package:currency_trends/stats.dart';
import 'package:flutter_test/flutter_test.dart';

List<RatePoint> series(List<double> rates) {
  return [for (var i = 0; i < rates.length; i++) RatePoint(DateTime(2026, 9, 1 + i), rates[i])];
}

void main() {
  group('computeStats', () {
    test('пустой набор данных — null', () {
      expect(computeStats([]), isNull);
    });

    test('минимум, максимум и среднее', () {
      final stats = computeStats(series([10, 12, 8, 14]))!;

      expect(stats.min, 8);
      expect(stats.max, 14);
      expect(stats.average, 11);
    });

    test('рост: изменение и процент считаются от первого значения', () {
      final stats = computeStats(series([10, 9, 12]))!;

      expect(stats.change, closeTo(2, 1e-9));
      expect(stats.changePercent, closeTo(20, 1e-9));
      expect(stats.trend, Trend.up);
    });

    test('падение: отрицательные изменение и процент', () {
      final stats = computeStats(series([20, 25, 15]))!;

      expect(stats.change, closeTo(-5, 1e-9));
      expect(stats.changePercent, closeTo(-25, 1e-9));
      expect(stats.trend, Trend.down);
    });

    test('первое и последнее значения равны — без изменений', () {
      final stats = computeStats(series([1.5, 1.7, 1.2, 1.5]))!;

      expect(stats.change, 0);
      expect(stats.changePercent, 0);
      expect(stats.trend, Trend.flat);
      expect(stats.min, 1.2);
      expect(stats.max, 1.7);
    });

    test('одна точка: все показатели равны ей, изменений нет', () {
      final stats = computeStats(series([0.88]))!;

      expect(stats.min, 0.88);
      expect(stats.max, 0.88);
      expect(stats.average, 0.88);
      expect(stats.change, 0);
      expect(stats.trend, Trend.flat);
    });

    test('первое значение ноль — процент равен нулю, а не бесконечности', () {
      final stats = computeStats(series([0, 5]))!;

      expect(stats.changePercent, 0);
      expect(stats.trend, Trend.up);
    });
  });
}
