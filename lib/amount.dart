/// Результат проверки введённой суммы: либо значение, либо текст ошибки.
class AmountResult {
  const AmountResult.valid(double this.value) : error = null;
  const AmountResult.invalid(String this.error) : value = null;

  final double? value;
  final String? error;

  bool get isValid => error == null;
}

const double maxAmount = 1000000000000;

final RegExp _number = RegExp(r'^-?[0-9]+([.,][0-9]+)?$');

/// Допустима положительная сумма, разделитель дробной части — точка или
/// запятая. Пусто, буквы, ноль и отрицательные числа — ошибка.
AmountResult validateAmount(String? text) {
  final trimmed = (text ?? '').trim();
  if (trimmed.isEmpty) {
    return const AmountResult.invalid('Введите сумму.');
  }
  if (!_number.hasMatch(trimmed)) {
    return const AmountResult.invalid('Сумма должна быть числом, например 100 или 99,50.');
  }

  final value = double.parse(trimmed.replaceAll(',', '.'));
  if (value <= 0) {
    return const AmountResult.invalid('Сумма должна быть больше нуля.');
  }
  if (value > maxAmount) {
    return const AmountResult.invalid('Сумма слишком большая.');
  }
  return AmountResult.valid(value);
}
