import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../config/app_config.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final session = supabase.Supabase.instance.client.auth.currentSession;
        final token = session?.accessToken;
        
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
