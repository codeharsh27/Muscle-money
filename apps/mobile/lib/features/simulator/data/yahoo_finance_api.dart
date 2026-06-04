import 'package:dio/dio.dart';

class YahooOhlc {
  final int timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  YahooOhlc({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

class YahooFinanceApi {
  final Dio _dio;

  YahooFinanceApi() : _dio = Dio(BaseOptions(
    baseUrl: 'https://query1.finance.yahoo.com',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    },
  ));

  /// Fetches real-time price (delayed by ~15 mins for some exchanges)
  Future<double> getLivePrice(String symbol) async {
    try {
      final response = await _dio.get('/v8/finance/chart/$symbol?interval=1d&range=1d');
      final result = response.data['chart']['result'][0];
      final meta = result['meta'];
      return (meta['regularMarketPrice'] as num).toDouble();
    } catch (e) {
      throw Exception('Failed to fetch live price for $symbol: $e');
    }
  }

  /// Fetches quotes for multiple symbols at once
  Future<Map<String, double>> getQuotes(List<String> symbols) async {
    if (symbols.isEmpty) return {};
    
    final Map<String, double> quotes = {};
    
    // Yahoo v7 quote endpoint now returns 401, so we use v8 chart endpoint concurrently
    final futures = symbols.map((sym) async {
      try {
        final price = await getLivePrice(sym);
        return MapEntry(sym, price);
      } catch (e) {
        // Return null entry on failure to avoid failing the whole batch
        return null;
      }
    });

    final results = await Future.wait(futures);
    for (var result in results) {
      if (result != null) {
        quotes[result.key] = result.value;
      }
    }
    
    return quotes;
  }

  /// Fetches historical OHLC data
  /// Valid ranges: 1d, 5d, 1mo, 3mo, 6mo, 1y, 2y, 5y, 10y, ytd, max
  /// Valid intervals: 1m, 2m, 5m, 15m, 30m, 60m, 90m, 1h, 1d, 5d, 1wk, 1mo, 3mo
  Future<List<YahooOhlc>> getChartData(String symbol, {String range = '1mo', String interval = '1d'}) async {
    try {
      final response = await _dio.get('/v8/finance/chart/$symbol?range=$range&interval=$interval');
      final result = response.data['chart']['result'][0];
      
      final timestamps = List<int>.from(result['timestamp'] ?? []);
      final quote = result['indicators']['quote'][0];
      
      final opens = List<num?>.from(quote['open'] ?? []);
      final highs = List<num?>.from(quote['high'] ?? []);
      final lows = List<num?>.from(quote['low'] ?? []);
      final closes = List<num?>.from(quote['close'] ?? []);
      final volumes = List<num?>.from(quote['volume'] ?? []);

      List<YahooOhlc> ohlcList = [];
      for (int i = 0; i < timestamps.length; i++) {
        // Yahoo sometimes returns nulls for missing data periods
        if (opens[i] != null && closes[i] != null && highs[i] != null && lows[i] != null) {
          ohlcList.add(
            YahooOhlc(
              timestamp: timestamps[i],
              open: opens[i]!.toDouble(),
              high: highs[i]!.toDouble(),
              low: lows[i]!.toDouble(),
              close: closes[i]!.toDouble(),
              volume: (volumes[i] ?? 0).toDouble(),
            ),
          );
        }
      }
      return ohlcList;
    } catch (e) {
      throw Exception('Failed to fetch chart data for $symbol: $e');
    }
  }
}
