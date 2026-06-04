import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/formatters/money_format.dart';
import '../../dashboard/data/dashboard_repository.dart';

class TimeMachineTab extends ConsumerStatefulWidget {
  const TimeMachineTab({super.key});

  @override
  ConsumerState<TimeMachineTab> createState() => _TimeMachineTabState();
}

class _TimeMachineTabState extends ConsumerState<TimeMachineTab> {
  double _investmentPercent = 0.5; // 50%
  static const int _years = 15;
  static const double _annualReturnRate = 0.12;

  double _calculateFutureValue(double monthlyInvestment, int years, double annualRate) {
    if (monthlyInvestment <= 0) return 0;
    final r = annualRate / 12;
    final n = years * 12;
    return monthlyInvestment * ((pow(1 + r, n) - 1) / r);
  }

  String _getNovaCommentary(double percent) {
    if (percent == 0.0) {
      return "Danger! You're spending all your cash. The future looks a bit stressed! 😰";
    } else if (percent < 0.25) {
      return "It's a start, but we can do better! Every rupee counts for your future. 🌱";
    } else if (percent < 0.5) {
      return "Solid effort! You're building a nice safety net. Keep it up! 📈";
    } else if (percent < 0.75) {
      return "Whoa! You're on track for some serious wealth. Future you is smiling! 🚀";
    } else {
      return "Incredible! You just unlocked early retirement. You're a money master! 👑";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dashboardAsync = ref.watch(dashboardSummaryProvider);

    return dashboardAsync.when(
      data: (summary) {
        final monthlySpending = (summary.monthlySpendingsMinor > 0) 
            ? summary.monthlySpendingsMinor / 100 
            : 5000.0;
        
        final monthlyInvestment = monthlySpending * _investmentPercent;
        final futureValue = _calculateFutureValue(monthlyInvestment, _years, _annualReturnRate);
        final totalInvested = monthlyInvestment * _years * 12;

        return Column(
          children: [
            const SizedBox(height: 16),
            // Nova Commentary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: const AssetImage('assets/images/nova_avatar.png'),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _getNovaCommentary(_investmentPercent),
                          key: ValueKey(_getNovaCommentary(_investmentPercent)),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // The Reality Check Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REALITY CHECK',
                    style: theme.textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                      children: [
                        const TextSpan(text: 'You spent '),
                        TextSpan(
                          text: formatMinorMoney((monthlySpending * 100).toInt(), currency: '₹'),
                          style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' last month.\nWhat if you invested some of it instead?'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Invest ₹0'),
                      Text(
                        'Invest ${formatMinorMoney((monthlyInvestment * 100).toInt(), currency: '₹')}/mo',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _investmentPercent,
                    onChanged: (val) {
                      setState(() {
                        _investmentPercent = val;
                      });
                    },
                    activeColor: colorScheme.primary,
                    inactiveColor: colorScheme.surfaceContainerHighest,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Chart Area
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 32, left: 16, right: 24, bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'In $_years Years',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              formatMinorMoney((futureValue * 100).toInt(), currency: '₹'),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Total Invested',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              formatMinorMoney((totalInvested * 100).toInt(), currency: '₹'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: _buildChart(monthlyInvestment, _years, _annualReturnRate, colorScheme),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      error: (err, stack) => Center(child: Text('Error loading data: $err')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildChart(double monthlyInvestment, int years, double annualRate, ColorScheme colorScheme) {
    if (monthlyInvestment <= 0) {
      return Center(
        child: Text(
          'Slide to see the magic of compounding! ✨',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int y = 0; y <= years; y++) {
      double fv = _calculateFutureValue(monthlyInvestment, y, annualRate);
      spots.add(FlSpot(y.toDouble(), fv));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 5 == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('Year ${value.toInt()}', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 10)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: colorScheme.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 250),
    );
  }
}
