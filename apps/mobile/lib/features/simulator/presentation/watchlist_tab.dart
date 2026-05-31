import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters/money_format.dart';
import '../data/simulator_models.dart';
import '../data/simulator_repository.dart';
import 'asset_detail_screen.dart';

final marketAssetsProvider = FutureProvider.autoDispose<List<MarketAsset>>((ref) {
  return ref.watch(simulatorRepositoryProvider).assets();
});

class WatchlistTab extends ConsumerWidget {
  const WatchlistTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(marketAssetsProvider);

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
              final isUp = asset.priceMinor != 0; // Simplified for now since we only have live price
              final color = isUp ? Colors.green.shade600 : Colors.red.shade600;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(asset.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(asset.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatMinorMoney(asset.priceMinor ?? 0, currency: '₹'),
                      style: TextStyle(fontWeight: FontWeight.bold, color: color),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AssetDetailScreen(asset: asset)),
                  ).then((_) {
                    // Refresh portfolio if they traded
                    ref.invalidate(marketAssetsProvider);
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
}
