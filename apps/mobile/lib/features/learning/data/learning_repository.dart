import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  if (AppConfig.skipAuth) {
    return MockLearningRepository();
  }
  return LearningRepository(ref.watch(dioProvider));
});

class LearningRepository {
  LearningRepository(this._dio);

  final Dio _dio;

  Future<List<LessonSummary>> lessons() async {
    final response = await _dio.get<Map<String, dynamic>>('/learning/lessons');
    final data = (response.data ?? <String, dynamic>{})['data'] as List<dynamic>;
    return data.map((item) => LessonSummary.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<LessonDetail> lesson(String slug) async {
    final response = await _dio.get<Map<String, dynamic>>('/learning/lessons/$slug');
    final data = (response.data ?? <String, dynamic>{})['data'] as Map<String, dynamic>;
    return LessonDetail.fromJson(data);
  }

  Future<QuizAttemptResult> submitQuiz(String quizId, List<String> selected) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/learning/quizzes/$quizId/attempts',
      data: {'selected': selected},
    );
    final data = (response.data ?? <String, dynamic>{})['data'] as Map<String, dynamic>;
    return QuizAttemptResult.fromJson(data);
  }

  Future<ActionCompletionResult> completeAction({
    required String lessonSlug,
    required String actionKey,
    required String actionType,
    int? amountMinor,
    String? note,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/learning/lessons/$lessonSlug/actions',
      data: {
        'actionKey': actionKey,
        'actionType': actionType,
        if (amountMinor != null) 'amountMinor': amountMinor,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    final data = (response.data ?? <String, dynamic>{})['data'] as Map<String, dynamic>;
    return ActionCompletionResult.fromJson(data);
  }
}

class LessonSummary {
  const LessonSummary({
    required this.slug,
    required this.title,
    required this.summary,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.track,
    required this.icon,
    required this.tool,
    required this.goalTags,
    required this.completionPercent,
    required this.completed,
    required this.recommendationReason,
    required this.missionName,
    required this.mapZone,
    required this.before,
    required this.after,
    required this.futureSelf,
    required this.scenario,
    required this.whatIf,
    required this.action,
    required this.completedActionKeys,
  });

  final String slug;
  final String title;
  final String summary;
  final String difficulty;
  final int estimatedMinutes;
  final String track;
  final String icon;
  final String tool;
  final List<String> goalTags;
  final int completionPercent;
  final bool completed;
  final String recommendationReason;
  final String missionName;
  final String mapZone;
  final String before;
  final String after;
  final String futureSelf;
  final String scenario;
  final String whatIf;
  final MoneyMissionAction? action;
  final List<String> completedActionKeys;

  factory LessonSummary.fromJson(Map<String, dynamic> json) {
    final content = LessonContent.fromJson(json['content'] as Map<String, dynamic>? ?? const {});
    final progressItems = json['progress'] as List<dynamic>? ?? const [];
    final progress = progressItems.isEmpty ? null : progressItems.first as Map<String, dynamic>;
    final recommendation = json['recommendation'] as Map<String, dynamic>?;

    return LessonSummary(
      slug: json['slug'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      difficulty: json['difficulty'] as String,
      estimatedMinutes: json['estimatedMinutes'] as int,
      track: content.track,
      icon: content.icon,
      tool: content.tool,
      goalTags: content.goalTags,
      completionPercent: progress == null ? 0 : progress['completionPercent'] as int,
      completed: progress?['completedAt'] != null,
      recommendationReason:
          recommendation == null ? 'Recommended for your finance path' : recommendation['reason'] as String,
      missionName: content.missionName,
      mapZone: content.mapZone,
      before: content.before,
      after: content.after,
      futureSelf: content.futureSelf,
      scenario: content.scenario,
      whatIf: content.whatIf,
      action: content.action,
      completedActionKeys: (json['actionCompletions'] as List<dynamic>? ?? const [])
          .map((item) => item as Map<String, dynamic>)
          .map((item) => item['actionKey'] as String)
          .toList(),
    );
  }
}

class LessonDetail extends LessonSummary {
  const LessonDetail({
    required super.slug,
    required super.title,
    required super.summary,
    required super.difficulty,
    required super.estimatedMinutes,
    required super.track,
    required super.icon,
    required super.tool,
    required super.goalTags,
    required super.completionPercent,
    required super.completed,
    required super.recommendationReason,
    required super.missionName,
    required super.mapZone,
    required super.before,
    required super.after,
    required super.futureSelf,
    required super.scenario,
    required super.whatIf,
    required super.action,
    required super.completedActionKeys,
    required this.sections,
    required this.quizzes,
  });

  final List<LessonSection> sections;
  final List<QuizItem> quizzes;

  factory LessonDetail.fromJson(Map<String, dynamic> json) {
    final content = LessonContent.fromJson(json['content'] as Map<String, dynamic>? ?? const {});
    final summary = LessonSummary.fromJson(json);
    return LessonDetail(
      slug: summary.slug,
      title: summary.title,
      summary: summary.summary,
      difficulty: summary.difficulty,
      estimatedMinutes: summary.estimatedMinutes,
      track: summary.track,
      icon: summary.icon,
      tool: summary.tool,
      goalTags: summary.goalTags,
      completionPercent: summary.completionPercent,
      completed: summary.completed,
      recommendationReason: summary.recommendationReason,
      missionName: summary.missionName,
      mapZone: summary.mapZone,
      before: summary.before,
      after: summary.after,
      futureSelf: summary.futureSelf,
      scenario: summary.scenario,
      whatIf: summary.whatIf,
      action: summary.action,
      completedActionKeys: summary.completedActionKeys,
      sections: content.sections,
      quizzes: (json['quizzes'] as List<dynamic>)
          .map((item) => QuizItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LessonContent {
  const LessonContent({
    required this.track,
    required this.icon,
    required this.tool,
    required this.goalTags,
    required this.sections,
    required this.missionName,
    required this.mapZone,
    required this.before,
    required this.after,
    required this.futureSelf,
    required this.scenario,
    required this.whatIf,
    required this.action,
  });

  final String track;
  final String icon;
  final String tool;
  final List<String> goalTags;
  final List<LessonSection> sections;
  final String missionName;
  final String mapZone;
  final String before;
  final String after;
  final String futureSelf;
  final String scenario;
  final String whatIf;
  final MoneyMissionAction? action;

  factory LessonContent.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] as Map<String, dynamic>? ?? const {};
    return LessonContent(
      track: metadata['track'] as String? ?? 'Foundations',
      icon: metadata['icon'] as String? ?? 'wallet',
      tool: metadata['tool'] as String? ?? 'none',
      goalTags: (metadata['goalTags'] as List<dynamic>? ?? const []).whereType<String>().toList(),
      sections: (json['sections'] as List<dynamic>? ?? const [])
          .map((item) => LessonSection.fromJson(item as Map<String, dynamic>))
          .toList(),
      missionName: metadata['missionName'] as String? ?? 'Complete a Money Mission',
      mapZone: metadata['mapZone'] as String? ?? 'Future Freedom City',
      before: metadata['before'] as String? ?? 'Money decisions feel confusing.',
      after: metadata['after'] as String? ?? 'I can take one clear money action.',
      futureSelf: metadata['futureSelf'] as String? ?? 'Future You benefits from one action today.',
      scenario: metadata['scenario'] as String? ?? 'Choose the action that protects Future You.',
      whatIf: metadata['whatIf'] as String? ?? 'What if one small action repeats for a year?',
      action: metadata['action'] is Map<String, dynamic>
          ? MoneyMissionAction.fromJson(metadata['action'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MoneyMissionAction {
  const MoneyMissionAction({
    required this.key,
    required this.type,
    required this.title,
    required this.description,
    required this.safetyNote,
    required this.buttonLabel,
    this.defaultAmountMinor,
  });

  final String key;
  final String type;
  final String title;
  final String description;
  final String safetyNote;
  final String buttonLabel;
  final int? defaultAmountMinor;

  factory MoneyMissionAction.fromJson(Map<String, dynamic> json) {
    return MoneyMissionAction(
      key: json['key'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      safetyNote: json['safetyNote'] as String? ?? 'Use your own trusted app and confirm after you act.',
      buttonLabel: json['buttonLabel'] as String? ?? 'I did this',
      defaultAmountMinor: json['defaultAmountMinor'] as int?,
    );
  }
}

class ActionCompletionResult {
  const ActionCompletionResult({
    required this.xpAwarded,
    required this.streakCount,
    this.walletBalanceMinor,
  });

  final int xpAwarded;
  final int streakCount;
  final int? walletBalanceMinor;

  factory ActionCompletionResult.fromJson(Map<String, dynamic> json) {
    final gamification = json['gamification'] as Map<String, dynamic>;
    final streak = gamification['streak'] as Map<String, dynamic>;
    final wallet = json['wallet'] as Map<String, dynamic>?;
    return ActionCompletionResult(
      xpAwarded: gamification['xpAwarded'] as int,
      streakCount: streak['currentCount'] as int,
      walletBalanceMinor: wallet == null ? null : wallet['balanceMinor'] as int,
    );
  }
}

class LessonSection {
  const LessonSection({required this.heading, required this.body});

  final String heading;
  final String body;

  factory LessonSection.fromJson(Map<String, dynamic> json) {
    return LessonSection(
      heading: json['heading'] as String? ?? 'Money idea',
      body: json['body'] as String? ?? '',
    );
  }
}

class QuizItem {
  const QuizItem({required this.id, required this.question, required this.options});

  final String id;
  final String question;
  final List<QuizOption> options;

  factory QuizItem.fromJson(Map<String, dynamic> json) {
    return QuizItem(
      id: json['id'] as String,
      question: json['question'] as String,
      options: (json['options'] as List<dynamic>)
          .map((item) => QuizOption.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuizOption {
  const QuizOption({required this.id, required this.text});

  final String id;
  final String text;

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(id: json['id'] as String, text: json['text'] as String);
  }
}

class QuizAttemptResult {
  const QuizAttemptResult({required this.isCorrect, required this.xpAwarded});

  final bool isCorrect;
  final int xpAwarded;

  factory QuizAttemptResult.fromJson(Map<String, dynamic> json) {
    final attempt = json['attempt'] as Map<String, dynamic>;
    return QuizAttemptResult(
      isCorrect: attempt['isCorrect'] as bool,
      xpAwarded: attempt['xpAwarded'] as int,
    );
  }
}

class MockLearningRepository implements LearningRepository {
  @override
  Dio get _dio => throw UnimplementedError();

  @override
  Future<List<LessonSummary>> lessons() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      const LessonSummary(
        slug: 'compound-growth-lab',
        title: 'Compound Growth Lab',
        summary: 'See how small monthly savings become future money.',
        difficulty: 'BEGINNER',
        estimatedMinutes: 7,
        track: 'Foundations',
        icon: 'rocket',
        tool: 'savings_calculator',
        goalTags: ['saving', 'future'],
        completionPercent: 35,
        completed: false,
        recommendationReason: 'Matched to your saving goal',
        missionName: 'Turn INR 100 Into a Future Habit',
        mapZone: 'Money Basics Island',
        before: 'I do not know how small savings become future money.',
        after: 'I can estimate how today\'s saving habit changes future money.',
        futureSelf: 'Future You has more choices because you made saving automatic.',
        scenario: 'You got INR 2,000 extra this month. What protects your future best?',
        whatIf: 'What if you save INR 100 daily for one year?',
        action: MoneyMissionAction(
          key: 'compound-growth-lab:irl-save',
          type: 'IRL_SAVE',
          title: 'Save in your real UPI or bank app',
          description: 'Use your trusted UPI or bank app separately, then return and mark it complete.',
          safetyNote: 'Muscle Money does not transfer money.',
          buttonLabel: 'I saved money',
          defaultAmountMinor: 10000,
        ),
        completedActionKeys: [],
      ),
      const LessonSummary(
        slug: 'first-etf-simulator',
        title: 'First ETF Simulator',
        summary: 'Learn why diversified funds can be easier than picking one stock.',
        difficulty: 'INTERMEDIATE',
        estimatedMinutes: 9,
        track: 'Investing',
        icon: 'pie',
        tool: 'simulator_prompt',
        goalTags: ['investing'],
        completionPercent: 0,
        completed: false,
        recommendationReason: 'Good next investing step',
        missionName: 'Make Your First Virtual Investment',
        mapZone: 'Investing Arena',
        before: 'I am nervous about investing because every asset looks the same.',
        after: 'I can practice before risking real money.',
        futureSelf: 'Future You enters markets after practicing first.',
        scenario: 'You can buy one ETF-style asset or one single stock in the simulator. What will you compare?',
        whatIf: 'What if your ETF and stock move in opposite directions?',
        action: MoneyMissionAction(
          key: 'first-etf-simulator:simulator',
          type: 'SIMULATOR',
          title: 'Practice before real investing',
          description: 'Open the simulator and compare one diversified asset with one individual stock.',
          safetyNote: 'This is virtual practice only.',
          buttonLabel: 'I did the simulator task',
        ),
        completedActionKeys: [],
      ),
    ];
  }

  @override
  Future<LessonDetail> lesson(String slug) async {
    await Future.delayed(const Duration(seconds: 1));
    return LessonDetail(
      slug: slug,
      title: 'Sample Lesson',
      summary: 'This is a sample lesson detail.',
      difficulty: 'BEGINNER',
      estimatedMinutes: 5,
      track: 'Foundations',
      icon: 'wallet',
      tool: 'savings_calculator',
      goalTags: const ['saving'],
      completionPercent: 25,
      completed: false,
      recommendationReason: 'Matched to your saving goal',
      missionName: 'Turn INR 100 Into a Future Habit',
      mapZone: 'Money Basics Island',
      before: 'I do not know how small savings become future money.',
      after: 'I can estimate how today\'s saving habit changes future money.',
      futureSelf: 'Future You has more choices because you made saving automatic.',
      scenario: 'You got INR 2,000 extra this month. What protects your future best?',
      whatIf: 'What if you save INR 100 daily for one year?',
      action: const MoneyMissionAction(
        key: 'compound-growth-lab:irl-save',
        type: 'IRL_SAVE',
        title: 'Save in your real UPI or bank app',
        description: 'Use your trusted UPI or bank app separately, then return and mark it complete.',
        safetyNote: 'Muscle Money does not transfer money.',
        buttonLabel: 'I saved money',
        defaultAmountMinor: 10000,
      ),
      completedActionKeys: const [],
      sections: const [
        LessonSection(
          heading: 'Small habits become big numbers',
          body: 'Use the calculator below to see how monthly saving can grow with time.',
        ),
      ],
      quizzes: [
        const QuizItem(id: 'q1', question: 'What is saving?', options: [QuizOption(id: 'a', text: 'Keeping money'), QuizOption(id: 'b', text: 'Spending money')])
      ],
    );
  }

  @override
  Future<QuizAttemptResult> submitQuiz(String quizId, List<String> selected) async {
    await Future.delayed(const Duration(seconds: 1));
    return const QuizAttemptResult(isCorrect: true, xpAwarded: 50);
  }

  @override
  Future<ActionCompletionResult> completeAction({
    required String lessonSlug,
    required String actionKey,
    required String actionType,
    int? amountMinor,
    String? note,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return ActionCompletionResult(
      xpAwarded: 15,
      streakCount: 4,
      walletBalanceMinor: amountMinor == null ? null : 255000 + amountMinor,
    );
  }
}
