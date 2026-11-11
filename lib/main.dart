import 'package:flutter/material.dart';

import 'platform_io.dart';
import 'rates_repository.dart';
import 'ui/converter_tab.dart';
import 'ui/trend_tab.dart';

void main() {
  runApp(CurrencyApp(repository: RatesRepository(fetch: httpFetch, store: PrefsStore())));
}

/// Валюты, которые публикует ЕЦБ и отдаёт Frankfurter.
const List<String> currencies = [
  'USD', 'EUR', 'GBP', 'CHF', 'JPY', 'RON', 'PLN', 'CZK', 'SEK', 'NOK', 'TRY', 'CNY', 'CAD', 'AUD',
];

class CurrencyApp extends StatelessWidget {
  const CurrencyApp({super.key, required this.repository});

  final RatesRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Курсы валют',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: HomePage(repository: repository),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.repository});

  final RatesRepository repository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _from = 'USD';
  String _to = 'EUR';
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    // Ключ с парой валют: при её смене вкладка создаётся заново и
    // перезагружает данные.
    final pair = '$_from-$_to';
    final body = switch (_tab) {
      0 => ConverterTab(key: ValueKey('c-$pair'), repository: widget.repository, from: _from, to: _to),
      1 => TrendTab(key: ValueKey('w-$pair'), repository: widget.repository, from: _from, to: _to, days: 7),
      _ => TrendTab(key: ValueKey('m-$pair'), repository: widget.repository, from: _from, to: _to, days: 30),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Курсы валют')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(child: _currencyBox('Из', _from, (v) => setState(() => _from = v))),
                  IconButton(
                    tooltip: 'Поменять местами',
                    icon: const Icon(Icons.swap_horiz),
                    onPressed: () => setState(() {
                      final from = _from;
                      _from = _to;
                      _to = from;
                    }),
                  ),
                  Expanded(child: _currencyBox('В', _to, (v) => setState(() => _to = v))),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.currency_exchange), label: 'Конвертер'),
          NavigationDestination(icon: Icon(Icons.view_week), label: 'Неделя'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Месяц'),
        ],
      ),
    );
  }

  Widget _currencyBox(String label, String value, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      key: ValueKey('$label-$value'),
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: [for (final code in currencies) DropdownMenuItem(value: code, child: Text(code))],
      onChanged: (code) {
        if (code != null) onChanged(code);
      },
    );
  }
}
