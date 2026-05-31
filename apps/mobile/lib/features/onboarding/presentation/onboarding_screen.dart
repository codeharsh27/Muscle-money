import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/onboarding_repository.dart';
import 'onboarding_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _incomeController = TextEditingController(text: '10000');
  final Set<String> _goals = {'Build emergency fund'};
  String _riskProfile = 'BALANCED';
  String _knowledgeLevel = 'BEGINNER';
  String _learningPace = 'daily';
  String _spendingPattern = 'moderate';

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final income = int.tryParse(_incomeController.text.trim());
    if (_goals.isEmpty || income == null || income < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a goal and enter valid monthly income')),
      );
      return;
    }

    await ref.read(onboardingControllerProvider.notifier).complete(
          OnboardingPayload(
            financialGoals: _goals.toList(),
            riskProfile: _riskProfile,
            knowledgeLevel: _knowledgeLevel,
            monthlyIncomeMinor: income * 100,
            spendingHabits: {'pattern': _spendingPattern},
            learningPreferences: {'pace': _learningPace},
          ),
        );

    if (!mounted) return;
    final state = ref.read(onboardingControllerProvider);
    if (state.hasValue && state.value?.completed == true) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final isLoading = state.isLoading;
    final error = state.hasError
        ? ref.read(onboardingControllerProvider.notifier).errorMessage(state.error!)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Personalize Muscle Money')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Your finance training plan', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            _Section(
              title: 'Goals',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _goalChip('Build emergency fund'),
                  _goalChip('Learn investing'),
                  _goalChip('Save monthly'),
                  _goalChip('Avoid debt'),
                ],
              ),
            ),
            _Section(
              title: 'Risk profile',
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'CONSERVATIVE', label: Text('Safe')),
                  ButtonSegment(value: 'BALANCED', label: Text('Balanced')),
                  ButtonSegment(value: 'AGGRESSIVE', label: Text('Growth')),
                ],
                selected: {_riskProfile},
                onSelectionChanged: (value) => setState(() => _riskProfile = value.first),
              ),
            ),
            _Section(
              title: 'Knowledge level',
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'BEGINNER', label: Text('Beginner')),
                  ButtonSegment(value: 'INTERMEDIATE', label: Text('Medium')),
                  ButtonSegment(value: 'ADVANCED', label: Text('Advanced')),
                ],
                selected: {_knowledgeLevel},
                onSelectionChanged: (value) => setState(() => _knowledgeLevel = value.first),
              ),
            ),
            _Section(
              title: 'Monthly income',
              child: TextField(
                controller: _incomeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(prefixText: 'INR ', labelText: 'Approx monthly income'),
              ),
            ),
            _Section(
              title: 'Habits and pace',
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _spendingPattern,
                    decoration: const InputDecoration(labelText: 'Spending pattern'),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low spending')),
                      DropdownMenuItem(value: 'moderate', child: Text('Moderate spending')),
                      DropdownMenuItem(value: 'high', child: Text('High spending')),
                    ],
                    onChanged: (value) => setState(() => _spendingPattern = value ?? _spendingPattern),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _learningPace,
                    decoration: const InputDecoration(labelText: 'Learning pace'),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'alternate_days', child: Text('Alternate days')),
                      DropdownMenuItem(value: 'weekends', child: Text('Weekends')),
                    ],
                    onChanged: (value) => setState(() => _learningPace = value ?? _learningPace),
                  ),
                ],
              ),
            ),
            if (error != null) Text(error, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : _complete,
              child: isLoading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Build my plan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalChip(String goal) {
    final selected = _goals.contains(goal);
    return FilterChip(
      label: Text(goal),
      selected: selected,
      onSelected: (value) {
        setState(() {
          if (value) {
            _goals.add(goal);
          } else {
            _goals.remove(goal);
          }
        });
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
