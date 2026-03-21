abstract class IPriceApiService {
  Future<double?> getCurrentPrice(String symbol);
  Future<List<Map<String, dynamic>>?> getHistoricalPrices(String symbol, int days);
}
