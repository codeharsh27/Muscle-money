import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/money_format.dart';
import '../data/simulator_models.dart';
import '../data/simulator_repository.dart';



class PortfolioTab extends ConsumerWidget {
  const PortfolioTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(simulatorPortfolioProvider);
    final theme = Theme.of(context);

    return portfolioAsync.when(
      data: (portfolio) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(simulatorPortfolioProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Virtual Equity', style: TextStyle(color: theme.colorScheme.onPrimary.withValues(alpha: 0.8))),
                    const SizedBox(height: 8),
                    Text(
                      formatMinorMoney(portfolio.totalEquityMinor, currency: '₹'),
                      style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Available Cash', style: TextStyle(color: theme.colorScheme.onPrimary.withValues(alpha: 0.8), fontSize: 12)),
                            Text(
                              formatMinorMoney(portfolio.cashBalanceMinor, currency: '₹'),
                              style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Positions', style: TextStyle(color: theme.colorScheme.onPrimary.withValues(alpha: 0.8), fontSize: 12)),
                            Text(
                              '${portfolio.positionsCount}',
                              style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Your Holdings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (portfolio.positions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No open positions.\nGo to Watchlist to start trading!', textAlign: TextAlign.center),
                  ),
                ),
              ...portfolio.positions.map((pos) {
                final currentVal = (pos.latestPriceMinor ?? pos.averagePriceMinor) * pos.quantity;
                final investedVal = pos.averagePriceMinor * pos.quantity;
                final profit = currentVal - investedVal;
                final profitColor = profit >= 0 ? Colors.green : Colors.red;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(pos.assetSymbol, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${pos.quantity.toStringAsFixed(2)} shares @ ${formatMinorMoney(pos.averagePriceMinor, currency: '₹')}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatMinorMoney(currentVal.toInt(), currency: '₹'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${profit >= 0 ? '+' : ''}${formatMinorMoney(profit.toInt(), currency: '₹')}',
                          style: TextStyle(color: profitColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
