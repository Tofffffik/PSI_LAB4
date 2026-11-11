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

/// Тема Material 3 из одного фирменного цвета; светлая и тёмная.
ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF3D5AFE), brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scheme.surface,
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class CurrencyApp extends StatelessWidget {
  const CurrencyApp({super.key, required this.repository});

  final RatesRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Курсы валют',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
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

  static const _titles = ['Конвертер', 'Неделя', 'Месяц'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Ключ с парой валют: при её смене вкладка создаётся заново и
    // перезагружает данные.
    final pair = '$_from-$_to';
    final body = switch (_tab) {
      0 => ConverterTab(key: ValueKey('c-$pair'), repository: widget.repository, from: _from, to: _to),
      1 => TrendTab(key: ValueKey('w-$pair'), repository: widget.repository, from: _from, to: _to, days: 7),
      _ => TrendTab(key: ValueKey('m-$pair'), repository: widget.repository, from: _from, to: _to, days: 30),
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Курсы валют',
                      style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
                  Text(_titles[_tab],
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _PairSelector(
                from: _from,
                to: _to,
                onFrom: (v) => setState(() => _from = v),
                onTo: (v) => setState(() => _to = v),
                onSwap: () => setState(() {
                  final from = _from;
                  _from = _to;
                  _to = from;
                }),
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
          NavigationDestination(
            icon: Icon(Icons.currency_exchange_outlined),
            selectedIcon: Icon(Icons.currency_exchange),
            label: 'Конвертер',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart),
            label: 'Неделя',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Месяц',
          ),
        ],
      ),
    );
  }
}

/// Выбор пары валют: два списка и круглая кнопка «поменять местами».
class _PairSelector extends StatelessWidget {
  const _PairSelector({
    required this.from,
    required this.to,
    required this.onFrom,
    required this.onTo,
    required this.onSwap,
  });

  final String from;
  final String to;
  final ValueChanged<String> onFrom;
  final ValueChanged<String> onTo;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(child: _box(context, 'Из', from, onFrom)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: IconButton.filledTonal(
                tooltip: 'Поменять местами',
                icon: const Icon(Icons.swap_horiz),
                onPressed: onSwap,
              ),
            ),
            Expanded(child: _box(context, 'В', to, onTo)),
          ],
        ),
      ),
    );
  }

  Widget _box(BuildContext context, String label, String value, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      key: ValueKey('$label-$value'),
      decoration: InputDecoration(labelText: label),
      borderRadius: BorderRadius.circular(14),
      items: [
        for (final code in currencies)
          DropdownMenuItem(
            value: code,
            child: Text(code, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
      ],
      onChanged: (code) {
        if (code != null) onChanged(code);
      },
    );
  }
}
