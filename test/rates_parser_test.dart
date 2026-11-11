import 'package:currency_trends/rates_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseSeries', () {
    test('читает точки и сортирует их по дате', () {
      const body = '{"amount":1.0,"base":"USD","start_date":"2026-09-25","end_date":"2026-09-29",'
          '"rates":{"2026-09-29":{"EUR":0.88067},"2026-09-25":{"EUR":0.87696},"2026-09-28":{"EUR":0.87889}}}';

      final points = parseSeries(body, 'EUR');

      expect(points.map((p) => p.rate), [0.87696, 0.87889, 0.88067]);
      expect(points.first.date, DateTime(2026, 9, 25));
      expect(points.last.date, DateTime(2026, 9, 29));
    });

    test('целое значение курса превращается в double', () {
      final points = parseSeries('{"rates":{"2026-09-29":{"JPY":150}}}', 'JPY');

      expect(points.single.rate, 150.0);
    });

    test('пустой rates — пустой список', () {
      expect(parseSeries('{"rates":{}}', 'EUR'), isEmpty);
    });

    test('записи без нужной валюты и с плохими значениями пропускаются', () {
      const body = '{"rates":{'
          '"2026-09-25":{"GBP":0.75},'
          '"2026-09-26":{"EUR":"abc"},'
          '"2026-09-27":{"EUR":0},'
          '"2026-09-28":{"EUR":-1.5},'
          '"not a date":{"EUR":0.9},'
          '"2026-09-29":{"EUR":0.88}}}';

      final points = parseSeries(body, 'EUR');

      expect(points.length, 1);
      expect(points.single.rate, 0.88);
    });

    test('не JSON — FormatException', () {
      expect(() => parseSeries('<html>Service unavailable</html>', 'EUR'), throwsFormatException);
      expect(() => parseSeries('', 'EUR'), throwsFormatException);
    });

    test('JSON без rates или не объект — FormatException', () {
      expect(() => parseSeries('{"message":"not found"}', 'EUR'), throwsFormatException);
      expect(() => parseSeries('[1,2,3]', 'EUR'), throwsFormatException);
      expect(() => parseSeries('{"rates":[]}', 'EUR'), throwsFormatException);
    });
  });
}
