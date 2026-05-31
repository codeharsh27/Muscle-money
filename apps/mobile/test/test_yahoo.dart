import 'package:flutter_test/flutter_test.dart';
import 'package:muscle_money/features/simulator/data/yahoo_finance_api.dart';

void main() {
  test('fetch yahoo finance chart', () async {
    final api = YahooFinanceApi();
    try {
      final chart = await api.getChartData('AAPL');
      print('Chart data points: ${chart.length}');
      if (chart.isNotEmpty) {
        print('Last point: ${chart.last.close}');
      }
    } catch (e) {
      print('Error: $e');
    }
  });
}
