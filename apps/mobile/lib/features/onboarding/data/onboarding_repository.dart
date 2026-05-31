import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(supabase.Supabase.instance.client);
});

class OnboardingRepository {
  OnboardingRepository(this._supabase);

  final supabase.SupabaseClient _supabase;

  Future<OnboardingStatus> status() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return const OnboardingStatus(completed: false, missingFields: ['auth']);
    }
    
    final metadata = user.userMetadata ?? {};
    final isCompleted = metadata['onboarding_completed'] == true;
    
    return OnboardingStatus(
      completed: isCompleted,
      missingFields: isCompleted ? [] : ['financialGoals', 'monthlyIncomeMinor'],
    );
  }

  Future<OnboardingStatus> complete(OnboardingPayload payload) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final currentMetadata = user.userMetadata ?? {};
    final updatedMetadata = {
      ...currentMetadata,
      ...payload.toJson(),
      'onboarding_completed': true,
    };

    await _supabase.auth.updateUser(
      supabase.UserAttributes(data: updatedMetadata),
    );

    return const OnboardingStatus(completed: true, missingFields: []);
  }
}

class OnboardingStatus {
  const OnboardingStatus({required this.completed, required this.missingFields});

  final bool completed;
  final List<String> missingFields;
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
