import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(dioProvider));
});

final userProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(profileRepositoryProvider).getProfile();
});

class ProfileRepository {
  final Dio _dio;

  ProfileRepository(this._dio);

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _dio.get('/api/v1/users/profile');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load profile');
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      await _dio.put('/api/v1/users/profile', data: data);
    } catch (e) {
      throw Exception('Failed to update profile');
    }
  }
}
