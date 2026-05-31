import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/secure_token_store.dart';

final dioProvider = Provider<Dio>((ref) {
  final tokenStore = ref.watch(secureTokenStoreProvider);
  final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStore.readAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        } else if (!AppConfig.skipAuth) {
          // Dev bypass token
          options.headers['Authorization'] = 'Bearer dev-token-xyz';
        }
        handler.next(options);
      },
    ),
  );
  return dio;
});
