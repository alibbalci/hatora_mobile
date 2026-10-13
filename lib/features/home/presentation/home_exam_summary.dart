import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/time/calendar_date.dart';
import '../../catalog/domain/exam_schedule.dart';
import '../../dashboard/domain/dashboard_models.dart';

String shortExamName(String name) =>
    name.replaceFirst(RegExp(r'\s*\([^)]*\)\s*$'), '').trim();

class HomeExamSummary extends ConsumerWidget {
  const HomeExamSummary({super.key, required this.exam});
  final DashboardActiveExam exam;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = examScheduleProvider((
      examId: exam.examId,
      editionId: exam.examEditionId,
    ));
    final schedule = ref.watch(provider);
    return HomeExamSummaryContent(
      exam: exam,
      sessions: schedule.asData?.value ?? const [],
      loading: schedule.isLoading,
      failed: schedule.hasError,
      onRetry: () => ref.invalidate(provider),
    );
  }
}

class HomeExamSummaryContent extends StatelessWidget {
  const HomeExamSummaryContent({
    super.key,
    required this.exam,
    this.sessions = const [],
    this.loading = false,
    this.failed = false,
    this.onRetry,
  });
  final DashboardActiveExam exam;
  final List<ExamSessionSchedule> sessions;
  final bool loading, failed;
  final VoidCallback? onRetry;

  String _date(ExamSessionSchedule session) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    final official = session.examDate;
    if (official != null) {
      return '${official.day} ${months[official.month - 1]} ${official.year}';
    }
    final estimated = session.estimatedDate;
    return estimated == null
        ? 'Yaklaşık ${exam.examYear}'
        : 'Yaklaşık ${months[estimated.month - 1]} ${estimated.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (isPastExam(exam.examDate, exam.examYear)) {
      return const SizedBox.shrink();
    }
    final visible = sessions
        .where((s) => !isPastExam(s.examDate, exam.examYear))
        .toList();
    final fallback = ExamSessionSchedule(
      code: '',
      name: '',
      examDate: exam.examDate,
    );
    final rows = visible.isEmpty ? [fallback] : visible;
    final unofficial =
        !loading && !failed && rows.any((s) => s.examDate == null);
    final days = exam.daysUntilExam;
    const weekdays = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
              decoration: BoxDecoration(
                color: days == null
                    ? AppColors.accentSoft
                    : AppColors.primaryInk,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  if (days != null)
                    FittedBox(
                      child: Text(
                        '$days',
                        style: const TextStyle(
                          color: AppColors.surface,
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const Icon(
                      Icons.event_outlined,
                      color: AppColors.accent,
                      size: 25,
                    ),
                  const SizedBox(height: 2),
                  Text(
                    days == null ? 'takvim' : 'gün',
                    style: TextStyle(
                      color: days == null
                          ? AppColors.accent
                          : AppColors.surface.withValues(alpha: .75),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${shortExamName(exam.examName)} · ${exam.examYear}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 5),
                  if (loading)
                    Text(
                      'Takvim yükleniyor…',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else if (failed)
                    Text(
                      'Takvim yüklenemedi',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else ...[
                    for (final session in rows)
                      Text(
                        '${rows.length > 1 ? '${session.code.replaceAll('_', ' ')} · ' : ''}${_date(session)}${session.examDate == null ? '' : ' · ${weekdays[session.examDate!.weekday - 1]}'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (unofficial)
                      Text(
                        'Resmî tarih henüz açıklanmadı',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontSize: 11),
                      ),
                  ],
                ],
              ),
            ),
            if (failed)
              IconButton(
                tooltip: 'Takvimi yeniden yükle',
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
              ),
          ],
        ),
      ),
    );
  }
}
