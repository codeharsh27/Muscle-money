import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/learning_repository.dart';

final lessonDetailProvider = FutureProvider.family<LessonDetail, String>((ref, slug) {
  return ref.watch(learningRepositoryProvider).lesson(slug);
});

class LessonDetailScreen extends ConsumerStatefulWidget {
  const LessonDetailScreen({required this.slug, super.key});
  final String slug;

  @override
  ConsumerState<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends ConsumerState<LessonDetailScreen> {
  // Quiz State
  String? _selectedOptionId;
  bool _isQuizSubmitted = false;
  bool _isQuizSubmitting = false;
  bool _isQuizCorrect = false;
  int _xpAwarded = 0;

  // Action State
  bool _isActionSubmitting = false;
  bool _isActionCompleted = false;

  Future<void> _submitQuiz(String quizId) async {
    if (_selectedOptionId == null) return;
    setState(() => _isQuizSubmitting = true);
    try {
      final result = await ref.read(learningRepositoryProvider).submitQuiz(quizId, [_selectedOptionId!]);
      if (mounted) {
        setState(() {
          _isQuizCorrect = result.isCorrect;
          _xpAwarded = result.xpAwarded;
          _isQuizSubmitted = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isQuizSubmitting = false);
      }
    }
  }

  Future<void> _completeAction(LessonDetail lesson) async {
    final action = lesson.action;
    if (action == null) return;

    setState(() => _isActionSubmitting = true);
    try {
      final result = await ref.read(learningRepositoryProvider).completeAction(
        lessonSlug: lesson.slug,
        actionKey: action.key,
        actionType: action.type,
      );
      if (mounted) {
        setState(() => _isActionCompleted = true);
        _showSuccessDialog(result.xpAwarded);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isActionSubmitting = false);
      }
    }
  }

  void _showSuccessDialog(int xp) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Icon(Icons.stars, color: Colors.amber, size: 64),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Mission Accomplished!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('You earned $xp XP and ₹10,000 Simulator Cash.', textAlign: TextAlign.center),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // pop dialog
                Navigator.of(context).pop(true); // pop screen, signal refresh
              },
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
              child: const Text('Awesome'),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncDetail = ref.watch(lessonDetailProvider(widget.slug));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: asyncDetail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (lesson) {
          final quiz = lesson.quizzes.isNotEmpty ? lesson.quizzes.first : null;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.surface, colorScheme.primary.withOpacity(0.2)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.rocket_launch, size: 80, color: colorScheme.primary.withOpacity(0.5)),
                    ),
                  ),
                ),
              ),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sections
                      for (final section in lesson.sections) ...[
                        Text(
                          section.heading,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          section.body,
                          style: theme.textTheme.bodyLarge?.copyWith(height: 1.6, color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 32),
                      ],

                      const Divider(height: 48),

                      // Layer 2: Interactive Practice
                      Row(
                        children: [
                          const Icon(Icons.touch_app, color: Colors.purpleAccent),
                          const SizedBox(width: 8),
                          Text('Interactive Practice', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text("Try allocating a ₹50,000 monthly salary. Aim for the 50/30/20 rule (50% Needs, 30% Wants, 20% Savings).", style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 24),
                      const _BudgetBuilderInteractive(),
                      const SizedBox(height: 32),

                      const Divider(height: 48),

                      // Quiz Checkpoint
                      if (quiz != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.quiz, color: Colors.amber),
                            const SizedBox(width: 8),
                            Text('Knowledge Checkpoint', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(quiz.question, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 24),
                        
                        for (final option in quiz.options) ...[
                          _QuizOptionCard(
                            text: option.text,
                            isSelected: _selectedOptionId == option.id,
                            isSubmitted: _isQuizSubmitted,
                            isCorrect: _isQuizCorrect && _selectedOptionId == option.id,
                            onTap: _isQuizSubmitted && _isQuizCorrect ? null : () {
                              setState(() {
                                _selectedOptionId = option.id;
                                _isQuizSubmitted = false;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                        
                        const SizedBox(height: 16),
                        
                        if (_isQuizSubmitted && !_isQuizCorrect)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              'Not quite right. Try again!',
                              style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold),
                            ),
                          ),

                        if (!_isQuizSubmitted || !_isQuizCorrect)
                          ElevatedButton(
                            onPressed: _selectedOptionId == null || _isQuizSubmitting ? null : () => _submitQuiz(quiz.id),
                            child: _isQuizSubmitting ? const CircularProgressIndicator() : const Text('Check Answer'),
                          ),
                      ],

                      // Real World Mission (Unlocked after Quiz)
                      if ((quiz == null || _isQuizCorrect) && lesson.action != null && !_isActionCompleted) ...[
                        const Divider(height: 64),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.lock_open, color: colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text('Mission Unlocked!', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(lesson.action!.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(lesson.action!.description, style: theme.textTheme.bodyMedium),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _isActionSubmitting ? null : () => _completeAction(lesson),
                                icon: const Icon(Icons.flash_on),
                                label: _isActionSubmitting ? const CircularProgressIndicator() : Text(lesson.action!.buttonLabel),
                              )
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuizOptionCard extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool isSubmitted;
  final bool isCorrect;
  final VoidCallback? onTap;

  const _QuizOptionCard({
    required this.text,
    required this.isSelected,
    required this.isSubmitted,
    required this.isCorrect,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final bool showCorrect = isSubmitted && isCorrect;
    final bool showIncorrect = isSubmitted && isSelected && !isCorrect;

    final borderColor = showCorrect 
        ? colorScheme.primary 
        : showIncorrect 
            ? colorScheme.error 
            : isSelected 
                ? colorScheme.primary 
                : colorScheme.outlineVariant.withOpacity(0.5);
                
    final bgColor = showCorrect 
        ? colorScheme.primary.withOpacity(0.2)
        : showIncorrect
            ? colorScheme.error.withOpacity(0.2)
            : isSelected
                ? colorScheme.primary.withOpacity(0.1)
                : colorScheme.surface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (showCorrect) Icon(Icons.check_circle, color: colorScheme.primary),
            if (showIncorrect) Icon(Icons.cancel, color: colorScheme.error),
          ],
        ),
      ),
    );
  }
}

class _BudgetBuilderInteractive extends StatefulWidget {
  const _BudgetBuilderInteractive();

  @override
  State<_BudgetBuilderInteractive> createState() => _BudgetBuilderInteractiveState();
}

class _BudgetBuilderInteractiveState extends State<_BudgetBuilderInteractive> {
  double _needs = 25000;
  double _wants = 15000;
  double _savings = 10000;
  final double _total = 50000;

  void _updateNeeds(double value) {
    setState(() {
      _needs = value;
      _adjustOthers(needsChanged: true);
    });
  }

  void _updateWants(double value) {
    setState(() {
      _wants = value;
      _adjustOthers(wantsChanged: true);
    });
  }

  void _updateSavings(double value) {
    setState(() {
      _savings = value;
      _adjustOthers(savingsChanged: true);
    });
  }

  void _adjustOthers({bool needsChanged = false, bool wantsChanged = false, bool savingsChanged = false}) {
    double currentTotal = _needs + _wants + _savings;
    if (currentTotal == _total) return;

    double diff = currentTotal - _total;
    
    if (needsChanged) {
      if (_wants >= diff && _wants > 0) {
        _wants -= diff;
      } else {
        diff -= _wants;
        _wants = 0;
        _savings -= diff;
      }
    } else if (wantsChanged) {
      if (_needs >= diff && _needs > 0) {
        _needs -= diff;
      } else {
        diff -= _needs;
        _needs = 0;
        _savings -= diff;
      }
    } else if (savingsChanged) {
      if (_wants >= diff && _wants > 0) {
        _wants -= diff;
      } else {
        diff -= _wants;
        _wants = 0;
        _needs -= diff;
      }
    }

    _needs = _needs.clamp(0, _total);
    _wants = _wants.clamp(0, _total);
    _savings = _savings.clamp(0, _total);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    bool isPerfect = _needs == 25000 && _wants == 15000 && _savings == 10000;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Salary', style: TextStyle(color: colorScheme.onSurfaceVariant)),
              Text('₹${_total.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 24),
          _buildSlider('Needs (50%)', _needs, colorScheme.primary, _updateNeeds),
          _buildSlider('Wants (30%)', _wants, Colors.orange, _updateWants),
          _buildSlider('Savings (20%)', _savings, Colors.green, _updateSavings),
          
          if (isPerfect) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Perfect 50/30/20 balance!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, Color color, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('₹${value.toInt()}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.2),
            thumbColor: color,
            trackHeight: 8,
          ),
          child: Slider(
            value: value,
            min: 0,
            max: _total,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
