import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(supabase.Supabase.instance.client);
});

class AuthRepository {
  AuthRepository(this._supabase);

  final supabase.SupabaseClient _supabase;

  Future<AuthUser> signIn({required String email, required String password}) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) {
      throw Exception('Login failed');
    }
    return AuthUser.fromSupabase(response.user!);
  }

  Future<AuthUser> signUp({
    required String email,
    required String fullName,
    required String password,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    if (response.user == null) {
      throw Exception('Signup failed');
    }
    return AuthUser.fromSupabase(response.user!);
  }

  Future<AuthUser> startDemoSession() async {
    // Demo session is not standard in Supabase, but we can simulate it if needed,
    // or just return a dummy user for now if SKIP_AUTH is true.
    return const AuthUser(
      id: 'demo-id',
      email: 'demo@musclemoney.app',
      fullName: 'Demo User',
      role: 'USER',
      status: 'ACTIVE',
    );
  }

  Future<AuthUser?> currentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return AuthUser.fromSupabase(user);
  }

  Future<void> signOut() => _supabase.auth.signOut();
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

  factory AuthUser.fromSupabase(supabase.User user) {
    final metadata = user.userMetadata ?? {};
    return AuthUser(
      id: user.id,
      email: user.email ?? '',
      fullName: metadata['full_name'] as String? ?? 'User',
      role: 'USER', // Supabase roles are handled via RLS or custom claims
      status: 'ACTIVE',
      emailVerifiedAt: user.emailConfirmedAt,
    );
  }
}
