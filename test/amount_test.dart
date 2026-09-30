import 'package:currency_trends/amount.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateAmount', () {
    for (final entry in {'100': 100.0, '99,50': 99.5, '99.50': 99.5, '  42  ': 42.0, '0,001': 0.001}.entries) {
      test('«${entry.key}» допустима', () {
        final result = validateAmount(entry.key);

        expect(result.isValid, isTrue);
        expect(result.value, entry.value);
        expect(result.error, isNull);
      });
    }

    for (final text in [null, '', '   ']) {
      test('пусто («$text») — просьба ввести сумму', () {
        final result = validateAmount(text);

        expect(result.isValid, isFalse);
        expect(result.error, 'Введите сумму.');
        expect(result.value, isNull);
      });
    }

    for (final text in ['abc', '12abc', '1 000', '1e5', '+5', '1.2.3', '.5', '5.', r'$100']) {
      test('«$text» — не число', () {
        expect(validateAmount(text).error, 'Сумма должна быть числом, например 100 или 99,50.');
      });
    }

    for (final text in ['0', '0,00', '-5', '-0,01']) {
      test('«$text» — не больше нуля', () {
        expect(validateAmount(text).error, 'Сумма должна быть больше нуля.');
      });
    }

    test('сумма выше максимума отклоняется', () {
      expect(validateAmount('1000000000001').error, 'Сумма слишком большая.');
      expect(validateAmount('1000000000000').isValid, isTrue);
    });
  });
}
