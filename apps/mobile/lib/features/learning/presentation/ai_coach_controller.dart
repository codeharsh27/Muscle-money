import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ai_coach_repository.dart';

class ChatMessage {
  final String text;
  final bool isCoach;
  final bool hasSnippet;

  ChatMessage({
    required this.text,
    required this.isCoach,
    this.hasSnippet = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isCoach': isCoach,
    };
  }
}

class AiCoachState {
  final List<ChatMessage> messages;
  final bool isTyping;

  AiCoachState({
    this.messages = const [],
    this.isTyping = false,
  });

  AiCoachState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
  }) {
    return AiCoachState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}

class AiCoachController extends StateNotifier<AiCoachState> {
  AiCoachController(this._repository) : super(AiCoachState(messages: [
    ChatMessage(
      text: "Hi there! I'm Nova, your Muscle Money Coach. 🎯\nAsk me anything about finance, investing, or how to grow your wealth!",
      isCoach: true,
    )
  ]));

  final AiCoachRepository _repository;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Prepare history BEFORE adding the new message
    final history = state.messages.map((m) => m.toJson()).toList();

    // Add user message to UI
    final userMsg = ChatMessage(text: text, isCoach: false);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isTyping: true,
    );

    // Send to backend
    final reply = await _repository.sendMessage(message: text, history: history);

    // Add coach reply
    if (mounted) {
      state = state.copyWith(
        messages: [...state.messages, ChatMessage(text: reply, isCoach: true)],
        isTyping: false,
      );
    }
  }
}

final aiCoachControllerProvider = StateNotifierProvider<AiCoachController, AiCoachState>((ref) {
  return AiCoachController(ref.watch(aiCoachRepositoryProvider));
});
