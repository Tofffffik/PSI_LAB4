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

        final theme = Theme.of(context);
        final sign = stats.change > 0 ? '+' : '';
        final trendColor = _trendColor(context, stats.trend);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CacheBanner(result: data),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.from} → ${widget.to} · последние ${widget.days} дней',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.points.last.rate.toStringAsFixed(4),
                      style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    _TrendPill(trend: stats.trend, color: trendColor),
                    const SizedBox(height: 16),
                    SizedBox(height: 190, child: RateChart(points: data.points, color: trendColor)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.3,
              children: [
                _StatTile(icon: Icons.south, label: 'Минимум', value: stats.min.toStringAsFixed(4)),
                _StatTile(icon: Icons.north, label: 'Максимум', value: stats.max.toStringAsFixed(4)),
                _StatTile(icon: Icons.functions, label: 'Среднее', value: stats.average.toStringAsFixed(4)),
                _StatTile(
                  icon: Icons.data_usage,
                  label: 'Точек данных',
                  value: '${data.points.length}',
                ),
                _StatTile(
                  icon: Icons.swap_vert,
                  label: 'Изменение',
                  value: '$sign${stats.change.toStringAsFixed(4)}',
                  valueColor: trendColor,
                ),
                _StatTile(
                  icon: Icons.percent,
                  label: 'Изменение, %',
                  value: '$sign${stats.changePercent.toStringAsFixed(2)} %',
                  valueColor: trendColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            InfoLine(
              icon: Icons.event,
              text: 'Период: ${formatDate(data.points.first.date)} – ${formatDate(data.points.last.date)} '
                  '(курс публикуется по рабочим дням)',
            ),
            const InfoLine(icon: Icons.account_balance, text: 'Источник: $sourceName'),
          ],
        );
      },
    );
  }

  static Color _trendColor(BuildContext context, Trend trend) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (trend) {
      Trend.up => dark ? const Color(0xFF6EE7A0) : const Color(0xFF15803D),
      Trend.down => dark ? const Color(0xFFFF8A8A) : const Color(0xFFC62828),
      Trend.flat => Theme.of(context).colorScheme.onSurfaceVariant,
    };
  }
}

/// Явное указание тенденции: значок и слово.
class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.trend, required this.color});

  final Trend trend;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final (icon, text) = switch (trend) {
      Trend.up => (Icons.trending_up, 'Рост'),
      Trend.down => (Icons.trending_down, 'Падение'),
      Trend.flat => (Icons.trending_flat, 'Без изменений'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text('Тенденция: $text', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value, this.valueColor});

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: valueColor),
            ),
          ],
        ),
      ),
    );
  }
}
