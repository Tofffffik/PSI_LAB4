import 'package:flutter/material.dart';

import '../amount.dart';
import '../models.dart';
import '../rates_repository.dart';
import 'common.dart';

/// Экран конвертации: сумма, результат, дата курса и источник.
class ConverterTab extends StatefulWidget {
  const ConverterTab({super.key, required this.repository, required this.from, required this.to});

  final RatesRepository repository;
  final String from;
  final String to;

  @override
  State<ConverterTab> createState() => _ConverterTabState();
}

class _ConverterTabState extends State<ConverterTab> {
  final _amount = TextEditingController();
  late Future<SeriesResult> _rates;
  String? _error;
  String? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  // Последняя точка недельного ряда — актуальный курс.
  void _load() {
    _rates = widget.repository.loadSeries(widget.from, widget.to, 7);
  }

  void _convert(RatePoint latest) {
    final amount = validateAmount(_amount.text);
    setState(() {
      if (amount.isValid) {
        _error = null;
        _result = '${_amount.text.trim()} ${widget.from} = '
            '${(amount.value! * latest.rate).toStringAsFixed(2)} ${widget.to}';
      } else {
        _error = amount.error;
        _result = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SeriesResult>(
      future: _rates,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorView(message: '${snapshot.error}', onRetry: () => setState(_load));
        }

        final data = snapshot.data!;
        final latest = data.points.last;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CacheBanner(result: data),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Сумма',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
              // Изменение ввода скрывает старый результат и ошибку.
              onChanged: (_) => setState(() {
                _error = null;
                _result = null;
              }),
            ),
            const SizedBox(height: 12),
            FilledButton(
              // Кнопка неактивна, пока сумма не введена.
              onPressed: _amount.text.trim().isEmpty ? null : () => _convert(latest),
              child: const Text('Конвертировать'),
            ),
            const SizedBox(height: 20),
            if (_result != null)
              Text(_result!, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text('1 ${widget.from} = ${latest.rate.toStringAsFixed(4)} ${widget.to}'),
            Text('Курс на ${formatDate(latest.date)} · Источник: $sourceName'),
          ],
        );
      },
    );
  }
}
