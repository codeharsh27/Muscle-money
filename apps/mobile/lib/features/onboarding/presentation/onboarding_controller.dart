import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../data/onboarding_repository.dart';

final onboardingStatusProvider = FutureProvider<OnboardingStatus>((ref) {
  return ref.watch(onboardingRepositoryProvider).status();
});

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, OnboardingStatus?>(
  OnboardingController.new,
);

class OnboardingController extends AsyncNotifier<OnboardingStatus?> {
  @override
  Future<OnboardingStatus?> build() async => null;

  Future<void> complete(OnboardingPayload payload) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(onboardingRepositoryProvider).complete(payload));
    ref.invalidate(onboardingStatusProvider);
  }

  String errorMessage(Object error) {
    if (error is supabase.AuthException) {
      return error.message;
    }
    return 'Error: ${error.toString()}';
  }
}
