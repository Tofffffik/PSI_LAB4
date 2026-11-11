import 'package:flutter/material.dart';

import '../models.dart';
import '../rates_repository.dart';
import '../stats.dart';
import 'common.dart';
import 'rate_chart.dart';

/// Экран сравнения за период: график, минимум, максимум, среднее,
/// изменение и тенденция.
class TrendTab extends StatefulWidget {
  const TrendTab({
    super.key,
    required this.repository,
    required this.from,
    required this.to,
    required this.days,
  });

  final RatesRepository repository;
  final String from;
  final String to;
  final int days;

  @override
  State<TrendTab> createState() => _TrendTabState();
}

class _TrendTabState extends State<TrendTab> {
  late Future<SeriesResult> _series;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _series = widget.repository.loadSeries(widget.from, widget.to, widget.days);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SeriesResult>(
      future: _series,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorView(message: '${snapshot.error}', onRetry: () => setState(_load));
        }

        final data = snapshot.data!;
        final stats = computeStats(data.points);
        if (stats == null) {
          return const Center(child: Text('За период нет данных.'));
        }

        final sign = stats.change > 0 ? '+' : '';
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CacheBanner(result: data),
            Text(
              '${widget.from} → ${widget.to}, последние ${widget.days} дней',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(height: 200, child: RateChart(points: data.points)),
            const SizedBox(height: 16),
            _TrendCard(trend: stats.trend),
            _row('Минимум', stats.min.toStringAsFixed(4)),
            _row('Максимум', stats.max.toStringAsFixed(4)),
            _row('Среднее', stats.average.toStringAsFixed(4)),
            _row('Изменение', '$sign${stats.change.toStringAsFixed(4)}'),
            _row('Изменение, %', '$sign${stats.changePercent.toStringAsFixed(2)} %'),
            const SizedBox(height: 12),
            Text(
              'Точек: ${data.points.length} (курс публикуется по рабочим дням) · '
              'Источник: $sourceName',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.trend});

  final Trend trend;

  @override
  Widget build(BuildContext context) {
    final (icon, text, color) = switch (trend) {
      Trend.up => (Icons.trending_up, 'Тенденция: рост', Colors.green.shade700),
      Trend.down => (Icons.trending_down, 'Тенденция: падение', Colors.red.shade700),
      Trend.flat => (Icons.trending_flat, 'Тенденция: без изменений', Colors.grey.shade700),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
