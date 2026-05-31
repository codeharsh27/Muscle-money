import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  if (AppConfig.skipAuth) {
    return MockDashboardRepository();
  }
  return DashboardRepository(ref.watch(dioProvider));
});

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<DashboardSummary> load() async {
    final response = await _dio.get<Map<String, dynamic>>('/analytics/dashboard');
    final data = (response.data ?? <String, dynamic>{})['data'] as Map<String, dynamic>;
    return DashboardSummary.fromJson(data);
  }
}

class DashboardSummary {
  const DashboardSummary({
    required this.monthlySavingsMinor,
    required this.financialScore,
    required this.novaInsight,
    this.monthlyIncomeMinor,
    this.externalSavings = const [],
    this.monthlySpendingsMinor = 0,
    this.recentSpendings = const [],
    required this.simulatorCashMinor,
    required this.simulatorHoldingsMinor,
    required this.simulatorEquityMinor,
    required this.openPositions,
    required this.totalXp,
    required this.level,
    required this.streakCount,
    required this.quizAccuracyPercent,
    required this.lessonsStarted,
    required this.lessonsCompleted,
    this.progressHistory = const [],
    this.health,
    this.goals = const [],
    this.smartAction,
  });

  final int monthlySavingsMinor;
  final int financialScore;
  final String novaInsight;
  final int? monthlyIncomeMinor;
  final List<ExternalSaving> externalSavings;
  final int monthlySpendingsMinor;
  final List<RecentSpending> recentSpendings;
  final int simulatorCashMinor;
  final int simulatorHoldingsMinor;
  final int simulatorEquityMinor;
  final int openPositions;
  final int totalXp;
  final int level;
  final int streakCount;
  final int quizAccuracyPercent;
  final int lessonsStarted;
  final int lessonsCompleted;
  final List<int> progressHistory;
  final HealthSummary? health;
  final List<DashboardGoal> goals;
  final DashboardSmartAction? smartAction;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final wallet = json['wallet'] as Map<String, dynamic>;
    final simulator = json['simulator'] as Map<String, dynamic>;
    final learning = json['learning'] as Map<String, dynamic>;
    final health = json['health'] as Map<String, dynamic>?; 
    final goalsJson = json['goals'] as List<dynamic>? ?? [];
    final smartActionJson = json['smartAction'] as Map<String, dynamic>?;

    return DashboardSummary(
      monthlySavingsMinor: wallet['monthlySavingsMinor'] as int,
      financialScore: wallet['financialScore'] as int,
      novaInsight: wallet['novaInsight'] as String,
      monthlyIncomeMinor: wallet['monthlyIncomeMinor'] as int?,
      externalSavings: (wallet['externalSavings'] as List<dynamic>?)
              ?.map((item) => ExternalSaving.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      monthlySpendingsMinor: wallet['monthlySpendingsMinor'] as int? ?? 0,
      recentSpendings: (wallet['recentSpendings'] as List<dynamic>?)
              ?.map((item) => RecentSpending.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      simulatorCashMinor: simulator['cashMinor'] as int,
      simulatorHoldingsMinor: simulator['holdingsValueMinor'] as int,
      simulatorEquityMinor: simulator['totalEquityMinor'] as int,
      openPositions: simulator['openPositions'] as int,
      totalXp: learning['totalXp'] as int,
      level: learning['level'] as int? ?? 1,
      streakCount: learning['streakCount'] as int? ?? 0,
      quizAccuracyPercent: learning['quizAccuracyPercent'] as int,
      lessonsStarted: learning['lessonsStarted'] as int,
      lessonsCompleted: learning['lessonsCompleted'] as int,
      progressHistory: (learning['progressHistory'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [0,0,0,0,0,0,0],
      health: health != null ? HealthSummary.fromJson(health) : null,
      goals: goalsJson.map((g) => DashboardGoal.fromJson(g as Map<String, dynamic>)).toList(),
      smartAction: smartActionJson != null ? DashboardSmartAction.fromJson(smartActionJson) : null,
    );
  }
}

class DashboardGoal {
  final String id;
  final String title;
  final int targetAmountMinor;
  final int currentAmountMinor;
  final bool isCompleted;

  const DashboardGoal({
    required this.id,
    required this.title,
    required this.targetAmountMinor,
    required this.currentAmountMinor,
    required this.isCompleted,
  });

  factory DashboardGoal.fromJson(Map<String, dynamic> json) {
    return DashboardGoal(
      id: json['id'] as String,
      title: json['title'] as String,
      targetAmountMinor: json['targetAmountMinor'] as int,
      currentAmountMinor: json['currentAmountMinor'] as int,
      isCompleted: json['isCompleted'] as bool,
    );
  }
}

class DashboardSmartAction {
  final String title;
  final String description;
  final String actionText;
  final String actionType;

  const DashboardSmartAction({
    required this.title,
    required this.description,
    required this.actionText,
    required this.actionType,
  });

  factory DashboardSmartAction.fromJson(Map<String, dynamic> json) {
    return DashboardSmartAction(
      title: json['title'] as String,
      description: json['description'] as String,
      actionText: json['actionText'] as String,
      actionType: json['actionType'] as String,
    );
  }
}

class HealthSummary {
  final int score;
  final List<String> strongAreas;
  final List<String> needsImprovement;

  const HealthSummary({
    required this.score,
    required this.strongAreas,
    required this.needsImprovement,
  });

  factory HealthSummary.fromJson(Map<String, dynamic> json) {
    return HealthSummary(
      score: json['score'] as int,
      strongAreas: List<String>.from(json['strongAreas'] as List<dynamic>),
      needsImprovement: List<String>.from(json['needsImprovement'] as List<dynamic>),
    );
  }
}

class ExternalSaving {
  const ExternalSaving({required this.platform, required this.amountMinor});

  final String platform;
  final int amountMinor;

  factory ExternalSaving.fromJson(Map<String, dynamic> json) {
    return ExternalSaving(
      platform: json['platform'] as String,
      amountMinor: json['amountMinor'] as int,
    );
  }
}

class RecentSpending {
  const RecentSpending({
    required this.amountMinor,
    required this.platform,
    this.merchant,
    this.category,
  });

  final int amountMinor;
  final String platform;
  final String? merchant;
  final String? category;

  factory RecentSpending.fromJson(Map<String, dynamic> json) {
    return RecentSpending(
      amountMinor: json['amountMinor'] as int,
      platform: json['platform'] as String,
      merchant: json['merchant'] as String?,
      category: json['category'] as String?,
    );
  }
}

class MockDashboardRepository implements DashboardRepository {
  @override
  Dio get _dio => throw UnimplementedError();

  @override
  Future<DashboardSummary> load() async {
    await Future.delayed(const Duration(seconds: 1));
    return const DashboardSummary(
      monthlySavingsMinor: 300000,
      financialScore: 75,
      novaInsight: "Great job saving this month! You are hitting 20% of your fixed salary.",
      monthlyIncomeMinor: 1500000,
      externalSavings: [
        ExternalSaving(platform: 'PhonePe', amountMinor: 100000),
        ExternalSaving(platform: 'Groww', amountMinor: 200000),
      ],
      monthlySpendingsMinor: 120000,
      recentSpendings: [
        RecentSpending(amountMinor: 50000, platform: 'PhonePe', merchant: 'Starbucks', category: 'Food'),
        RecentSpending(amountMinor: 20000, platform: 'GPay', merchant: 'Uber', category: 'Transport'),
      ],
      simulatorCashMinor: 500000,
      simulatorHoldingsMinor: 550000,
      simulatorEquityMinor: 1050000,
      openPositions: 3,
      totalXp: 450,
      level: 2,
      streakCount: 3,
      quizAccuracyPercent: 92,
      lessonsStarted: 5,
      lessonsCompleted: 4,
    );
  }
}
