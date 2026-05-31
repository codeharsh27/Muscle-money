import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/learning_repository.dart';
import 'ai_coach_screen.dart';
import 'lesson_detail_screen.dart';

final lessonsProvider = FutureProvider<List<LessonSummary>>((ref) {
  return ref.watch(learningRepositoryProvider).lessons();
});

class LearningScreen extends ConsumerStatefulWidget {
  const LearningScreen({super.key});

  @override
  ConsumerState<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends ConsumerState<LearningScreen> {
  String? _selectedJourney;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessonsAsync = ref.watch(lessonsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Missions',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: lessonsAsync.when(
        data: (allLessons) {
          if (allLessons.isEmpty) {
            return const Center(
                child: Text('No missions available right now.'));
          }
          final completed = allLessons.where((l) => l.completed).length;
          final total = allLessons.length;
          final started = allLessons.where((l) => l.completionPercent > 0).length;

          // Extract unique tracks (Journeys)
          final journeys = allLessons.map((l) => l.track).toSet().toList();
          
          // Filter lessons based on selection
          final lessons = _selectedJourney == null 
              ? allLessons 
              : allLessons.where((l) => l.track == _selectedJourney).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _HealthRings(
                  completed: completed, total: total, started: started),
              const SizedBox(height: 24),
              
              // Feature: Learning Journeys (Horizontal Filter)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "LEARNING JOURNEYS",
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: journeys.length + 1,
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final journeyName = isAll ? "All Missions" : journeys[index - 1];
                    final isSelected = isAll ? _selectedJourney == null : _selectedJourney == journeyName;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(journeyName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedJourney = isAll ? null : journeyName;
                          });
                        },
                        selectedColor: colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    
                    // Identify if this is the highest priority incomplete mission globally
                    // Only highlight "Today's Mission" if we are viewing ALL missions
                    final firstIncompleteIndex = allLessons.indexWhere((l) => !l.completed);
                    final isTodayMissionGlobally = firstIncompleteIndex != -1 && lesson.slug == allLessons[firstIncompleteIndex].slug;
                    final isTodayMission = _selectedJourney == null && isTodayMissionGlobally;
                    
                    final isUpNext = _selectedJourney == null && firstIncompleteIndex != -1 && index == 1;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isTodayMission) ...[
                          Row(
                            children: [
                              Icon(Icons.local_fire_department, color: colorScheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Text("TODAY'S MONEY MISSION", style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: colorScheme.primary)),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (isUpNext) ...[
                           const SizedBox(height: 16),
                           Text("YOUR LEARNING FEED", style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: colorScheme.onSurfaceVariant)),
                           const SizedBox(height: 16),
                        ],
                        if (index == 0 && _selectedJourney == null && firstIncompleteIndex == -1) ...[
                           Text("COMPLETED MISSIONS", style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: colorScheme.onSurfaceVariant)),
                           const SizedBox(height: 16),
                        ],
                        _ActionCard(
                          lesson: lesson,
                          onActionCompleted: () {
                            ref.invalidate(lessonsProvider);
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
        error: (error, _) =>
            Center(child: Text('Error loading missions: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _HealthRings extends StatelessWidget {
  const _HealthRings({
    required this.completed,
    required this.total,
    required this.started,
  });

  final int completed;
  final int total;
  final int started;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final knowledgeProgress =
        total == 0 ? 0.0 : (started + completed) / (total * 2);
    final practiceProgress = total == 0 ? 0.0 : started / total;
    final realityProgress = total == 0 ? 0.0 : completed / total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _RingIndicator(
            progress: knowledgeProgress,
            color: Colors.blueAccent,
            label: 'Knowledge',
            icon: Icons.lightbulb_outline,
          ),
          _RingIndicator(
            progress: practiceProgress,
            color: Colors.purpleAccent,
            label: 'Practice',
            icon: Icons.videogame_asset_outlined,
          ),
          _RingIndicator(
            progress: realityProgress,
            color: colorScheme.primary,
            label: 'Reality',
            icon: Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }
}

class _RingIndicator extends StatelessWidget {
  const _RingIndicator({
    required this.progress,
    required this.color,
    required this.label,
    required this.icon,
  });

  final double progress;
  final Color color;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: colorScheme.outlineVariant.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Icon(icon, color: color, size: 28),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _ActionCard extends ConsumerStatefulWidget {
  const _ActionCard({required this.lesson, required this.onActionCompleted});

  final LessonSummary lesson;
  final VoidCallback onActionCompleted;

  @override
  ConsumerState<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends ConsumerState<_ActionCard> {
  bool _isFlipped = false;
  bool _isLoading = false;

  Future<void> _completeAction() async {
    final action = widget.lesson.action;
    if (action == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ref.read(learningRepositoryProvider).completeAction(
            lessonSlug: widget.lesson.slug,
            actionKey: action.key,
            actionType: action.type,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Awesome! Earned ${result.xpAwarded} XP & ₹10,000 Simulator Cash!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onActionCompleted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete action: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final action = widget.lesson.action;

    return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(32),
          border:
              Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.surface,
                      colorScheme.surface.withOpacity(0.8)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.rocket_launch, // Fallback icon
                            color: colorScheme.primary,
                            size: 32,
                          ),
                        ),
                        if (widget.lesson.completed)
                          Icon(Icons.check_circle,
                              color: colorScheme.primary, size: 28),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.lesson.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.lesson.summary,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Colors.white10),

              // Core Concept
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ConceptRow(
                      icon: Icons.cancel_outlined,
                      iconColor: Colors.redAccent,
                      title: 'Before',
                      text: widget.lesson.before,
                    ),
                    const SizedBox(height: 24),
                    _ConceptRow(
                      icon: Icons.check_circle_outline,
                      iconColor: Colors.greenAccent,
                      title: 'After',
                      text: widget.lesson.after,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'The Scenario',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: colorScheme.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.lesson.scenario,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),

              // Action Drawer
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(top: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final shouldRefresh = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LessonDetailScreen(slug: widget.lesson.slug),
                          ),
                        );
                        if (shouldRefresh == true) {
                          widget.onActionCompleted();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.lesson.completed ? colorScheme.surfaceContainerHighest : colorScheme.primary,
                        foregroundColor: widget.lesson.completed ? Colors.white : colorScheme.onPrimary,
                      ),
                      child: Text(widget.lesson.completed ? 'Review Mission' : 'Start Mission'),
                    )
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}

class _ConceptRow extends StatelessWidget {
  const _ConceptRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white54, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
