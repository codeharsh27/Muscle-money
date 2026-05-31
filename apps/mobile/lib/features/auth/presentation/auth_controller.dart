import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../data/auth_repository.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    final repository = ref.read(authRepositoryProvider);
    if (AppConfig.skipAuth) {
      return repository.startDemoSession();
    }
    return repository.currentUser();
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(authRepositoryProvider).signIn(email: email.trim(), password: password);
    });
  }

  Future<void> signUp({
    required String email,
    required String fullName,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref
          .read(authRepositoryProvider)
          .signUp(email: email.trim(), fullName: fullName.trim(), password: password);
    });
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }

  String errorMessage(Object error) {
    if (error is DioException) {
      final body = error.response?.data;
      if (body is Map<String, dynamic>) {
        final errorBody = body['error'];
        if (errorBody is Map<String, dynamic> && errorBody['message'] is String) {
          return errorBody['message'] as String;
        }
      }
      return 'Unable to reach Muscle Money. Check your connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
