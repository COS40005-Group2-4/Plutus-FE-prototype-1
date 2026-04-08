import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/investment_model.dart';
import '../utils/date_format_utils.dart';
import 'interfaces/i_backend_ffi_service.dart';
import 'interfaces/i_price_api_service.dart';
import 'interfaces/i_database_service.dart';
import 'interfaces/i_investment_service.dart';
import '../di/service_locator.dart';

class InvestmentService implements IInvestmentService {
  final IBackendFfiService _ffiService;
  final IPriceApiService _priceService;
  final IDatabaseService _dbService;

  InvestmentService({
    IBackendFfiService? ffiService,
    IPriceApiService? priceService,
    IDatabaseService? dbService,
  })  : _ffiService = ffiService ?? sl<IBackendFfiService>(),
        _priceService = priceService ?? sl<IPriceApiService>(),
        _dbService = dbService ?? sl<IDatabaseService>();

  List<InvestmentModel>? _cachedInvestments;
  DateTime? _lastFetchTime;
  int? _currentUserId;
  static const Duration _cacheExpiration = Duration(minutes: 5);

  @override
  void setUserId(int userId) {
    _currentUserId = userId;
  }

  @override
  Future<List<InvestmentModel>> getInvestmentList({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedInvestments != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheExpiration) {
      return _cachedInvestments!;
    }

    try {
      if (_currentUserId == null) return [];

      final investmentMaps = await _dbService.getInvestmentsByUserId(_currentUserId!);
      final investments = investmentMaps
          .map((m) => InvestmentModel.fromJson(m))
          .toList();

      _cachedInvestments = investments;
      _lastFetchTime = DateTime.now();
      return investments;
    } catch (e) {
      throw Exception('Failed to fetch investment list: $e');
    }
  }

  @override
  Future<InvestmentModel> getInvestmentDetail(String commodity) async {
    if (commodity.isEmpty) {
      throw ArgumentError('Commodity cannot be empty');
    }

    final investments = await getInvestmentList();
    return investments.firstWhere(
      (inv) => inv.assetName == commodity || inv.id == commodity,
      orElse: () => throw Exception('Investment not found: $commodity'),
    );
  }

  @override
  void clearCache() {
    _cachedInvestments = null;
    _lastFetchTime = null;
  }

  @override
  Future<void> deleteInvestment(String investmentId) async {
    if (investmentId.isEmpty) {
      throw ArgumentError('Investment ID cannot be empty');
    }

    debugPrint('InvestmentService: Deleting investment $investmentId');

    // Get the investment before deleting so we can create a reversal posting
    try {
      final existing = await _dbService.getInvestmentById(investmentId);
      if (existing != null && _ffiService.isAvailable) {
        // Create reversal transaction in the Go journal
        final currency = existing['currency'] as String? ?? 'VND';
        final amount = (existing['purchase_value'] as num?)?.toDouble() ?? 0.0;
        final assetName = existing['asset_name'] as String? ?? '';
        final quantity = (existing['quantity'] as num?)?.toDouble() ?? 0.0;

        final reversalJson = jsonEncode({
          'date': toCustomDate(DateTime.now()),
          'payee': '',
          'desc': 'Investment deletion reversal: $assetName',
          'postings': [
            {
              'account': 'Assets:investment:$assetName',
              'amount': {'value': -quantity, 'commodity': assetName},
            },
            {
              'account': 'Assets:cash',
              'amount': {'value': amount, 'commodity': currency},
            },
          ],
        });
        _ffiService.addInvestment(reversalJson);
      }

      await _dbService.deleteInvestment(investmentId);
      clearCache();
      debugPrint('InvestmentService: Delete successful');
    } catch (e) {
      debugPrint('InvestmentService: Delete failed - $e');
      throw Exception('Failed to delete investment: $e');
    }
  }

  @override
  Future<String> saveInvestment(InvestmentModel investment) async {
    debugPrint('InvestmentService: Saving investment ${investment.assetName}');

    try {
      double? currentPrice;
      List<PriceHistoryPoint>? priceHistory;

      if (investment.assetType == AssetType.crypto ||
          investment.assetType == AssetType.stock) {
        debugPrint('InvestmentService: Fetching price data for ${investment.assetName}');
        currentPrice = await _priceService.getCurrentPrice(investment.assetName);
        debugPrint('InvestmentService: Current price: $currentPrice');

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
        }
      }

      final investmentWithPrices = InvestmentModel(
        id: investment.id.isNotEmpty
            ? investment.id
            : 'inv_${DateTime.now().millisecondsSinceEpoch}',
        assetType: investment.assetType,
        assetName: investment.assetName,
        quantity: investment.quantity,
        purchaseValue: investment.purchaseValue,
        currency: investment.currency,
        purchaseDate: investment.purchaseDate,
        currentPrice: currentPrice,
        priceHistory: priceHistory,
      );

      // Persist to SQLite
      if (_currentUserId != null) {
        await _dbService.insertInvestment(_currentUserId!, {
          'id': investmentWithPrices.id,
          'asset_type': investmentWithPrices.assetType.name,
          'asset_name': investmentWithPrices.assetName,
          'quantity': investmentWithPrices.quantity,
          'purchase_value': investmentWithPrices.purchaseValue,
          'currency': investmentWithPrices.currency.name,
          'purchase_date': investmentWithPrices.purchaseDate.millisecondsSinceEpoch ~/ 1000,
          'current_price': investmentWithPrices.currentPrice,
        });
      }

      // Record the investment transaction in the Go journal
      if (_ffiService.isAvailable) {
        final txJson = jsonEncode({
          'date': toCustomDate(investmentWithPrices.purchaseDate),
          'payee': '',
          'desc': 'Investment purchase: ${investmentWithPrices.assetName}',
          'postings': [
            {
              'account': 'Assets:investment:${investmentWithPrices.assetName}',
              'amount': {
                'value': investmentWithPrices.quantity,
                'commodity': investmentWithPrices.assetName,
              },
            },
            {
              'account': 'Assets:cash',
              'amount': {
                'value': -investmentWithPrices.purchaseValue,
                'commodity': investmentWithPrices.currency.name.toUpperCase(),
              },
            },
          ],
        });
        _ffiService.addInvestment(txJson);
      }

      clearCache();
      debugPrint('InvestmentService: Save successful with ID: ${investmentWithPrices.id}');
      return investmentWithPrices.id;
    } catch (e) {
      debugPrint('InvestmentService: Save failed - $e');
      throw Exception('Failed to save investment: $e');
    }
  }

  @override
  double getTotalPortfolioValue(List<InvestmentModel> investments) {
    if (investments.isEmpty) return 0.0;
    return investments.fold(0.0, (sum, inv) => sum + inv.getCurrentValue());
  }

  @override
  double getTotalGainLoss(List<InvestmentModel> investments) {
    if (investments.isEmpty) return 0.0;
    final totalValue = getTotalPortfolioValue(investments);
    final totalCost = investments.fold(0.0, (sum, inv) => sum + inv.purchaseValue);
    if (totalCost <= 0) return 0.0;
    return ((totalValue - totalCost) / totalCost) * 100;
  }

  @override
  Future<InvestmentModel> refreshPriceData(InvestmentModel investment) async {
    debugPrint('InvestmentService: Refreshing price data for ${investment.assetName}');

    try {
      double? currentPrice;
      List<PriceHistoryPoint>? priceHistory;

      if (investment.assetType == AssetType.crypto ||
          investment.assetType == AssetType.stock) {
        currentPrice = await _priceService.getCurrentPrice(investment.assetName);
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
        }
      }

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
      debugPrint('InvestmentService: Price refresh failed - $e');
      return investment;
    }
  }

  @override
  Future<Map<String, dynamic>> getInvestmentReport({String? currency}) async {
    if (!_ffiService.isAvailable) {
      return {'roi': 0.0, 'irr': 0.0};
    }

    try {
      final now = DateTime.now();
      final twoYearsAgo = DateTime(now.year - 2, now.month, now.day);
      final requestJson = jsonEncode({
        'start': toCustomDate(twoYearsAgo),
        'end': toCustomDate(now),
        'currency': currency ?? 'VND',
      });

      final result = _ffiService.getInvestmentReport(requestJson);
      final decoded = jsonDecode(result) as Map<String, dynamic>;

      if (decoded.containsKey('code')) {
        debugPrint('InvestmentService: Report error — ${decoded['message']}');
        return {'roi': 0.0, 'irr': 0.0};
      }

      return decoded;
    } catch (e) {
      debugPrint('InvestmentService: Failed to get investment report - $e');
      return {'roi': 0.0, 'irr': 0.0};
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getUnsyncedInvestments(int userId) async {
    _currentUserId ??= userId;
    return await _dbService.getUnsyncedInvestments(userId);
  }

  @override
  Future<void> markInvestmentAsSynced(String investmentId) async {
    await _dbService.markInvestmentAsSynced(investmentId);
  }
}
