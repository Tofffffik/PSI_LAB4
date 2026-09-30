import 'dart:convert';

import 'models.dart';

/// Разбирает ответ Frankfurter с рядом курсов:
/// `{"rates": {"2026-09-29": {"EUR": 0.88067}, ...}}`.
///
/// Возвращает точки по возрастанию даты. Пустой `rates` — пустой список.
/// Записи без нужной валюты или с некорректным значением пропускаются.
/// Некорректный документ — [FormatException].
List<RatePoint> parseSeries(String body, String symbol) {
  final Object? json = jsonDecode(body);
  if (json is! Map<String, dynamic>) {
    throw const FormatException('Ответ не является объектом JSON');
  }

  final rates = json['rates'];
  if (rates is! Map<String, dynamic>) {
    throw const FormatException('В ответе нет поля rates');
  }

  final points = <RatePoint>[];
  rates.forEach((day, values) {
    final date = DateTime.tryParse(day);
    final value = values is Map<String, dynamic> ? values[symbol] : null;
    if (date != null && value is num && value > 0) {
      points.add(RatePoint(date, value.toDouble()));
    }
  });

  points.sort((a, b) => a.date.compareTo(b.date));
  return points;
}
