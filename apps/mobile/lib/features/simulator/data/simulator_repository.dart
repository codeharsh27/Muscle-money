import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'simulator_models.dart';
import 'yahoo_finance_api.dart';

final simulatorRepositoryProvider = Provider<SimulatorRepository>((ref) {
  return MockSimulatorRepository(YahooFinanceApi());
});

final simulatorPortfolioProvider = FutureProvider.autoDispose<SimulatorPortfolio>((ref) {
  return ref.watch(simulatorRepositoryProvider).portfolio();
});

abstract class SimulatorRepository {
  Future<SimulatorPortfolio> portfolio();
  Future<List<MarketAsset>> assets();
  Future<void> buy({required String assetId, required double quantity});
  Future<void> sell({required String assetId, required double quantity});
  Dio get _dio;
}

class MockSimulatorRepository implements SimulatorRepository {
  final YahooFinanceApi _api;
  int _cashBalanceMinor = 15000000; // 1,50,000 INR default
  final List<SimulatorPosition> _positions = [];

  MockSimulatorRepository(this._api);

  final List<MarketAsset> _baseAssets = [
    // Indian Blue-Chips
    const MarketAsset(id: 'RELIANCE.NS', symbol: 'RELIANCE', name: 'Reliance Industries', type: 'STOCK', priceMinor: 0),
    const MarketAsset(id: 'TCS.NS', symbol: 'TCS', name: 'Tata Consultancy', type: 'STOCK', priceMinor: 0),
    const MarketAsset(id: 'HDFCBANK.NS', symbol: 'HDFCBANK', name: 'HDFC Bank', type: 'STOCK', priceMinor: 0),
    const MarketAsset(id: 'INFY.NS', symbol: 'INFY', name: 'Infosys', type: 'STOCK', priceMinor: 0),
    const MarketAsset(id: 'ITC.NS', symbol: 'ITC', name: 'ITC Limited', type: 'STOCK', priceMinor: 0),
    const MarketAsset(id: 'SBIN.NS', symbol: 'SBIN', name: 'State Bank of India', type: 'STOCK', priceMinor: 0),
    const MarketAsset(id: 'TATAMOTORS.NS', symbol: 'TATAMOTORS', name: 'Tata Motors', type: 'STOCK', priceMinor: 0),
    const MarketAsset(id: 'LT.NS', symbol: 'LT', name: 'Larsen & Toubro', type: 'STOCK', priceMinor: 0),
    
    // Global Tech Giants
    const MarketAsset(id: 'AAPL', symbol: 'AAPL', name: 'Apple Inc.', type: 'STOCK', priceMinor: 0),
    const MarketAsset(id: 'MSFT', symbol: 'MSFT', name: 'Microsoft Corp.', type: 'STOCK', priceMinor: 0),
    const MarketAsset(id: 'AMZN', symbol: 'AMZN', name: 'Amazon.com', type: 'STOCK', priceMinor: 0),
    const MarketAsset(id: 'TSLA', symbol: 'TSLA', name: 'Tesla Inc.', type: 'STOCK', priceMinor: 0),
    
    // ETFs & Indices
    const MarketAsset(id: 'NIFTYBEES.NS', symbol: 'NIFTYBEES', name: 'Nifty 50 ETF', type: 'ETF', priceMinor: 0),
    const MarketAsset(id: 'BANKBEES.NS', symbol: 'BANKBEES', name: 'Bank Nifty ETF', type: 'ETF', priceMinor: 0),
    const MarketAsset(id: 'GOLDBEES.NS', symbol: 'GOLDBEES', name: 'Gold ETF', type: 'ETF', priceMinor: 0),
  ];

  @override
  Dio get _dio => throw UnimplementedError();

  @override
  Future<List<MarketAsset>> assets() async {
    // Fetch live prices for all base assets
    final ids = _baseAssets.map((a) => a.id).toList();
    try {
      final liveQuotes = await _api.getQuotes(ids);
      
      return _baseAssets.map((a) {
        final livePrice = liveQuotes[a.id];
        if (livePrice != null) {
          double priceInNative = livePrice;
          if (['AAPL', 'MSFT', 'AMZN', 'TSLA'].contains(a.id)) {
            priceInNative *= 83.5; // crude INR conversion
          }
          return MarketAsset(
            id: a.id,
            symbol: a.symbol,
            name: a.name,
            type: a.type,
            priceMinor: (priceInNative * 100).toInt()
          );
        }
        return a;
      }).toList();
    } catch (e) {
      return _baseAssets;
    }
  }

  @override
  Future<SimulatorPortfolio> portfolio() async {
    final ids = _positions.map((p) => p.marketAssetId).toSet().toList();
    
    Map<String, double> liveQuotes = {};
    if (ids.isNotEmpty) {
      try {
        liveQuotes = await _api.getQuotes(ids);
      } catch (e) {
        // ignore
      }
    }
    
    final updatedPositions = _positions.map((p) {
      final livePrice = liveQuotes[p.marketAssetId];
      if (livePrice != null) {
        double priceInNative = livePrice;
        if (['AAPL', 'MSFT', 'AMZN', 'TSLA'].contains(p.marketAssetId)) {
          priceInNative *= 83.5;
        }
        return SimulatorPosition(
          id: p.id,
          marketAssetId: p.marketAssetId,
          quantity: p.quantity,
          averagePriceMinor: p.averagePriceMinor,
          assetSymbol: p.assetSymbol,
          assetName: p.assetName,
          assetType: p.assetType,
          latestPriceMinor: (priceInNative * 100).toInt(),
        );
      }
      return p;
    }).toList();

    int totalEquity = _cashBalanceMinor;
    for (var pos in updatedPositions) {
      totalEquity += (pos.latestPriceMinor ?? pos.averagePriceMinor) * pos.quantity.toInt();
    }

    return SimulatorPortfolio(
      totalEquityMinor: totalEquity,
      cashBalanceMinor: _cashBalanceMinor,
      positionsCount: updatedPositions.length,
      positions: updatedPositions,
    );
  }

  @override
  Future<void> buy({required String assetId, required double quantity}) async {
    final liveQuotes = await _api.getQuotes([assetId]);
    final livePrice = liveQuotes[assetId];
    if (livePrice == null) throw Exception('Asset price not available right now. Market closed?');
    
    double priceInNative = livePrice;
    if (['AAPL', 'MSFT', 'AMZN', 'TSLA'].contains(assetId)) {
      priceInNative *= 83.5;
    }
    
    final priceMinor = (priceInNative * 100).toInt();
    final cost = (priceMinor * quantity).toInt();
    
    if (_cashBalanceMinor < cost) {
      throw Exception('Insufficient funds! Need ₹${cost / 100}');
    }

    _cashBalanceMinor -= cost;
    
    final asset = _baseAssets.firstWhere((a) => a.id == assetId);
    final existingIndex = _positions.indexWhere((p) => p.marketAssetId == assetId);

    if (existingIndex >= 0) {
      final existing = _positions[existingIndex];
      final newQuantity = existing.quantity + quantity;
      final newAvgPrice = ((existing.averagePriceMinor * existing.quantity) + cost) / newQuantity;
      
      _positions[existingIndex] = SimulatorPosition(
        id: existing.id,
        marketAssetId: existing.marketAssetId,
        quantity: newQuantity,
        averagePriceMinor: newAvgPrice.toInt(),
        assetSymbol: existing.assetSymbol,
        assetName: existing.assetName,
        assetType: existing.assetType,
        latestPriceMinor: existing.latestPriceMinor,
      );
    } else {
      _positions.add(SimulatorPosition(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        marketAssetId: assetId,
        assetSymbol: asset.symbol,
        assetName: asset.name,
        assetType: asset.type,
        quantity: quantity,
        averagePriceMinor: priceMinor,
        latestPriceMinor: priceMinor,
      ));
    }
  }

  @override
  Future<void> sell({required String assetId, required double quantity}) async {
    final existingIndex = _positions.indexWhere((p) => p.marketAssetId == assetId);
    if (existingIndex < 0) throw Exception('No open position for this asset');
    
    final existing = _positions[existingIndex];
    if (existing.quantity < quantity) throw Exception('Insufficient quantity to sell');

    final liveQuotes = await _api.getQuotes([assetId]);
    final livePrice = liveQuotes[assetId];
    if (livePrice == null) throw Exception('Asset price not available');
    
    double priceInNative = livePrice;
    if (['AAPL', 'MSFT', 'AMZN', 'TSLA'].contains(assetId)) {
      priceInNative *= 83.5;
    }
    
    final priceMinor = (priceInNative * 100).toInt();
    final revenue = (priceMinor * quantity).toInt();

    _cashBalanceMinor += revenue;

    if (existing.quantity == quantity) {
      _positions.removeAt(existingIndex);
    } else {
      _positions[existingIndex] = SimulatorPosition(
        id: existing.id,
        marketAssetId: existing.marketAssetId,
        quantity: existing.quantity - quantity,
        averagePriceMinor: existing.averagePriceMinor,
        assetSymbol: existing.assetSymbol,
        assetName: existing.assetName,
        assetType: existing.assetType,
        latestPriceMinor: existing.latestPriceMinor,
      );
    }
  }
}
