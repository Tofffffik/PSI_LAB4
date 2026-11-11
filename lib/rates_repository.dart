import 'dart:convert';

import 'models.dart';
import 'rates_parser.dart';

/// Загружает тело ответа по адресу. Бросает исключение при любой неудаче.
typedef Fetcher = Future<String> Function(Uri uri);

/// Локальное хранилище строк, переживающее перезапуск приложения.
abstract class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

const String sourceName = 'Frankfurter (курсы ЕЦБ)';

/// Ряды курсов: сначала сеть, при неудаче — последний сохранённый ответ.
class RatesRepository {
  RatesRepository({required this.fetch, required this.store, DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final Fetcher fetch;
  final KeyValueStore store;
  final DateTime Function() _now;

  static Uri seriesUri(String from, String to, DateTime start, DateTime end) {
    return Uri.parse(
      'https://api.frankfurter.dev/v1/${_day(start)}..${_day(end)}?base=$from&symbols=$to',
    );
  }

  /// Курс пары за последние [days] дней.
  Future<SeriesResult> loadSeries(String from, String to, int days) async {
    final now = _now();
    final end = DateTime(now.year, now.month, now.day);
    final start = end.subtract(Duration(days: days));

    // Одинаковые валюты: курс всегда 1, сеть не нужна.
    if (from == to) {
      return SeriesResult(
        points: [for (var i = days; i >= 0; i--) RatePoint(end.subtract(Duration(days: i)), 1)],
        fromCache: false,
        fetchedAt: now,
      );
    }

    final key = 'series_${from}_${to}_$days';
    try {
      final body = await fetch(seriesUri(from, to, start, end));
      // Источник может добавить предыдущий рабочий день — он вне периода.
      final points = parseSeries(body, to).where((p) => !p.date.isBefore(start)).toList();
      if (points.isEmpty) {
        throw const RatesException('Источник не вернул данных за период.');
      }

      await _save(key, points, now);
      return SeriesResult(points: points, fromCache: false, fetchedAt: now);
    } catch (error) {
      final cached = await _readCache(key);
      if (cached != null) {
        return cached;
      }
      throw RatesException(_describe(error));
    }
  }

  static String _describe(Object error) {
    if (error is RatesException) {
      return error.message;
    }
    if (error is FormatException) {
      return 'Источник вернул некорректные данные.';
    }
    return 'Не удалось получить курсы. Проверьте подключение к интернету.';
  }

  Future<void> _save(String key, List<RatePoint> points, DateTime fetchedAt) async {
    try {
      await store.write(
        key,
        jsonEncode({
          'fetchedAt': fetchedAt.toIso8601String(),
          'points': [
            for (final p in points) {'d': _day(p.date), 'r': p.rate},
          ],
        }),
      );
    } catch (_) {
      // Сбой записи кэша не должен мешать показать свежие данные.
    }
  }

  /// null — сохранённых данных нет или они повреждены.
  Future<SeriesResult?> _readCache(String key) async {
    try {
      final raw = await store.read(key);
      if (raw == null) {
        return null;
      }

      final json = jsonDecode(raw) as Map<String, dynamic>;
      final points = [
        for (final item in json['points'] as List<dynamic>)
          RatePoint(DateTime.parse(item['d'] as String), (item['r'] as num).toDouble()),
      ];
      if (points.isEmpty) {
        return null;
      }

      return SeriesResult(
        points: points,
        fromCache: true,
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  static String _day(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }
}
