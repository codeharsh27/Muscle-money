import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/formatters/money_format.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/dashboard_repository.dart';

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) {
  return ref.watch(dashboardRepositoryProvider).load();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => context.push('/profile'),
              child: Hero(
                tag: 'profile_avatar',
                child: CircleAvatar(
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                  child: Text(
                    _initialFor(user?.fullName),
                    style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                  Text(
                    _firstNameFor(user?.fullName),
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          summary.maybeWhen(
            data: (data) => _StreakPill(streakCount: data.streakCount),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
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
          child: RefreshIndicator(
            color: colorScheme.primary,
            backgroundColor: const Color(0xFF1B1429),
            onRefresh: () async {
              ref.invalidate(dashboardSummaryProvider);
              await ref.read(dashboardSummaryProvider.future);
            },
            child: summary.when(
              data: (data) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                  children: [
                    // Golden Hero (Savings)
                    _GoldenWalletCard(balanceMinor: data.monthlySavingsMinor),
                    const SizedBox(height: 24),

                    // Daily Motivation
                    const _DailyMotivation(),
                    const SizedBox(height: 32),

                    // Habit Progress Graph
                    _HabitProgressGraph(progressHistory: data.progressHistory),
                    const SizedBox(height: 32),
                    
                    // Learn Concept Card
                    _LearnConceptCard(
                      onLearnTap: () {
                        // Navigate to Learn tab
                        context.go('/learning');
                      },
                    ),
                  ],
                );
              },
              error: (_, __) => const Center(
                child: Text('Dashboard unavailable. Pull to refresh.', style: TextStyle(color: Colors.white54)),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.greenAccent),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// Golden Wallet Card
// ---------------------------------------------------------

class _GoldenWalletCard extends StatelessWidget {
  final int balanceMinor;
  const _GoldenWalletCard({required this.balanceMinor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFDF73), // Bright Gold
            Color(0xFFE5B53B), // Rich Gold
            Color(0xFFB57E10), // Deep Gold
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5B53B).withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.account_balance_wallet, color: Colors.black87, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text('TOTAL SAVINGS', style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatMinorMoney(balanceMinor, currency: '₹'),
              style: const TextStyle(color: Colors.black87, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to wallet or open save modal
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: const Color(0xFFFFDF73),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('+ ADD NEW SAVE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
            ),
          )
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// Daily Motivation
// ---------------------------------------------------------

class _DailyMotivation extends StatelessWidget {
  const _DailyMotivation();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.format_quote, color: Colors.white.withValues(alpha: 0.2), size: 40),
        const SizedBox(height: 8),
        const Text(
          "Discipline is the bridge between goals and accomplishment. Keep saving steadily, day by day.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontStyle: FontStyle.italic,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// Habit Progress Graph
// ---------------------------------------------------------

class _HabitProgressGraph extends StatelessWidget {
  final List<int> progressHistory;
  const _HabitProgressGraph({required this.progressHistory});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Icon(Icons.trending_up, color: Colors.greenAccent, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'DISCIPLINE SCORE',
              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Your learning and saving habits are compounding!',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 140,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    progressHistory.length,
                    (i) => FlSpot(i.toDouble(), progressHistory[i].toDouble()),
                  ),
                  isCurved: true,
                  color: Colors.greenAccent,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.greenAccent.withValues(alpha: 0.3),
                        Colors.greenAccent.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// Learn Concept Card
// ---------------------------------------------------------

class _LearnConceptCard extends StatelessWidget {
  final VoidCallback onLearnTap;
  const _LearnConceptCard({required this.onLearnTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.school, color: Colors.lightBlueAccent, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'CONCEPT OF THE DAY',
                    style: TextStyle(color: Colors.lightBlueAccent, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'The Power of Compound Interest',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Understand how your small, consistent savings can snowball into massive wealth over time.',
                style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: onLearnTap,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.lightBlueAccent, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Start Lesson', style: TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// Helpers
// ---------------------------------------------------------

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning,';
  if (hour < 17) return 'Good afternoon,';
  return 'Good evening,';
}

String _firstNameFor(String? fullName) {
  final trimmed = fullName?.trim();
  if (trimmed == null || trimmed.isEmpty) return 'User';
  return trimmed.split(RegExp(r'\s+')).first;
}

String _initialFor(String? fullName) {
  final firstName = _firstNameFor(fullName);
  return firstName.substring(0, 1).toUpperCase();
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.streakCount});
  final int streakCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 18),
          const SizedBox(width: 6),
          Text(
            '$streakCount',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
