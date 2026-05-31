import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../data/onboarding_repository.dart';
import 'onboarding_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _incomeController = TextEditingController();
  final Set<String> _goals = {'Build emergency fund'};
  String _riskProfile = 'BALANCED';
  String _knowledgeLevel = 'BEGINNER';

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final income = int.tryParse(_incomeController.text.trim());
    if (_goals.isEmpty || income == null || income <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a goal and enter a valid monthly income', style: GoogleFonts.spaceGrotesk()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    await ref.read(onboardingControllerProvider.notifier).complete(
          OnboardingPayload(
            financialGoals: _goals.toList(),
            riskProfile: _riskProfile,
            knowledgeLevel: _knowledgeLevel,
            monthlyIncomeMinor: income * 100,
            spendingHabits: {'pattern': 'moderate'},
            learningPreferences: {'pace': 'daily'},
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Personalize Nova', 
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)
        ).animate().fadeIn(delay: 200.ms),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F111A),
              Color(0xFF1B1429),
              Color(0xFF071B1A),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            children: [
              Text(
                'Help Nova build your custom financial roadmap.',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 16),
              ).animate().slideY(begin: 0.3, end: 0, delay: 100.ms, duration: 500.ms, curve: Curves.easeOutCubic).fadeIn(),
              const SizedBox(height: 40),

              _buildPremiumSection(
                title: 'Monthly Income (INR)',
                delay: 200.ms,
                child: TextFormField(
                  controller: _incomeController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: GoogleFonts.spaceGrotesk(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.greenAccent, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              _buildPremiumSection(
                title: 'Primary Goals',
                delay: 300.ms,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildPill('Build emergency fund', Icons.health_and_safety_rounded),
                    _buildPill('Learn investing', Icons.trending_up_rounded),
                    _buildPill('Save monthly', Icons.savings_rounded),
                    _buildPill('Avoid debt', Icons.money_off_rounded),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              _buildPremiumSection(
                title: 'Risk Profile',
                delay: 400.ms,
                child: Row(
                  children: [
                    _buildSelectionCard('Safe', 'CONSERVATIVE', _riskProfile, (v) => setState(() => _riskProfile = v), Icons.shield_rounded),
                    const SizedBox(width: 12),
                    _buildSelectionCard('Balanced', 'BALANCED', _riskProfile, (v) => setState(() => _riskProfile = v), Icons.balance_rounded),
                    const SizedBox(width: 12),
                    _buildSelectionCard('Growth', 'AGGRESSIVE', _riskProfile, (v) => setState(() => _riskProfile = v), Icons.rocket_launch_rounded),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              _buildPremiumSection(
                title: 'Finance Knowledge',
                delay: 500.ms,
                child: Row(
                  children: [
                    _buildSelectionCard('Beginner', 'BEGINNER', _knowledgeLevel, (v) => setState(() => _knowledgeLevel = v), Icons.school_outlined),
                    const SizedBox(width: 12),
                    _buildSelectionCard('Medium', 'INTERMEDIATE', _knowledgeLevel, (v) => setState(() => _knowledgeLevel = v), Icons.menu_book_rounded),
                    const SizedBox(width: 12),
                    _buildSelectionCard('Pro', 'ADVANCED', _knowledgeLevel, (v) => setState(() => _knowledgeLevel = v), Icons.psychology_rounded),
                  ],
                ),
              ),

              if (error != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          error, 
                          style: GoogleFonts.spaceGrotesk(color: Colors.redAccent, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ).animate().shakeX(duration: 400.ms),
              ],

              const SizedBox(height: 48),
              
              // Build Plan Button
              Container(
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00FFA3), Color(0xFF00B8FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF00FFA3).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: isLoading ? null : _complete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: isLoading
                      ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black87))
                      : Text('Build My Plan', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 0.5)),
                ),
              ).animate().slideY(begin: 0.3, end: 0, delay: 600.ms, duration: 500.ms, curve: Curves.easeOutCubic).fadeIn(delay: 600.ms),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumSection({required String title, required Widget child, required Duration delay}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 16),
        child,
      ],
    ).animate().slideX(begin: -0.1, end: 0, delay: delay, duration: 500.ms, curve: Curves.easeOutCubic).fadeIn(delay: delay);
  }

  Widget _buildPill(String goal, IconData icon) {
    final isSelected = _goals.contains(goal);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _goals.remove(goal);
          } else {
            _goals.add(goal);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.greenAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.greenAccent : Colors.white.withValues(alpha: 0.1), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: isSelected ? Colors.greenAccent : Colors.white54),
            const SizedBox(width: 8),
            Text(
              goal,
              style: GoogleFonts.spaceGrotesk(
                color: isSelected ? Colors.greenAccent : Colors.white70,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCard(String label, String value, String groupValue, ValueChanged<String> onSelect, IconData icon) {
    final isSelected = value == groupValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00B8FF).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? const Color(0xFF00B8FF) : Colors.white.withValues(alpha: 0.1), width: 1.5),
            boxShadow: isSelected ? [
              BoxShadow(color: const Color(0xFF00B8FF).withValues(alpha: 0.2), blurRadius: 15, spreadRadius: -5),
            ] : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: isSelected ? const Color(0xFF00B8FF) : Colors.white38),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  color: isSelected ? const Color(0xFF00B8FF) : Colors.white70,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
