import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

final aiCoachRepositoryProvider = Provider<AiCoachRepository>((ref) {
  return AiCoachRepository(ref.watch(dioProvider));
});

class AiCoachRepository {
  AiCoachRepository(this._dio);
  final Dio _dio;

  Future<String> sendMessage({required String message, required List<Map<String, dynamic>> history}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/learning/chat',
        data: {
          'message': message,
          'history': history,
        },
      );
      final envelope = response.data ?? <String, dynamic>{};
      final data = envelope['data'] as Map<String, dynamic>? ?? envelope;
      return data['reply'] as String? ?? "I'm sorry, I didn't quite catch that.";
    } catch (e) {
      return "Looks like I'm having trouble connecting right now. Try again in a bit!";
    }
  }
}

class MockAiCoachRepository implements AiCoachRepository {
  @override
  Dio get _dio => throw UnimplementedError();

  @override
  Future<String> sendMessage({required String message, required List<Map<String, dynamic>> history}) async {
    await Future.delayed(const Duration(seconds: 2));
    if (message.toLowerCase().contains('buy') || message.toLowerCase().contains('invest')) {
      return "As your AI coach, I'm here to teach you the concepts, but I can't give you specific investment advice! Remember, all investments carry risk.";
    }
    return "That's a great question about $message! Think of it like planting a seed: it takes time to grow, but with consistency, you'll see results.";
  }
}
