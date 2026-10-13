import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/time/calendar_date.dart';
import '../../dashboard/domain/dashboard_models.dart';
import 'home_exam_summary.dart' show shortExamName;

// The home quote can be replaced here without changing the layout.
const homeMotivationQuote = 'Küçük adımlar,\nbüyük sonuçlar getirir.';
const _journeyInk = AppColors.primaryInk;

class HomeJourneyHeader extends StatelessWidget {
  const HomeJourneyHeader({
    super.key,
    required this.name,
    required this.onProfile,
    required this.onReminders,
    this.today,
  });
  final String name;
  final DateTime? today;
  final VoidCallback onProfile, onReminders;
  @override
  Widget build(BuildContext context) {
    final date = today ?? DateTime.now();
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
    const weekdays = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    final initials = words.isEmpty
        ? '?'
        : '${words.first.characters.first}${words.length > 1 ? words.last.characters.first : ''}'
              .toUpperCase();
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/hatora-logo.png',
              semanticLabel: 'Hatora logosu',
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${date.day} ${months[date.month - 1]}, ${weekdays[date.weekday - 1]}',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                words.isEmpty ? 'Merhaba' : 'Merhaba, ${words.first}',
                maxLines: 2,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.5,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Hatırlatmalar',
          onPressed: onReminders,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.line),
            minimumSize: const Size(46, 46),
          ),
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: _journeyInk,
            size: 23,
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          tooltip: 'Profili aç',
          onPressed: onProfile,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.accentSoft,
            foregroundColor: AppColors.accent,
            minimumSize: const Size(46, 46),
          ),
          icon: Text(
            initials,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class HomeJourneyCountdown extends ConsumerWidget {
  const HomeJourneyCountdown({
    super.key,
    required this.exam,
    required this.onTap,
  });
  final DashboardActiveExam exam;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isPastExam(exam.examDate, exam.examYear)) {
      return const SizedBox.shrink();
    }
    final schedule = ref.watch(
      examScheduleProvider((
        examId: exam.examId,
        editionId: exam.examEditionId,
      )),
    );
    final sessions = schedule.asData?.value
        .where((s) => !isPastExam(s.examDate, exam.examYear))
        .toList();
    final estimated = sessions
        ?.where((s) => s.estimatedDate != null)
        .firstOrNull
        ?.estimatedDate;
    final days = exam.daysUntilExam;
    return Semantics(
      button: true,
      label: 'Sınav takvimini aç',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.primaryInk,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Stack(
            children: [
              const Positioned(
                right: -5,
                bottom: 0,
                width: 186,
                height: 160,
                child: CustomPaint(painter: _MountainPainter()),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          color: Color(0xFFBBB4DE),
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${shortExamName(exam.examName)} ${exam.examYear}',
                            style: const TextStyle(
                              color: Color(0xFFBBB4DE),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (days != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '$days',
                                style: const TextStyle(
                                  fontSize: 64,
                                  height: 1,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.surface,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Flexible(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 5),
                              child: Text(
                                'gün kaldı',
                                style: TextStyle(
                                  fontSize: 20,
                                  height: 1.2,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFDDD7FF),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      const Text(
                        'Tarih bekleniyor',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: AppColors.surface,
                        ),
                      ),
                    const SizedBox(height: 14),
                    Text(
                      days == null
                          ? examDateLabel(
                              null,
                              estimatedDate: estimated,
                              year: exam.examYear,
                            )
                          : 'Disiplin bugün, hayalindeki yarın.',
                      style: const TextStyle(
                        color: Color(0xFFB6AED5),
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                    if (schedule.hasError)
                      TextButton(
                        onPressed: () => ref.invalidate(
                          examScheduleProvider((
                            examId: exam.examId,
                            editionId: exam.examEditionId,
                          )),
                        ),
                        child: const Text('Takvimi yeniden yükle'),
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

class HomeMotivationCard extends StatelessWidget {
  const HomeMotivationCard({super.key, this.quote = homeMotivationQuote});
  final String quote;
  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFFF0ECFF),
      borderRadius: BorderRadius.circular(25),
    ),
    child: Stack(
      children: [
        const Positioned(
          right: 0,
          bottom: -8,
          width: 80,
          height: 100,
          child: CustomPaint(painter: _PlantPainter()),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 78, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.format_quote_rounded,
                color: Color(0xFFAD9CF5),
                size: 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  quote,
                  style: const TextStyle(
                    color: _journeyInk,
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MountainPainter extends CustomPainter {
  const _MountainPainter();
  @override
  void paint(Canvas c, Size s) {
    final p = Paint();
    c.drawCircle(
      Offset(s.width * .28, s.height * .28),
      s.width * .16,
      p..color = const Color(0xFF30295E),
    );
    void triangle(List<Offset> points, Color color) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      path.close();
      c.drawPath(path, p..color = color);
    }

    triangle([
      Offset(0, s.height),
      Offset(s.width * .23, s.height * .5),
      Offset(s.width * .6, s.height),
    ], const Color(0xFF3B317C));
    triangle([
      Offset(s.width * .24, s.height),
      Offset(s.width * .5, s.height * .18),
      Offset(s.width, s.height),
    ], AppColors.accent);
    triangle([
      Offset(s.width * .5, s.height * .18),
      Offset(s.width * .62, s.height * .45),
      Offset(s.width * .51, s.height * .41),
      Offset(s.width * .43, s.height * .48),
      Offset(s.width * .39, s.height * .42),
    ], const Color(0xFF9275FF));
    triangle([
      Offset(s.width * .5, s.height * .18),
      Offset(s.width, s.height),
      Offset(s.width * .61, s.height),
    ], AppColors.accent);
    triangle([
      Offset(s.width * .66, s.height),
      Offset(s.width * .8, s.height * .4),
      Offset(s.width * 1.12, s.height),
    ], const Color(0xFF3B317C));
    c.drawLine(
      Offset(s.width * .5, s.height * .18),
      Offset(s.width * .5, s.height * .025),
      p
        ..color = _journeyInk
        ..strokeWidth = 2,
    );
    triangle([
      Offset(s.width * .5, s.height * .03),
      Offset(s.width * .67, s.height * .065),
      Offset(s.width * .5, s.height * .11),
    ], const Color(0xFFF07065));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PlantPainter extends CustomPainter {
  const _PlantPainter();
  @override
  void paint(Canvas c, Size s) {
    final p = Paint();
    c.drawCircle(
      Offset(s.width * .72, s.height * .95),
      s.width * .46,
      p..color = const Color(0xFFE3DAFB),
    );
    c.drawLine(
      Offset(s.width * .48, s.height * .82),
      Offset(s.width * .43, s.height * .46),
      p
        ..color = const Color(0xFF9076DF)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    final leaf = Path()
      ..moveTo(s.width * .46, s.height * .6)
      ..cubicTo(
        s.width * .2,
        s.height * .59,
        s.width * .12,
        s.height * .42,
        s.width * .17,
        s.height * .4,
      )
      ..cubicTo(
        s.width * .38,
        s.height * .38,
        s.width * .49,
        s.height * .52,
        s.width * .46,
        s.height * .6,
      );
    c.drawPath(
      leaf,
      p
        ..color = const Color(0xFFA48AEF)
        ..style = PaintingStyle.fill,
    );
    final tall = Path()
      ..moveTo(s.width * .45, s.height * .61)
      ..cubicTo(
        s.width * .29,
        s.height * .4,
        s.width * .44,
        s.height * .14,
        s.width * .67,
        s.height * .1,
      )
      ..cubicTo(
        s.width * .8,
        s.height * .26,
        s.width * .69,
        s.height * .54,
        s.width * .45,
        s.height * .61,
      );
    c.drawPath(tall, p..color = const Color(0xFF8060D3));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
