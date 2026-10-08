import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../insights_provider.dart';

class InsightsCard extends ConsumerWidget {
  const InsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(insightsProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Nhận xét chi tiêu', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            insights.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              ),
              error: (error, _) => Text('Chưa tải được nhận xét: $error'),
              data: (items) => items.isEmpty
                  ? Text(
                      'Chưa có đủ dữ liệu để đưa ra nhận xét.',
                      style: theme.textTheme.bodyMedium,
                    )
                  : Column(
                      children: [
                        for (final insight in items)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  size: 18,
                                  color: theme.colorScheme.tertiary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(insight)),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
