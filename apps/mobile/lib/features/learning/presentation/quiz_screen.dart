import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/learning_repository.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final QuizItem quiz;

  const QuizScreen({required this.quiz, super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> with SingleTickerProviderStateMixin {
  String? _selectedOptionId;
  bool _isSubmitted = false;
  bool _isSubmitting = false;
  QuizAttemptResult? _result;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedOptionId == null) return;
    setState(() => _isSubmitting = true);
    try {
      final result = await ref.read(learningRepositoryProvider).submitQuiz(widget.quiz.id, [_selectedOptionId!]);
      setState(() {
        _result = result;
        _isSubmitted = true;
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final isCorrect = _result?.isCorrect ?? false;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _buildProgressStepper(context),
        actions: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
              const SizedBox(width: 4),
              Text('12', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
            ],
          )
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 120),
            children: [
              // Topic Tag
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.school, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 6),
                      Text('INVESTING BASICS', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Question
              Text(
                widget.quiz.question,
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              
              // Options
              ...widget.quiz.options.map((option) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _OptionButton(
                  option: option,
                  isSelected: _selectedOptionId == option.id,
                  isSubmitted: _isSubmitted,
                  isCorrect: isCorrect && option.id == _selectedOptionId,
                  onTap: () {
                    if (!_isSubmitted) {
                      setState(() {
                        _selectedOptionId = option.id;
                      });
                    }
                  },
                ),
              )),
            ],
          ),
          
          // Fixed Bottom Action Area
          if (_selectedOptionId != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(context).padding.bottom + 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.8),
                      border: Border(top: BorderSide(color: colorScheme.surfaceContainerHighest)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isSubmitted)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.stars, color: isCorrect ? Colors.amber : colorScheme.error, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  isCorrect
                                      ? 'You\'re on a roll! +${_result?.xpAwarded ?? 0} XP'
                                      : 'Not quite. Review the lesson and try again.',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: _isSubmitted && isCorrect ? [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(alpha: 0.2 + (_pulseController.value * 0.4)),
                                      blurRadius: 15 + (_pulseController.value * 10),
                                      spreadRadius: 2,
                                    )
                                  ] : [],
                                ),
                                child: child,
                              );
                            },
                            child: ElevatedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : _isSubmitted
                                      ? () => Navigator.of(context).pop()
                                      : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isSubmitted ? colorScheme.surfaceContainerHigh : colorScheme.primary,
                                foregroundColor: _isSubmitted ? colorScheme.onSurface : colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text(
                                _isSubmitting ? 'Checking...' : (_isSubmitted ? 'Continue' : 'Check Answer'), 
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                              ),
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

  Widget _buildProgressStepper(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Container(
                width: constraints.maxWidth * 0.75, // MOCK progress
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final QuizOption option;
  final bool isSelected;
  final bool isSubmitted;
  final bool isCorrect;
  final VoidCallback onTap;

  const _OptionButton({
    required this.option,
    required this.isSelected,
    required this.isSubmitted,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Determine state
    final bool showCorrect = isSubmitted && isCorrect;
    final bool showIncorrect = isSubmitted && isSelected && !isCorrect;
    final bool dimOthers = isSubmitted && !isSelected && !showCorrect;

    // Colors based on state
    final borderColor = showCorrect 
        ? colorScheme.primary 
        : showIncorrect 
            ? colorScheme.error 
            : isSelected 
                ? colorScheme.primary 
                : Colors.transparent;
                
    final bgColor = showCorrect 
        ? colorScheme.primaryContainer.withValues(alpha: 0.2)
        : showIncorrect
            ? colorScheme.errorContainer.withValues(alpha: 0.2)
            : isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.1)
                : colorScheme.surfaceContainer;

    // Icons mapping based on index or text (mocking the stitch design icons)
    IconData iconData = Icons.pie_chart;
    if (option.text.toLowerCase().contains('stock')) iconData = Icons.trending_up;
    if (option.text.toLowerCase().contains('account')) iconData = Icons.account_balance;
    if (option.text.toLowerCase().contains('debt')) iconData = Icons.payments;

    return Opacity(
      opacity: dimOthers ? 0.4 : 1.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: isSelected && !isSubmitted ? [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ] : [],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: showCorrect 
                      ? colorScheme.primary.withValues(alpha: 0.2)
                      : showIncorrect
                          ? colorScheme.error.withValues(alpha: 0.2)
                          : isSelected
                              ? colorScheme.primary.withValues(alpha: 0.2)
                              : colorScheme.surfaceContainerHighest,
                ),
                child: Icon(
                  iconData, 
                  color: showCorrect 
                      ? colorScheme.primary
                      : showIncorrect
                          ? colorScheme.error
                          : isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option.text,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (showCorrect)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary,
                  ),
                  child: Icon(Icons.check, color: colorScheme.onPrimary, size: 20),
                ),
              if (showIncorrect)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.error,
                  ),
                  child: Icon(Icons.close, color: colorScheme.onError, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

