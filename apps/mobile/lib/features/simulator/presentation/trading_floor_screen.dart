import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/money_format.dart';
import '../data/simulator_models.dart';
import '../data/simulator_repository.dart';
import 'asset_detail_screen.dart';

final simulatorPortfolioProvider = FutureProvider.autoDispose<SimulatorPortfolio>((ref) {
  return ref.watch(simulatorRepositoryProvider).portfolio();
});

final marketAssetsProvider = FutureProvider.autoDispose<List<MarketAsset>>((ref) {
  return ref.watch(simulatorRepositoryProvider).assets();
});

class TradingFloorScreen extends ConsumerStatefulWidget {
  const TradingFloorScreen({super.key});

  @override
  ConsumerState<TradingFloorScreen> createState() => _TradingFloorScreenState();
}

class _TradingFloorScreenState extends ConsumerState<TradingFloorScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final portfolioAsync = ref.watch(simulatorPortfolioProvider);
    final assetsAsync = ref.watch(marketAssetsProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: colorScheme.surface.withValues(alpha: 0.95),
              title: Text('Trading Floor', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              centerTitle: true,
              bottom: TabBar(
                indicatorColor: colorScheme.primary,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                tabs: const [
                  Tab(text: 'Watchlist'),
                  Tab(text: 'Portfolio'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _buildWatchlistTab(context, assetsAsync),
              _buildPortfolioTab(context, portfolioAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWatchlistTab(BuildContext context, AsyncValue<List<MarketAsset>> assetsAsync) {
    return assetsAsync.when(
      data: (assets) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(marketAssetsProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: assets.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final asset = assets[index];
              // Randomly decide if it's up or down for mock UI
              final isUp = DateTime.now().millisecond % 2 == 0;
              final color = isUp ? Colors.green : Colors.red;

              return ListTile(
                title: Text(asset.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(asset.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatMinorMoney(asset.priceMinor ?? 0, currency: '₹'),
                      style: TextStyle(fontWeight: FontWeight.bold, color: color),
                    ),
                    Text(
                      isUp ? '+1.2%' : '-0.8%',
                      style: TextStyle(color: color, fontSize: 12),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AssetDetailScreen(asset: asset)),
                  ).then((_) {
                    ref.invalidate(simulatorPortfolioProvider);
                  });
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildPortfolioTab(BuildContext context, AsyncValue<SimulatorPortfolio> portfolioAsync) {
    return portfolioAsync.when(
      data: (portfolio) {
        final theme = Theme.of(context);
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
                    child: Text('No open positions.\nGo to Watchlist to start trading!'),
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
