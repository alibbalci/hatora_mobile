import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widget/components.dart';
import '../../../core/widget/reference_widgets.dart';
import '../domain/question.dart';
import 'question_screens.dart' show difficultyLabels, reasonLabels;

class QuestionSavedScreen extends StatelessWidget {
  const QuestionSavedScreen({
    super.key,
    required this.question,
    required this.image,
    required this.onAdd,
    required this.onQuestions,
    required this.onHome,
  });
  final Question question;
  final SelectedImage image;
  final VoidCallback onAdd, onQuestions, onHome;
  @override
  Widget build(BuildContext context) {
    final date = question.nextReviewDate;
    final days = date == null
        ? null
        : DateUtils.dateOnly(date)
              .difference(DateUtils.dateOnly(DateTime.now()))
              .inDays;
    const weekdays = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    const months = [
      'OCA',
      'ŞUB',
      'MAR',
      'NİS',
      'MAY',
      'HAZ',
      'TEM',
      'AĞU',
      'EYL',
      'EKİ',
      'KAS',
      'ARA',
    ];
    final difficultyColor = question.difficulty == Difficulty.easy
        ? AppColors.success
        : question.difficulty == Difficulty.hard
        ? AppColors.error
        : AppColors.warning;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (c.maxHeight - 36).clamp(0, double.infinity),
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: 'Kapat',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          shape: const CircleBorder(
                            side: BorderSide(color: AppColors.line),
                          ),
                        ),
                        onPressed: onHome,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Container(
                        width: 156,
                        height: 156,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE2F7EF),
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          width: 116,
                          height: 116,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Color(0xFFC2EEDD),
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            width: 78,
                            height: 78,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 38,
                              color: AppColors.surface,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'Defterine eklendi',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -.7,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bu hatayı bir daha yapmaman için zamanı gelince sana hatırlatacağız.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryText,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 76,
                                  child: QuestionImageCard(
                                    bytes: image.bytes,
                                    height: 76,
                                    bottomMargin: 0,
                                    backgroundColor: const Color(0xFFFAFAF7),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ReferenceTag(
                                        label: question.subjectName,
                                        color: subjectColor(
                                          question.subjectName,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        question.topicName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          ReferenceTag(
                                            label:
                                                difficultyLabels[question
                                                    .difficulty]!,
                                            color: difficultyColor,
                                            icon: Icons.circle,
                                          ),
                                          ReferenceTag(
                                            label:
                                                reasonLabels[question
                                                    .mistakeReason]!,
                                            color: AppColors.secondaryText,
                                            backgroundColor:
                                                AppColors.surfaceMuted,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFAF9FE),
                              border: Border(
                                top: BorderSide(color: AppColors.line),
                              ),
                            ),
                            child: Row(
                              children: [
                                if (date != null)
                                  Container(
                                    width: 44,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(13),
                                      border: Border.all(color: AppColors.line),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          months[date.month - 1],
                                          style: const TextStyle(
                                            color: AppColors.error,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${date.day}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.event_note_outlined,
                                    color: AppColors.accent,
                                  ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'İlk tekrar',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                      Text(
                                        date == null
                                            ? 'Henüz planlanmadı'
                                            : '${weekdays[date.weekday - 1]} · ${days == 0
                                                  ? 'bugün'
                                                  : days == 1
                                                  ? 'yarın'
                                                  : days! > 1
                                                  ? '$days gün sonra'
                                                  : '${-days} gün önce'}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.event_outlined,
                                  color: AppColors.accent,
                                  size: 21,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Spacer(),
                    FilledButton.icon(
                      style: _button(true),
                      onPressed: onAdd,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Yeni soru ekle'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: _button(false),
                            onPressed: onQuestions,
                            icon: const Icon(
                              Icons.auto_stories_outlined,
                              size: 20,
                            ),
                            label: const Text('Sorularım'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: _button(false),
                            onPressed: onHome,
                            icon: const Icon(Icons.home_outlined, size: 20),
                            label: const Text('Ana sayfa'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  ButtonStyle _button(bool primary) => FilledButton.styleFrom(
    minimumSize: const Size(0, 58),
    padding: const EdgeInsets.symmetric(horizontal: 8),
    backgroundColor: primary ? AppColors.accent : AppColors.surface,
    foregroundColor: primary ? AppColors.surface : AppColors.primaryInk,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: primary ? BorderSide.none : const BorderSide(color: AppColors.line),
    ),
  );
}
