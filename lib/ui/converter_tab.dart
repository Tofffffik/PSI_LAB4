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
        _result = (amount.value! * latest.rate).toStringAsFixed(2);
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
        final theme = Theme.of(context);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CacheBanner(result: data),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: theme.textTheme.headlineSmall,
              decoration: InputDecoration(
                labelText: 'Сумма',
                hintText: '0',
                suffixText: widget.from,
                errorText: _error,
              ),
              // Изменение ввода скрывает старый результат и ошибку.
              onChanged: (_) => setState(() {
                _error = null;
                _result = null;
              }),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              // Кнопка неактивна, пока сумма не введена.
              onPressed: _amount.text.trim().isEmpty ? null : () => _convert(latest),
              icon: const Icon(Icons.currency_exchange),
              label: const Text('Конвертировать'),
            ),
            const SizedBox(height: 16),
            _ResultCard(
              amount: _result == null ? null : _amount.text.trim(),
              result: _result,
              from: widget.from,
              to: widget.to,
              rate: latest.rate,
            ),
            const SizedBox(height: 12),
            InfoLine(icon: Icons.event, text: 'Курс на ${formatDate(latest.date)}'),
            const InfoLine(icon: Icons.account_balance, text: 'Источник: $sourceName'),
          ],
        );
      },
    );
  }
}

/// Крупная карточка с результатом и курсом за единицу.
class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.amount,
    required this.result,
    required this.from,
    required this.to,
    required this.rate,
  });

  final String? amount;
  final String? result;
  final String from;
  final String to;
  final double rate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result == null ? 'Введите сумму' : '$amount $from =',
              style: TextStyle(color: scheme.onPrimaryContainer.withValues(alpha: 0.75)),
            ),
            const SizedBox(height: 4),
            Text(
              result == null ? '—' : '$result $to',
              style: theme.textTheme.displaySmall?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.onPrimaryContainer.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '1 $from = ${rate.toStringAsFixed(4)} $to',
                style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
