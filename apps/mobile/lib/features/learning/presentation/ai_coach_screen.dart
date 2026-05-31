import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'ai_coach_controller.dart';

class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key});

  @override
  ConsumerState<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends ConsumerState<AiCoachScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    await _speechToText.initialize();
  }

  void _startListening() async {
    bool available = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
          // Auto-send when finished speaking
          if (_controller.text.isNotEmpty && !_speechToText.isListening) {
             _sendMessage(_controller.text);
          }
        }
      },
    );
    if (available) {
      setState(() => _isListening = true);
      _speechToText.listen(
        onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
          });
        },
      );
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();
    
    // Scroll immediately for user message
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    
    await ref.read(aiCoachControllerProvider.notifier).sendMessage(text);
    
    // Scroll again for coach reply
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chatState = ref.watch(aiCoachControllerProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text('Nova', style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          )
        ],
      ),
      body: Stack(
        children: [
          // Chat List
          ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 180 + MediaQuery.of(context).padding.bottom),
            itemCount: chatState.messages.length + (chatState.isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Text('Today', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildMessageBubble(chatState.messages[index]),
                  ],
                );
              }
              
              if (index == chatState.messages.length && chatState.isTyping) {
                return _buildTypingIndicator();
              }
              
              return _buildMessageBubble(chatState.messages[index]);
            },
          ),
          
          // Fixed Bottom Input Area
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16, top: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.8),
                    border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.2))),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Suggestion Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            _buildSuggestionChip('Explain Compound Interest', Icons.school, true),
                            const SizedBox(width: 8),
                            _buildSuggestionChip('Check my progress', Icons.donut_large, false),
                            const SizedBox(width: 8),
                            _buildSuggestionChip('What\'s a Dividend?', Icons.help, false),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Input Field
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          padding: const EdgeInsets.only(left: 16, right: 6, top: 4, bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  maxLines: 5,
                                  minLines: 1,
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: TextInputAction.newline,
                                  style: theme.textTheme.bodyMedium,
                                  decoration: InputDecoration(
                                    hintText: _isListening ? 'Listening...' : 'Ask Nova...',
                                    hintStyle: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onChanged: (text) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: _isListening 
                                        ? [Colors.redAccent, Colors.red]
                                        : [colorScheme.primary, colorScheme.secondary],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isListening ? Colors.red : colorScheme.primary).withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      _controller.text.isEmpty && !_isListening ? Icons.mic : (_isListening ? Icons.stop : Icons.send), 
                                      color: colorScheme.surface,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      if (_isListening) {
                                        _stopListening();
                                      } else if (_controller.text.isEmpty) {
                                        _startListening();
                                      } else {
                                        _sendMessage(_controller.text);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text, IconData icon, bool isPrimary) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return InkWell(
      onTap: () => _sendMessage(text),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? colorScheme.primary.withValues(alpha: 0.1) : colorScheme.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isPrimary ? colorScheme.primary.withValues(alpha: 0.4) : colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isPrimary ? colorScheme.primary : colorScheme.onSurface),
            const SizedBox(width: 8),
            Text(
              text,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isPrimary ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: message.isCoach ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isCoach) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outlineVariant),
                boxShadow: [
                  BoxShadow(color: colorScheme.secondaryContainer.withValues(alpha: 0.3), blurRadius: 15),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/nova_avatar.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: message.isCoach 
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colorScheme.surfaceContainerHigh, colorScheme.surfaceContainer],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colorScheme.primary, colorScheme.primaryContainer],
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isCoach ? 4 : 16),
                  bottomRight: Radius.circular(message.isCoach ? 16 : 4),
                ),
                border: message.isCoach ? Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)) : null,
                boxShadow: message.isCoach ? [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 4))
                ] : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: message.isCoach ? colorScheme.onSurface : colorScheme.onPrimary,
                      fontWeight: message.isCoach ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  if (message.hasSnippet) ...[
                    const SizedBox(height: 16),
                    _buildFinanceSnippet(),
                  ],
                ],
              ),
            ),
          ),
          if (!message.isCoach) const SizedBox(width: 48), // Padding equivalent to coach avatar space
        ],
      ),
    );
  }

  Widget _buildFinanceSnippet() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LAPTOP FUND PROJECTION', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text('\$1,254.30', style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              Transform.rotate(
                angle: -0.785, // -45 degrees
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surfaceContainerHighest, width: 4),
                  ),
                  child: Center(
                    child: Icon(Icons.trending_up, color: colorScheme.primary, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Mock Bar Chart
          SizedBox(
            height: 80,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [colorScheme.primary.withValues(alpha: 0.1), Colors.transparent],
                    ),
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (int i = 0; i < 6; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Container(
                            height: 20.0 + (i * 12.0),
                            decoration: BoxDecoration(
                              color: i == 5 ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0.3 + (i * 0.1)),
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(2), topRight: Radius.circular(2)),
                              boxShadow: i == 5 ? [
                                BoxShadow(color: colorScheme.primary.withValues(alpha: 0.5), blurRadius: 10)
                              ] : [],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Now', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant, fontSize: 10)),
              Text('12 mo', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/nova_avatar.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(delay: 0),
                SizedBox(width: 4),
                _TypingDot(delay: 200),
                SizedBox(width: 4),
                _TypingDot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -4 * _controller.value),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}



