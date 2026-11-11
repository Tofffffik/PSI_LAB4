import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'rates_repository.dart';

/// Настоящая сеть: GET с тайм-аутом 10 секунд.
Future<String> httpFetch(Uri uri) async {
  final response = await http.get(uri).timeout(const Duration(seconds: 10));
  if (response.statusCode != 200) {
    throw RatesException('Источник ответил ошибкой ${response.statusCode}.');
  }
  return response.body;
}

/// Хранилище на SharedPreferences — данные переживают перезапуск.
class PrefsStore implements KeyValueStore {
  @override
  Future<String?> read(String key) async {
    return (await SharedPreferences.getInstance()).getString(key);
  }

  @override
  Future<void> write(String key, String value) async {
    await (await SharedPreferences.getInstance()).setString(key, value);
  }
}
