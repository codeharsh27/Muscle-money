import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(ref.watch(dioProvider));
});

class OnboardingRepository {
  OnboardingRepository(this._dio);

  final Dio _dio;

  Future<OnboardingStatus> status() async {
    final response = await _dio.get<Map<String, dynamic>>('/onboarding/status');
    final data = (response.data ?? <String, dynamic>{})['data'] as Map<String, dynamic>;
    return OnboardingStatus.fromJson(data);
  }

  Future<OnboardingStatus> complete(OnboardingPayload payload) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/onboarding/complete',
      data: payload.toJson(),
    );
    final data = (response.data ?? <String, dynamic>{})['data'] as Map<String, dynamic>;
    return OnboardingStatus.fromJson(data);
  }
}

class OnboardingStatus {
  const OnboardingStatus({required this.completed, required this.missingFields});

  final bool completed;
  final List<String> missingFields;

  factory OnboardingStatus.fromJson(Map<String, dynamic> json) {
    return OnboardingStatus(
      completed: json['completed'] as bool,
      missingFields: (json['missingFields'] as List<dynamic>? ?? const [])
          .map((item) => item as String)
          .toList(),
    );
  }
}

class OnboardingPayload {
  const OnboardingPayload({
    required this.financialGoals,
    required this.riskProfile,
    required this.knowledgeLevel,
    required this.monthlyIncomeMinor,
    required this.spendingHabits,
    required this.learningPreferences,
  });

  final List<String> financialGoals;
  final String riskProfile;
  final String knowledgeLevel;
  final int monthlyIncomeMinor;
  final Map<String, Object> spendingHabits;
  final Map<String, Object> learningPreferences;

  Map<String, Object> toJson() {
    return {
      'financialGoals': financialGoals,
      'riskProfile': riskProfile,
      'knowledgeLevel': knowledgeLevel,
      'monthlyIncomeMinor': monthlyIncomeMinor,
      'spendingHabits': spendingHabits,
      'learningPreferences': learningPreferences,
    };
  }
}
