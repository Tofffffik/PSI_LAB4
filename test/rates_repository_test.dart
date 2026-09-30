import 'dart:io';

import 'package:currency_trends/models.dart';
import 'package:currency_trends/rates_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryStore implements KeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

const okBody = '{"rates":{"2026-09-28":{"EUR":0.87889},"2026-09-29":{"EUR":0.88067}}}';

void main() {
  final now = DateTime(2026, 9, 30, 12, 0);
  late MemoryStore store;
  late List<Uri> requests;

  RatesRepository repository(Future<String> Function() respond, {DateTime? at}) {
    return RatesRepository(
      fetch: (uri) {
        requests.add(uri);
        return respond();
      },
      store: store,
      now: () => at ?? now,
    );
  }

  setUp(() {
    store = MemoryStore();
    requests = [];
  });

  test('запрашивает период и возвращает свежие данные', () async {
    final result = await repository(() async => okBody).loadSeries('USD', 'EUR', 7);

    expect(requests.single.toString(),
        'https://api.frankfurter.dev/v1/2026-09-23..2026-09-30?base=USD&symbols=EUR');
    expect(result.fromCache, isFalse);
    expect(result.fetchedAt, now);
    expect(result.points.map((p) => p.rate), [0.87889, 0.88067]);
  });

  test('отбрасывает точки раньше начала периода', () async {
    const body = '{"rates":{"2026-09-18":{"EUR":0.87},"2026-09-29":{"EUR":0.88}}}';

    final result = await repository(() async => body).loadSeries('USD', 'EUR', 7);

    expect(result.points.single.rate, 0.88);
  });

  test('без сети отдаёт сохранённые данные с датой их получения', () async {
    await repository(() async => okBody).loadSeries('USD', 'EUR', 7);

    // «Перезапуск»: новый репозиторий, то же хранилище, сеть недоступна.
    final later = DateTime(2026, 10, 2, 9, 30);
    final result = await repository(
      () async => throw const SocketException('нет сети'),
      at: later,
    ).loadSeries('USD', 'EUR', 7);

    expect(result.fromCache, isTrue);
    expect(result.fetchedAt, now);
    expect(result.points.map((p) => p.rate), [0.87889, 0.88067]);
  });

  test('без сети и без кэша — понятная ошибка', () async {
    final load = repository(() async => throw const SocketException('нет сети')).loadSeries('USD', 'EUR', 7);

    await expectLater(
      load,
      throwsA(isA<RatesException>().having((e) => e.message, 'message', contains('подключение'))),
    );
  });

  test('пустой ответ источника — ошибка «нет данных»', () async {
    final load = repository(() async => '{"rates":{}}').loadSeries('USD', 'EUR', 7);

    await expectLater(
      load,
      throwsA(isA<RatesException>().having((e) => e.message, 'message', contains('не вернул данных'))),
    );
  });

  test('некорректный ответ источника — ошибка «некорректные данные»', () async {
    final load = repository(() async => '<html>oops</html>').loadSeries('USD', 'EUR', 7);

    await expectLater(
      load,
      throwsA(isA<RatesException>().having((e) => e.message, 'message', contains('некорректные'))),
    );
  });

  test('некорректный ответ не затирает кэш и кэш используется', () async {
    await repository(() async => okBody).loadSeries('USD', 'EUR', 7);

    final result = await repository(() async => 'garbage').loadSeries('USD', 'EUR', 7);

    expect(result.fromCache, isTrue);
    expect(result.points.length, 2);
  });

  test('кэш раздельный для недели и месяца и для разных пар', () async {
    await repository(() async => okBody).loadSeries('USD', 'EUR', 7);
    Future<String> offline() async => throw const SocketException('нет сети');

    expect(repository(offline).loadSeries('USD', 'EUR', 30), throwsA(isA<RatesException>()));
    expect(repository(offline).loadSeries('USD', 'GBP', 7), throwsA(isA<RatesException>()));
  });

  test('повреждённый кэш считается отсутствующим', () async {
    store.values['series_USD_EUR_7'] = '{broken';

    final load = repository(() async => throw const SocketException('нет сети')).loadSeries('USD', 'EUR', 7);

    await expectLater(load, throwsA(isA<RatesException>()));
  });

  test('одинаковые валюты: курс 1 без обращения к сети', () async {
    final result = await repository(() async => fail('сеть не нужна')).loadSeries('USD', 'USD', 7);

    expect(requests, isEmpty);
    expect(result.points.length, 8);
    expect(result.points.every((p) => p.rate == 1), isTrue);
    expect(result.fromCache, isFalse);
  });
}
