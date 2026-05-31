import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_token_store.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider), ref.watch(secureTokenStoreProvider));
});

class AuthRepository {
  AuthRepository(this._dio, this._tokenStore);

  final Dio _dio;
  final SecureTokenStore _tokenStore;

  Future<AuthUser> signIn({required String email, required String password}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final envelope = response.data ?? <String, dynamic>{};
    final data = envelope['data'] as Map<String, dynamic>;
    final tokens = data['tokens'] as Map<String, dynamic>;
    await _tokenStore.saveTokens(
      accessToken: tokens['accessToken'] as String,
      refreshToken: tokens['refreshToken'] as String,
    );
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AuthUser> signUp({
    required String email,
    required String fullName,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'email': email, 'fullName': fullName, 'password': password},
    );
    final envelope = response.data ?? <String, dynamic>{};
    final data = envelope['data'] as Map<String, dynamic>;
    final tokens = data['tokens'] as Map<String, dynamic>;
    await _tokenStore.saveTokens(
      accessToken: tokens['accessToken'] as String,
      refreshToken: tokens['refreshToken'] as String,
    );
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AuthUser> startDemoSession() async {
    final response = await _dio.post<Map<String, dynamic>>('/auth/dev-demo');
    final envelope = response.data ?? <String, dynamic>{};
    final data = envelope['data'] as Map<String, dynamic>;
    final tokens = data['tokens'] as Map<String, dynamic>;
    await _tokenStore.saveTokens(
      accessToken: tokens['accessToken'] as String,
      refreshToken: tokens['refreshToken'] as String,
    );
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AuthUser?> currentUser() async {
    final token = await _tokenStore.readAccessToken();
    if (token == null) {
      return null;
    }
    final response = await _dio.get<Map<String, dynamic>>('/auth/me');
    final envelope = response.data ?? <String, dynamic>{};
    final data = envelope['data'] as Map<String, dynamic>;
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> signOut() => _tokenStore.clear();
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.status,
    this.emailVerifiedAt,
  });

  final String id;
  final String email;
  final String fullName;
  final String role;
  final String status;
  final String? emailVerifiedAt;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      emailVerifiedAt: json['emailVerifiedAt'] as String?,
    );
  }
}
