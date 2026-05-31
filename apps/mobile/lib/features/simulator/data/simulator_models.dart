class MarketAsset {
  final String id;
  final String symbol;
  final String name;
  final String type;
  final int? priceMinor;

  const MarketAsset({
    required this.id,
    required this.symbol,
    required this.name,
    required this.type,
    this.priceMinor,
  });

  MarketAsset copyWith({
    String? id,
    String? symbol,
    String? name,
    String? type,
    int? priceMinor,
  }) {
    return MarketAsset(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      type: type ?? this.type,
      priceMinor: priceMinor ?? this.priceMinor,
    );
  }
}

class SimulatorPosition {
  final String id;
  final String marketAssetId;
  final double quantity;
  final int averagePriceMinor;
  final String assetSymbol;
  final String assetName;
  final String assetType;
  final int? latestPriceMinor;

  const SimulatorPosition({
    required this.id,
    required this.marketAssetId,
    required this.quantity,
    required this.averagePriceMinor,
    required this.assetSymbol,
    required this.assetName,
    required this.assetType,
    this.latestPriceMinor,
  });

  SimulatorPosition copyWith({
    String? id,
    String? marketAssetId,
    double? quantity,
    int? averagePriceMinor,
    String? assetSymbol,
    String? assetName,
    String? assetType,
    int? latestPriceMinor,
  }) {
    return SimulatorPosition(
      id: id ?? this.id,
      marketAssetId: marketAssetId ?? this.marketAssetId,
      quantity: quantity ?? this.quantity,
      averagePriceMinor: averagePriceMinor ?? this.averagePriceMinor,
      assetSymbol: assetSymbol ?? this.assetSymbol,
      assetName: assetName ?? this.assetName,
      assetType: assetType ?? this.assetType,
      latestPriceMinor: latestPriceMinor ?? this.latestPriceMinor,
    );
  }
}

class SimulatorPortfolio {
  final int totalEquityMinor;
  final int cashBalanceMinor;
  final int positionsCount;
  final List<SimulatorPosition> positions;

  const SimulatorPortfolio({
    required this.totalEquityMinor,
    required this.cashBalanceMinor,
    required this.positionsCount,
    required this.positions,
  });
}
