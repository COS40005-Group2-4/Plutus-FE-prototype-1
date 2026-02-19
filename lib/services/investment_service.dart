import 'backend_ffi_service.dart';
import 'price_api_service.dart';
import '../models/investment_model.dart';

/// Service layer for managing investment data operations
/// 
/// This service handles:
/// - Fetching investment list with 5-minute caching
/// - Fetching detailed investment data
/// - Cache management and invalidation
/// - Portfolio-level calculations
class InvestmentService {
  final BackendFfiService _ffiService = BackendFfiService();
  final PriceApiService _priceService = PriceApiService();
  
  // Cache for investment list
  List<InvestmentModel>? _cachedInvestments;
  DateTime? _lastFetchTime;
  
  // Cache expiration duration (5 minutes)
  static const Duration _cacheExpiration = Duration(minutes: 5);

  /// Retrieves the list of all investments
  /// 
  /// Uses cached data if available and not expired (5 minutes).
  /// Set [forceRefresh] to true to bypass cache and fetch fresh data.
  /// 
  /// Throws [Exception] if backend is unavailable or returns an error.
  Future<List<InvestmentModel>> getInvestmentList({bool forceRefresh = false}) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && 
        _cachedInvestments != null && 
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheExpiration) {
      return _cachedInvestments!;
    }

    try {
      // Fetch fresh data from backend via FFI
      final jsonData = await _ffiService.getInvestmentList();
      
      // Parse investments array from response
      if (!jsonData.containsKey('investments')) {
        throw Exception('Invalid response: missing investments array');
      }
      
      final investmentsList = (jsonData['investments'] as List)
          .map((e) => InvestmentModel.fromJson(e as Map<String, dynamic>))
          .toList();
      
      // Update cache
      _cachedInvestments = investmentsList;
      _lastFetchTime = DateTime.now();
      
      return investmentsList;
    } catch (e) {
      // Re-throw with descriptive error message
      throw Exception('Failed to fetch investment list: $e');
    }
  }

  /// Retrieves detailed information for a specific investment
  /// 
  /// Returns an [InvestmentModel] with complete transaction history
  /// and value history for the specified [commodity].
  /// 
  /// Throws [Exception] if backend is unavailable or returns an error.
  Future<InvestmentModel> getInvestmentDetail(String commodity) async {
    if (commodity.isEmpty) {
      throw ArgumentError('Commodity cannot be empty');
    }

    try {
      // Fetch detailed data from backend via FFI
      final jsonData = await _ffiService.getInvestmentDetail(commodity);
      
      // Parse and return investment model
      return InvestmentModel.fromJson(jsonData);
    } catch (e) {
      // Re-throw with descriptive error message
      throw Exception('Failed to fetch investment detail for $commodity: $e');
    }
  }

  /// Clears all cached investment data
  /// 
  /// Call this method after modifying investment data (add, update, delete)
  /// to ensure the next fetch retrieves fresh data from the backend.
  void clearCache() {
    _cachedInvestments = null;
    _lastFetchTime = null;
  }

  /// Deletes an investment by ID
  /// 
  /// Removes the investment from the backend and clears the cache.
  /// Throws [Exception] if backend is unavailable or returns an error.
  Future<void> deleteInvestment(String investmentId) async {
    if (investmentId.isEmpty) {
      throw ArgumentError('Investment ID cannot be empty');
    }

    print('InvestmentService: Deleting investment $investmentId');

    try {
      // Delete from backend via FFI
      await _ffiService.deleteInvestment(investmentId);
      
      print('InvestmentService: Delete successful, clearing cache');
      
      // Clear cache to force refresh on next fetch
      clearCache();
    } catch (e) {
      print('InvestmentService: Delete failed - $e');
      // Re-throw with descriptive error message
      throw Exception('Failed to delete investment: $e');
    }
  }

  /// Saves a new investment
  /// 
  /// Creates a new investment in the backend and clears the cache.
  /// Fetches current price and historical data for crypto/stock assets.
  /// Returns the ID of the newly created investment.
  /// Throws [Exception] if backend is unavailable or returns an error.
  Future<String> saveInvestment(InvestmentModel investment) async {
    print('InvestmentService: Saving investment ${investment.assetName}');

    try {
      // Fetch current price and historical data for crypto/stock
      double? currentPrice;
      List<PriceHistoryPoint>? priceHistory;
      
      if (investment.assetType == AssetType.crypto || 
          investment.assetType == AssetType.stock) {
        print('InvestmentService: Fetching price data for ${investment.assetName}');
        
        // Get current price
        currentPrice = await _priceService.getCurrentPrice(investment.assetName);
        print('InvestmentService: Current price: $currentPrice');
        
        // Get 30 days of historical data
        final historicalData = await _priceService.getHistoricalPrices(
          investment.assetName,
          30,
        );
        
        if (historicalData != null && historicalData.isNotEmpty) {
          priceHistory = historicalData.map((point) {
            return PriceHistoryPoint(
              date: DateTime.fromMillisecondsSinceEpoch(point['date'] as int),
              price: point['price'] as double,
            );
          }).toList();
          print('InvestmentService: Fetched ${priceHistory.length} historical price points');
        }
      }
      
      // Create updated investment with price data
      final investmentWithPrices = InvestmentModel(
        id: investment.id,
        assetType: investment.assetType,
        assetName: investment.assetName,
        quantity: investment.quantity,
        purchaseValue: investment.purchaseValue,
        currency: investment.currency,
        purchaseDate: investment.purchaseDate,
        currentPrice: currentPrice,
        priceHistory: priceHistory,
      );
      
      // Convert to JSON (without ID since backend will generate it)
      final data = investmentWithPrices.toJson();
      data.remove('id'); // Remove ID, backend will generate a new one
      
      // Save to backend via FFI
      final newId = await _ffiService.saveInvestment(data);
      
      print('InvestmentService: Save successful with ID: $newId, clearing cache');
      
      // Clear cache to force refresh on next fetch
      clearCache();
      
      return newId;
    } catch (e) {
      print('InvestmentService: Save failed - $e');
      // Re-throw with descriptive error message
      throw Exception('Failed to save investment: $e');
    }
  }
  
  /// Calculates the total portfolio value across all investments
  /// 
  /// Returns the sum of current values for all provided [investments].
  double getTotalPortfolioValue(List<InvestmentModel> investments) {
    if (investments.isEmpty) {
      return 0.0;
    }
    
    return investments.fold(0.0, (sum, inv) => sum + inv.getCurrentValue());
  }
  
  /// Calculates the total gain/loss percentage for the portfolio
  /// 
  /// Returns the percentage gain or loss calculated as:
  /// ((totalValue - totalCost) / totalCost) * 100
  /// 
  /// Returns 0.0 if total cost basis is 0 or negative.
  double getTotalGainLoss(List<InvestmentModel> investments) {
    if (investments.isEmpty) {
      return 0.0;
    }
    
    final totalValue = getTotalPortfolioValue(investments);
    final totalCost = investments.fold(0.0, (sum, inv) => sum + inv.purchaseValue);
    
    // Avoid division by zero
    if (totalCost <= 0) {
      return 0.0;
    }
    
    return ((totalValue - totalCost) / totalCost) * 100;
  }

  /// Refreshes price data for an existing investment
  /// 
  /// Fetches current price and updates historical data.
  /// Returns updated investment model.
  Future<InvestmentModel> refreshPriceData(InvestmentModel investment) async {
    print('InvestmentService: Refreshing price data for ${investment.assetName}');

    try {
      double? currentPrice;
      List<PriceHistoryPoint>? priceHistory;
      
      if (investment.assetType == AssetType.crypto || 
          investment.assetType == AssetType.stock) {
        // Get current price
        currentPrice = await _priceService.getCurrentPrice(investment.assetName);
        print('InvestmentService: Current price: $currentPrice');
        
        // Get 30 days of historical data
        final historicalData = await _priceService.getHistoricalPrices(
          investment.assetName,
          30,
        );
        
        if (historicalData != null && historicalData.isNotEmpty) {
          priceHistory = historicalData.map((point) {
            return PriceHistoryPoint(
              date: DateTime.fromMillisecondsSinceEpoch(point['date'] as int),
              price: point['price'] as double,
            );
          }).toList();
          print('InvestmentService: Fetched ${priceHistory.length} historical price points');
        }
      }
      
      // Return updated investment
      return InvestmentModel(
        id: investment.id,
        assetType: investment.assetType,
        assetName: investment.assetName,
        quantity: investment.quantity,
        purchaseValue: investment.purchaseValue,
        currency: investment.currency,
        purchaseDate: investment.purchaseDate,
        currentPrice: currentPrice ?? investment.currentPrice,
        priceHistory: priceHistory ?? investment.priceHistory,
      );
    } catch (e) {
      print('InvestmentService: Price refresh failed - $e');
      // Return original investment if refresh fails
      return investment;
    }
  }

  /// Gets ROI and IRR data from backend
  /// 
  /// Returns map with 'roi' and 'irr' keys as formatted percentage strings
  Future<Map<String, String>?> getRoiIrrData() async {
    try {
      final data = await _ffiService.getRoiData();
      
      // Parse the decimal strings and format as percentages
      String roiStr = data['roi'] ?? '0';
      String irrStr = data['irr'] ?? '0';
      
      // Remove any existing % signs
      roiStr = roiStr.replaceAll('%', '');
      irrStr = irrStr.replaceAll('%', '');
      
      // Parse as double and format
      double roi = double.tryParse(roiStr) ?? 0.0;
      double irr = double.tryParse(irrStr) ?? 0.0;
      
      return {
        'roi': '${roi.toStringAsFixed(2)}%',
        'irr': '${irr.toStringAsFixed(2)}%',
      };
    } catch (e) {
      print('InvestmentService: Failed to get ROI/IRR data - $e');
      return null;
    }
  }
}
