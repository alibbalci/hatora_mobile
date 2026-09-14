class GeneralStatsDto {
  GeneralStatsDto.fromJson(Map<String, dynamic> json)
    : totalQuestionsAdded = (json['totalQuestionsAdded'] as num).toInt(),
      totalReviews = (json['totalReviews'] as num).toInt(),
      correctCount = (json['correctCount'] as num).toInt(),
      wrongCount = (json['wrongCount'] as num).toInt(),
      unsolvedCount = (json['unsolvedCount'] as num).toInt(),
      successRate = (json['successRate'] as num).toDouble(),
      activeQuestionCount = (json['activeQuestionCount'] as num).toInt(),
      masteredQuestionCount = (json['masteredQuestionCount'] as num).toInt(),
      currentStreak = json['currentStreak'] as int,
      longestStreak = json['longestStreak'] as int;
  final int totalQuestionsAdded,
      totalReviews,
      correctCount,
      wrongCount,
      unsolvedCount,
      activeQuestionCount,
      masteredQuestionCount,
      currentStreak,
      longestStreak;
  final double successRate;
}

class SubjectStatsDto {
  SubjectStatsDto.fromJson(Map<String, dynamic> json)
    : subjectId = json['subjectId'] as String,
      subjectName = json['subjectName'] as String,
      reviewCount = (json['reviewCount'] as num).toInt(),
      correctCount = (json['correctCount'] as num).toInt(),
      wrongCount = (json['wrongCount'] as num).toInt(),
      unsolvedCount = (json['unsolvedCount'] as num).toInt(),
      successRate = (json['successRate'] as num).toDouble(),
      masteredCount = (json['masteredCount'] as num).toInt();
  final String subjectId, subjectName;
  final int reviewCount, correctCount, wrongCount, unsolvedCount, masteredCount;
  final double successRate;
}

class TopicStatsDto {
  TopicStatsDto.fromJson(Map<String, dynamic> json)
    : topicId = json['topicId'] as String,
      topicName = json['topicName'] as String,
      subjectId = json['subjectId'] as String,
      subjectName = json['subjectName'] as String,
      reviewCount = (json['reviewCount'] as num).toInt(),
      correctCount = (json['correctCount'] as num).toInt(),
      wrongCount = (json['wrongCount'] as num).toInt(),
      unsolvedCount = (json['unsolvedCount'] as num).toInt(),
      successRate = (json['successRate'] as num).toDouble(),
      masteredCount = (json['masteredCount'] as num).toInt();
  final String topicId, topicName, subjectId, subjectName;
  final int reviewCount, correctCount, wrongCount, unsolvedCount, masteredCount;
  final double successRate;
}

class MistakeReasonStatsDto {
  MistakeReasonStatsDto.fromJson(Map<String, dynamic> json)
    : mistakeReason = json['mistakeReason'] as String,
      count = (json['count'] as num).toInt(),
      percentage = (json['percentage'] as num).toDouble();
  final String mistakeReason;
  final int count;
  final double percentage;
}

class InsightDto {
  InsightDto.fromJson(Map<String, dynamic> json)
    : strongestSubjects = (json['strongestSubjects'] as List<dynamic>)
          .map((e) => SubjectStatsDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      weakestSubjects = (json['weakestSubjects'] as List<dynamic>)
          .map((e) => SubjectStatsDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      strongestTopics = (json['strongestTopics'] as List<dynamic>)
          .map((e) => TopicStatsDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      weakestTopics = (json['weakestTopics'] as List<dynamic>)
          .map((e) => TopicStatsDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      hardestTopics = (json['hardestTopics'] as List<dynamic>)
          .map((e) => TopicStatsDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      mostCommonMistakeReason = json['mostCommonMistakeReason'] as String?;
  final List<SubjectStatsDto> strongestSubjects, weakestSubjects;
  final List<TopicStatsDto> strongestTopics, weakestTopics, hardestTopics;
  final String? mostCommonMistakeReason;
}
