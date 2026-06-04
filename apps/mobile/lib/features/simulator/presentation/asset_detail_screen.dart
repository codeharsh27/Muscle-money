import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/money_format.dart';
import '../data/simulator_models.dart';
import '../data/simulator_repository.dart';
import '../data/yahoo_finance_api.dart';
import '../../dashboard/data/dashboard_repository.dart';
import 'candlestick_chart.dart';

class ChartRequest {
  final String symbol;
  final String timeframe;
  ChartRequest(this.symbol, this.timeframe);
  
  @override
  bool operator ==(Object other) => identical(this, other) || other is ChartRequest && other.symbol == symbol && other.timeframe == timeframe;
  @override
  int get hashCode => symbol.hashCode ^ timeframe.hashCode;
}

final chartDataProvider = FutureProvider.family<List<YahooOhlc>, ChartRequest>((ref, req) async {
  final api = YahooFinanceApi();
  String range = '3mo';
  String interval = '1d';
  
  switch (req.timeframe) {
    case '1D': range = '1d'; interval = '5m'; break;
    case '1W': range = '5d'; interval = '15m'; break;
    case '1M': range = '1mo'; interval = '1d'; break;
    case '3M': range = '3mo'; interval = '1d'; break;
    case '1Y': range = '1y'; interval = '1d'; break;
  }
  
  return await api.getChartData(req.symbol, range: range, interval: interval);
});

class AssetDetailScreen extends ConsumerStatefulWidget {
  final MarketAsset asset;

  const AssetDetailScreen({super.key, required this.asset});

  @override
  ConsumerState<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends ConsumerState<AssetDetailScreen> {
  String _selectedTimeframe = '3M';

  void _showOrderSheet(BuildContext context, bool isBuy) {
    final parentNavigator = Navigator.of(context);
    final parentScaffold = ScaffoldMessenger.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _OrderSheet(
        asset: widget.asset,
        isBuy: isBuy,
        onConfirm: (quantity) async {
          Navigator.pop(sheetContext); // close sheet
          
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => const Center(child: CircularProgressIndicator()),
          );
          
          try {
            final repo = ref.read(simulatorRepositoryProvider);
            if (isBuy) {
              await repo.buy(assetId: widget.asset.id, quantity: quantity);
            } else {
              await repo.sell(assetId: widget.asset.id, quantity: quantity);
            }
            if (!mounted) return;
            parentNavigator.pop(); // remove loader
            
            // Invalidate the portfolio so UI updates
            ref.invalidate(simulatorPortfolioProvider);
            ref.read(mockStreakProvider.notifier).state++;
            ref.invalidate(dashboardSummaryProvider);
            
            parentScaffold.showSnackBar(
              const SnackBar(content: Text('Order executed successfully!'), backgroundColor: Colors.green),
            );
          } catch (e) {
            if (!mounted) return;
            parentNavigator.pop(); // remove loader
            parentScaffold.showSnackBar(
              SnackBar(content: Text('Order Failed: $e'), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  String _getNovaTip(String symbol, String timeframe, bool isPositive, double percent) {
    final direction = isPositive ? 'up' : 'down';
    final colorTip = isPositive 
        ? 'Green candles mean the price closed higher than it opened (Bullish!).'
        : 'Red candles mean the price dropped from open to close (Bearish).';
        
    String timeframeText = '';
    switch (timeframe) {
      case '1D': timeframeText = 'today'; break;
      case '1W': timeframeText = 'this past week'; break;
      case '1M': timeframeText = 'over the last month'; break;
      case '3M': timeframeText = 'in the last 3 months'; break;
      case '1Y': timeframeText = 'this past year'; break;
    }

    if (percent < 1.0) {
      return '$symbol is mostly flat $timeframeText, moving $direction by just ${percent.toStringAsFixed(1)}%. $colorTip';
    } else if (percent > 10.0) {
      return 'Whoa! $symbol has made a huge $direction move of ${percent.toStringAsFixed(1)}% $timeframeText! High volatility usually means big news. $colorTip';
    } else {
      return '$symbol is $direction ${percent.toStringAsFixed(1)}% $timeframeText. $colorTip';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final chartAsync = ref.watch(chartDataProvider(ChartRequest(widget.asset.id, _selectedTimeframe)));
    final livePriceMinor = widget.asset.priceMinor ?? 0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.asset.symbol, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header: Name and Live Price
          Text(widget.asset.name, style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          
          chartAsync.when(
            data: (data) {
              if (data.isEmpty) return const SizedBox.shrink();
              
              // Calculate change over the selected timeframe
              final firstCandle = data.first;
              final lastCandle = data.last;
              
              // Depending on timeframe, "Open" might be the open of the first candle in the range.
              final startPrice = firstCandle.open;
              final endPrice = lastCandle.close;
              final diff = endPrice - startPrice;
              final percent = startPrice != 0 ? (diff / startPrice) * 100 : 0.0;
              final isPositive = diff >= 0;
              final color = isPositive ? Colors.green : Colors.red;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatMinorMoney((endPrice * (widget.asset.id.contains('.NS') ? 100 : 8350)).toInt(), currency: '₹'),
                    style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward, color: color, size: 16),
                      Text(
                        '${formatMinorMoney((diff.abs() * (widget.asset.id.contains('.NS') ? 100 : 8350)).toInt(), currency: '₹')} (${percent.abs().toStringAsFixed(2)}%)',
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(_selectedTimeframe, style: TextStyle(color: colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Timeframes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['1D', '1W', '1M', '3M', '1Y'].map((t) {
                      final isSelected = t == _selectedTimeframe;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTimeframe = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Candlestick Chart
                  SizedBox(
                    height: 300,
                    child: CandlestickChart(data: data),
                  ),
                  const SizedBox(height: 24),
                  
                  // Nova Educational Tip
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundImage: AssetImage('assets/images/nova_avatar.png'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nova Insight',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getNovaTip(widget.asset.symbol, _selectedTimeframe, isPositive, percent.abs()),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 400,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SizedBox(
              height: 400,
              child: Center(child: Text('Error loading chart: $e')),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Order Book (Mock)
          Text('Market Depth', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('BID', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    const Divider(),
                    _buildDepthRow('98.50', '1,200', Colors.green),
                    _buildDepthRow('98.45', '4,500', Colors.green),
                    _buildDepthRow('98.40', '3,100', Colors.green),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    const Text('ASK', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    const Divider(),
                    _buildDepthRow('98.55', '2,100', Colors.red),
                    _buildDepthRow('98.60', '8,000', Colors.red),
                    _buildDepthRow('98.65', '1,500', Colors.red),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showOrderSheet(context, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('SELL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showOrderSheet(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('BUY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepthRow(String price, String qty, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(price, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          Text(qty, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _OrderSheet extends StatefulWidget {
  final MarketAsset asset;
  final bool isBuy;
  final Function(double quantity) onConfirm;

  const _OrderSheet({required this.asset, required this.isBuy, required this.onConfirm});

  @override
  State<_OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends State<_OrderSheet> {
  double _quantity = 1;
  bool _isIntraday = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalValue = ((widget.asset.priceMinor ?? 0) * _quantity).toInt();
    final actionColor = widget.isBuy ? Colors.green.shade600 : Colors.red.shade600;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.isBuy ? 'BUY' : 'SELL'} ${widget.asset.symbol}', 
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: actionColor)
              ),
              Text(
                formatMinorMoney(widget.asset.priceMinor ?? 0, currency: '₹'),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Product type toggle (Delivery/Intraday)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isIntraday = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isIntraday ? colorScheme.surface : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: !_isIntraday ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
                      ),
                      alignment: Alignment.center,
                      child: Text('Delivery', style: TextStyle(fontWeight: !_isIntraday ? FontWeight.bold : FontWeight.normal)),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isIntraday = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isIntraday ? colorScheme.surface : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _isIntraday ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
                      ),
                      alignment: Alignment.center,
                      child: Text('Intraday', style: TextStyle(fontWeight: _isIntraday ? FontWeight.bold : FontWeight.normal)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quantity Input
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Qty NSE', style: theme.textTheme.titleMedium),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (_quantity > 1) setState(() { _quantity--; });
                      },
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        _quantity.toStringAsFixed(0), 
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() { _quantity++; });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Margin / Total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Required Margin', style: TextStyle(color: Colors.grey)),
                Text(
                  formatMinorMoney(totalValue, currency: '₹'),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Swipe to buy / Big Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => widget.onConfirm(_quantity),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: actionColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'SWIPE TO ${widget.isBuy ? 'BUY' : 'SELL'}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
