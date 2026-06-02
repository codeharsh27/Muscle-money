import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/money_format.dart';
import 'dashboard_screen.dart'; // To access dashboardSummaryProvider

class StreakScreen extends ConsumerWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Your Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F111A),
              Color(0xFF1B1429),
            ],
          ),
        ),
        child: summaryAsync.when(
          data: (data) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 48),
              children: [
                _buildHeroStreak(data.streakCount),
                const SizedBox(height: 48),
                const Text(
                  'DISCIPLINE BREAKDOWN',
                  style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  title: 'Total Learning Time',
                  value: '${data.totalLearningMinutes} mins',
                  subtitle: '${data.lessonsCompleted} lessons completed',
                  icon: Icons.school,
                  iconColor: Colors.lightBlueAccent,
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  title: 'Simulator Portfolio',
                  value: formatMinorMoney(data.simulatorEquityMinor, currency: '₹'),
                  subtitle: '${data.openPositions} open positions in the market',
                  icon: Icons.candlestick_chart,
                  iconColor: Colors.greenAccent,
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  title: 'Financial Score',
                  value: '${data.financialScore} / 100',
                  subtitle: 'Based on savings ratio & habits',
                  icon: Icons.score,
                  iconColor: Colors.orangeAccent,
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
          error: (_, __) => const Center(child: Text('Failed to load progress.', style: TextStyle(color: Colors.white54))),
        ),
      ),
    );
  }

  Widget _buildHeroStreak(int streakCount) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.orangeAccent.withValues(alpha: 0.1),
            boxShadow: [
              BoxShadow(
                color: Colors.orangeAccent.withValues(alpha: 0.2),
                blurRadius: 50,
                spreadRadius: 10,
              ),
            ],
          ),
          child: const Icon(
            Icons.local_fire_department,
            color: Colors.orangeAccent,
            size: 80,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '$streakCount Day Streak',
          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
        ),
        const SizedBox(height: 8),
        const Text(
          'Consistency is the key to compounding wealth.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
