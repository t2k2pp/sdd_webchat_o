import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/usage_event.dart';
import 'providers/usage_report_providers.dart';

class UsageReportsPage extends ConsumerWidget {
  const UsageReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(usageEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usage Reports'),
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(usageReportRepositoryProvider).clear();
              ref.invalidate(usageEventsProvider);
            },
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: '履歴クリア',
          ),
        ],
      ),
      body: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return const Center(child: Text('利用履歴はまだありません。'));
          }
          final now = DateTime.now();
          final startDay = DateTime(now.year, now.month, now.day);
          final startMonth = DateTime(now.year, now.month, 1);
          final end = now.add(const Duration(days: 1));

          final daySummary = _aggregate(events, startDay, end);
          final monthSummary = _aggregate(events, startMonth, end);

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _PeriodSection(
                title:
                    'Today (${startDay.year}-${startDay.month.toString().padLeft(2, '0')}-${startDay.day.toString().padLeft(2, '0')})',
                summaries: daySummary,
              ),
              const SizedBox(height: 12),
              _PeriodSection(
                title:
                    'This Month (${startMonth.year}-${startMonth.month.toString().padLeft(2, '0')})',
                summaries: monthSummary,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('読み込み失敗: $error')),
      ),
    );
  }
}

class _PeriodSection extends StatelessWidget {
  const _PeriodSection({required this.title, required this.summaries});

  final String title;
  final List<_UsageSummary> summaries;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            if (summaries.isEmpty)
              const Text('データなし')
            else
              ...summaries.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.endpointName,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text('tokens in=${s.inputTokens}, out=${s.outputTokens}'),
                      Text(
                        'actual≈${s.currency} ${s.actualCost.toStringAsFixed(4)} / '
                        'ref≈${s.currency} ${s.referenceCost.toStringAsFixed(4)} / '
                        'saved≈${s.currency} ${s.savedCost.toStringAsFixed(4)}',
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

List<_UsageSummary> _aggregate(
  List<UsageEvent> events,
  DateTime from,
  DateTime to,
) {
  final map = <String, _UsageSummary>{};
  for (final e in events) {
    if (e.timestamp.isBefore(from) || !e.timestamp.isBefore(to)) {
      continue;
    }
    final key = '${e.endpointId}::${e.currency}';
    final base =
        map[key] ??
        _UsageSummary(
          endpointId: e.endpointId,
          endpointName: e.endpointName,
          currency: e.currency,
          inputTokens: 0,
          outputTokens: 0,
          actualCost: 0,
          referenceCost: 0,
          savedCost: 0,
        );
    map[key] = base.copyWith(
      inputTokens: base.inputTokens + e.inputTokens,
      outputTokens: base.outputTokens + e.outputTokens,
      actualCost: base.actualCost + e.actualCost,
      referenceCost: base.referenceCost + e.referenceCost,
      savedCost: base.savedCost + e.savedCost,
    );
  }
  final list = map.values.toList();
  list.sort((a, b) => b.actualCost.compareTo(a.actualCost));
  return list;
}

class _UsageSummary {
  const _UsageSummary({
    required this.endpointId,
    required this.endpointName,
    required this.currency,
    required this.inputTokens,
    required this.outputTokens,
    required this.actualCost,
    required this.referenceCost,
    required this.savedCost,
  });

  final String endpointId;
  final String endpointName;
  final String currency;
  final int inputTokens;
  final int outputTokens;
  final double actualCost;
  final double referenceCost;
  final double savedCost;

  _UsageSummary copyWith({
    String? endpointId,
    String? endpointName,
    String? currency,
    int? inputTokens,
    int? outputTokens,
    double? actualCost,
    double? referenceCost,
    double? savedCost,
  }) {
    return _UsageSummary(
      endpointId: endpointId ?? this.endpointId,
      endpointName: endpointName ?? this.endpointName,
      currency: currency ?? this.currency,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      actualCost: actualCost ?? this.actualCost,
      referenceCost: referenceCost ?? this.referenceCost,
      savedCost: savedCost ?? this.savedCost,
    );
  }
}
