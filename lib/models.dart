/// Курс валютной пары на одну дату.
class RatePoint {
  const RatePoint(this.date, this.rate);

  final DateTime date;
  final double rate;
}

/// Направление изменения курса за период.
enum Trend { up, down, flat }

/// Статистика для экранов сравнения.
class Stats {
  const Stats({
    required this.min,
    required this.max,
    required this.average,
    required this.change,
    required this.changePercent,
    required this.trend,
  });

  final double min;
  final double max;
  final double average;

  /// Последнее значение минус первое, в единицах курса.
  final double change;
  final double changePercent;
  final Trend trend;
}

/// Итог загрузки ряда курсов.
class SeriesResult {
  const SeriesResult({
    required this.points,
    required this.fromCache,
    required this.fetchedAt,
  });

  final List<RatePoint> points;

  /// true — сеть недоступна, показаны сохранённые данные.
  final bool fromCache;

  /// Когда данные были получены от источника.
  final DateTime fetchedAt;
}

/// Ошибка с готовым текстом для пользователя.
class RatesException implements Exception {
  const RatesException(this.message);

  final String message;

  @override
  String toString() => message;
}
