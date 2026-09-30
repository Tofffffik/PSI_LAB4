import 'package:flutter/material.dart';

import '../models.dart';

String formatDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}.${two(date.month)}.${date.year}';
}

String formatDateTime(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${formatDate(date)} ${two(date.hour)}:${two(date.minute)}';
}

/// Полоса «нет сети, данные из кэша» с датой актуальности.
class CacheBanner extends StatelessWidget {
  const CacheBanner({super.key, required this.result});

  final SeriesResult result;

  @override
  Widget build(BuildContext context) {
    if (!result.fromCache) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Нет связи с источником. Показаны сохранённые данные '
        'от ${formatDateTime(result.fetchedAt)}.',
        style: const TextStyle(color: Colors.black87),
      ),
    );
  }
}

/// Сообщение об ошибке с кнопкой повтора.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            const Text('Сохранённых данных для этой пары нет.', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
