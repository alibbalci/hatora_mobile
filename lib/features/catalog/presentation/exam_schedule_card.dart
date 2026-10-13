import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/widget/components.dart';

class ExamScheduleCard extends ConsumerWidget {
  const ExamScheduleCard({
    super.key,
    required this.examId,
    required this.editionId,
  });
  final String examId, editionId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = examScheduleProvider((
      examId: examId,
      editionId: editionId,
    ));
    return ref
        .watch(provider)
        .when(
          loading: () => const LoadingView(label: 'Sınav takvimi yükleniyor…'),
          error: (error, _) =>
              ErrorView(error: error, onRetry: () => ref.invalidate(provider)),
          data: (sessions) => sessions.isEmpty
              ? const SizedBox.shrink()
              : Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sınav takvimi',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        for (final session in sessions)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.event_outlined, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(session.name),
                                      Text(
                                        examDateLabel(session.examDate, estimatedDate: session.estimatedDate),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
        );
  }
}
