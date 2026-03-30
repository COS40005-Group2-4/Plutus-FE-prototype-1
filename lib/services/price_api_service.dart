import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for fetching real-time cryptocurrency and stock prices
///
/// Uses:
/// - CoinGecko API for cryptocurrency prices (with API key)
/// - Alpha Vantage API for stock prices (with API key)
import 'interfaces/i_price_api_service.dart';
import '../models/market_data_model.dart';

class PriceApiService implements IPriceApiService {
  static const Duration _timeout = Duration(seconds: 5);
  
  // CoinGecko API endpoints
  static const String _coinGeckoBase = 'https://api.coingecko.com/api/v3';
  
  // Alpha Vantage API
  static const String _alphaVantageBase = 'https://www.alphavantage.co/query';
  
  // Get API keys from environment
  String? get _coinGeckoApiKey => dotenv.env['COINGECKO_API_KEY'];
  String? get _alphaVantageApiKey => dotenv.env['ALPHA_VANTAGE_API_KEY'];

  /// Fetches current price for a cryptocurrency or stock symbol
  /// 
  /// For crypto: Use symbols like 'BTC', 'ETH', 'DOGE'
  /// For stocks: Use symbols like 'AAPL', 'GOOGL', 'TSLA'
  /// 
  /// Returns price in USD, or null if fetch fails
  @override
  Future<double?> getCurrentPrice(String symbol) async {
    try {
      // Try crypto first (common symbols)
      if (_isCryptoSymbol(symbol)) {
        final price = await _getCryptoPrice(symbol);
        if (price != null) return price;
      }
      
      // Try stock API
      return await _getStockPrice(symbol);
    } catch (e) {
      debugPrint('Error fetching price for $symbol: $e');
      return null;
    }
  }

  /// Checks if symbol is likely a cryptocurrency
  bool _isCryptoSymbol(String symbol) {
    final cryptoSymbols = [
      'BTC', 'ETH', 'USDT', 'BNB', 'SOL', 'XRP', 'USDC', 'ADA', 'DOGE', 
      'TRX', 'TON', 'LINK', 'MATIC', 'DOT', 'DAI', 'SHIB', 'LTC', 'BCH',
      'UNI', 'ATOM', 'XLM', 'ALGO', 'VET', 'FIL', 'HBAR', 'APT', 'ARB'
    ];
    return cryptoSymbols.contains(symbol.toUpperCase());
  }

  /// Fetches cryptocurrency price from CoinGecko
  Future<double?> _getCryptoPrice(String symbol) async {
    try {
      final coinId = _getCoinGeckoId(symbol);
      if (coinId == null) return null;

      final headers = _coinGeckoApiKey != null
          ? {'x-cg-demo-api-key': _coinGeckoApiKey!}
          : <String, String>{};

      final url = Uri.parse(
        '$_coinGeckoBase/simple/price?ids=$coinId&vs_currencies=usd'
      );

      final response = await http.get(url, headers: headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data.containsKey(coinId)) {
          final priceData = data[coinId] as Map<String, dynamic>;
          return (priceData['usd'] as num).toDouble();
        }
      }
      return null;
    } catch (e) {
      debugPrint('CoinGecko API error: $e');
      return null;
    }
  }

  /// Fetches stock price from Alpha Vantage
  Future<double?> _getStockPrice(String symbol) async {
    try {
      if (_alphaVantageApiKey == null) {
        debugPrint('Alpha Vantage API key not configured');
        return null;
      }

      final url = Uri.parse(
        '$_alphaVantageBase?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$_alphaVantageApiKey'
      );

      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        final quote = data['Global Quote'] as Map<String, dynamic>?;
        if (quote == null) return null;
        
        final priceStr = quote['05. price'] as String?;
        if (priceStr == null) return null;
        
        return double.tryParse(priceStr);
      }
      return null;
    } catch (e) {
      debugPrint('Alpha Vantage API error: $e');
      return null;
    }
  }

  /// Maps common crypto symbols to CoinGecko IDs
  String? _getCoinGeckoId(String symbol) {
    final mapping = {
      'BTC': 'bitcoin',
      'ETH': 'ethereum',
      'USDT': 'tether',
      'BNB': 'binancecoin',
      'SOL': 'solana',
      'XRP': 'ripple',
      'USDC': 'usd-coin',
      'ADA': 'cardano',
      'DOGE': 'dogecoin',
      'TRX': 'tron',
      'TON': 'the-open-network',
      'LINK': 'chainlink',
      'MATIC': 'matic-network',
      'DOT': 'polkadot',
      'DAI': 'dai',
      'SHIB': 'shiba-inu',
      'LTC': 'litecoin',
      'BCH': 'bitcoin-cash',
      'UNI': 'uniswap',
      'ATOM': 'cosmos',
      'XLM': 'stellar',
      'ALGO': 'algorand',
      'VET': 'vechain',
      'FIL': 'filecoin',
      'HBAR': 'hedera-hashgraph',
      'APT': 'aptos',
      'ARB': 'arbitrum',
    };
    return mapping[symbol.toUpperCase()];
  }

  /// Fetches historical prices for charting
  /// 
  /// Returns list of price points with timestamp and price
  /// [days] specifies how many days of history to fetch (max 365)
  @override
  Future<List<Map<String, dynamic>>?> getHistoricalPrices(
    String symbol,
    int days,
  ) async {
    try {
      // Try crypto first
      if (_isCryptoSymbol(symbol)) {
        final prices = await _getCryptoHistoricalPrices(symbol, days);
        if (prices != null) return prices;
      }
      
      // Try stock API
      return await _getStockHistoricalPrices(symbol, days);
    } catch (e) {
      debugPrint('Error fetching historical prices for $symbol: $e');
      return null;
    }
  }

  /// Fetches cryptocurrency historical prices from CoinGecko
  Future<List<Map<String, dynamic>>?> _getCryptoHistoricalPrices(
    String symbol,
    int days,
  ) async {
    try {
      final coinId = _getCoinGeckoId(symbol);
      if (coinId == null) return null;

      final headers = _coinGeckoApiKey != null
          ? {'x-cg-demo-api-key': _coinGeckoApiKey!}
          : <String, String>{};

      final url = Uri.parse(
        '$_coinGeckoBase/coins/$coinId/market_chart?vs_currency=usd&days=$days'
      );

      final response = await http.get(url, headers: headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final prices = data['prices'] as List?;
        
        if (prices == null) return null;
        
        return prices.map((point) {
          final list = point as List;
          return {
            'date': (list[0] as num).toInt(), // Unix timestamp in milliseconds
            'price': (list[1] as num).toDouble(),
          };
        }).toList();
      }
      return null;
    } catch (e) {
      debugPrint('CoinGecko historical API error: $e');
      return null;
    }
  }

  /// Fetches market data (price, 24h change, high/low, volume, market cap)
  @override
  Future<MarketData?> getMarketData(String symbol) async {
    try {
      if (_isCryptoSymbol(symbol)) {
        final data = await _getCryptoMarketData(symbol);
        if (data != null) return data;
      }
      return await _getStockMarketData(symbol);
    } catch (e) {
      debugPrint('Error fetching market data for $symbol: $e');
      return null;
    }
  }

  Future<MarketData?> _getCryptoMarketData(String symbol) async {
    try {
      final coinId = _getCoinGeckoId(symbol);
      if (coinId == null) return null;

      final headers = _coinGeckoApiKey != null
          ? {'x-cg-demo-api-key': _coinGeckoApiKey!}
          : <String, String>{};

      final url = Uri.parse(
        '$_coinGeckoBase/coins/$coinId?localization=false&tickers=false&community_data=false&developer_data=false',
      );

      final response = await http.get(url, headers: headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final marketData = data['market_data'] as Map<String, dynamic>?;
        if (marketData == null) return null;

        final currentPrice = (marketData['current_price'] as Map<String, dynamic>?)?['usd'];
        final changePercent = marketData['price_change_percentage_24h'];
        final high = (marketData['high_24h'] as Map<String, dynamic>?)?['usd'];
        final low = (marketData['low_24h'] as Map<String, dynamic>?)?['usd'];
        final marketCap = (marketData['market_cap'] as Map<String, dynamic>?)?['usd'];
        final volume = (marketData['total_volume'] as Map<String, dynamic>?)?['usd'];

        if (currentPrice == null) return null;

        return MarketData(
          currentPrice: (currentPrice as num).toDouble(),
          priceChangePercent24h: changePercent != null ? (changePercent as num).toDouble() : 0.0,
          high24h: high != null ? (high as num).toDouble() : currentPrice.toDouble(),
          low24h: low != null ? (low as num).toDouble() : currentPrice.toDouble(),
          marketCap: marketCap != null ? (marketCap as num).toDouble() : null,
          volume: volume != null ? (volume as num).toDouble() : null,
        );
      }
      return null;
    } catch (e) {
      debugPrint('CoinGecko market data API error: $e');
      return null;
    }
  }

  Future<MarketData?> _getStockMarketData(String symbol) async {
    try {
      if (_alphaVantageApiKey == null) return null;

      final url = Uri.parse(
        '$_alphaVantageBase?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$_alphaVantageApiKey',
      );

      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final quote = data['Global Quote'] as Map<String, dynamic>?;
        if (quote == null || quote.isEmpty) return null;

        final priceStr = quote['05. price'] as String?;
        if (priceStr == null) return null;

        final price = double.tryParse(priceStr);
        if (price == null) return null;

        final changePercentStr = (quote['10. change percent'] as String?)?.replaceAll('%', '');
        final high = double.tryParse(quote['03. high'] as String? ?? '');
        final low = double.tryParse(quote['04. low'] as String? ?? '');
        final volume = double.tryParse(quote['06. volume'] as String? ?? '');

        return MarketData(
          currentPrice: price,
          priceChangePercent24h: changePercentStr != null ? (double.tryParse(changePercentStr) ?? 0.0) : 0.0,
          high24h: high ?? price,
          low24h: low ?? price,
          marketCap: null,
          volume: volume,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Alpha Vantage market data API error: $e');
      return null;
    }
  }

  /// Fetches stock historical prices from Alpha Vantage
  Future<List<Map<String, dynamic>>?> _getStockHistoricalPrices(
    String symbol,
    int days,
  ) async {
    try {
      if (_alphaVantageApiKey == null) {
        debugPrint('Alpha Vantage API key not configured');
        return null;
      }

      // Use TIME_SERIES_DAILY for historical data
      final url = Uri.parse(
        '$_alphaVantageBase?function=TIME_SERIES_DAILY&symbol=$symbol&apikey=$_alphaVantageApiKey'
      );

      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final timeSeries = data['Time Series (Daily)'] as Map<String, dynamic>?;
        
        if (timeSeries == null) return null;
        
        final prices = <Map<String, dynamic>>[];
        final entries = timeSeries.entries.toList();
        
        // Sort by date descending and take only requested days
        entries.sort((a, b) => b.key.compareTo(a.key));
        final limitedEntries = entries.take(days);
        
        for (final entry in limitedEntries) {
          final dateStr = entry.key;
          final values = entry.value as Map<String, dynamic>;
          final closePrice = values['4. close'] as String?;
          
          if (closePrice != null) {
            final date = DateTime.parse(dateStr);
            prices.add({
              'date': date.millisecondsSinceEpoch,
              'price': double.parse(closePrice),
            });
          }
        }
        
        // Reverse to get chronological order
        return prices.reversed.toList();
      }
      return null;
    } catch (e) {
      debugPrint('Alpha Vantage historical API error: $e');
      return null;
    }
  }
}
