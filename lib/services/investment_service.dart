import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/investment_model.dart';
import '../utils/date_format_utils.dart';
import 'interfaces/i_backend_ffi_service.dart';
import 'interfaces/i_price_api_service.dart';
import 'interfaces/i_database_service.dart';
import 'interfaces/i_investment_service.dart';
import 'journal_initializer.dart';
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

  final StreamController<void> _changedController =
      StreamController<void>.broadcast();

  @override
  Stream<void> get onChanged => _changedController.stream;

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

    try {
      // Delete the matching transaction from SQLite so journal stays in sync
      final txId = 'inv_tx_$investmentId';
      await _dbService.deleteTransactionById(txId);

      await _dbService.deleteInvestment(investmentId);
      clearCache();

      // Rebuild Go journal from SQLite for consistency
      await _rebuildJournal();

      _changedController.add(null);
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

      // Persist investment metadata to SQLite
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

        // Also persist the double-entry transaction so the Go journal
        // can reconstruct it on app restart via JournalInitializer.
        final currencyStr = investmentWithPrices.currency.name.toUpperCase();
        await _dbService.insertTransaction(_currentUserId!, {
          'transaction_id': 'inv_tx_${investmentWithPrices.id}',
          'type': 'investment',
          'amount': investmentWithPrices.purchaseValue,
          'currency': currencyStr,
          'description': 'Investment purchase: ${investmentWithPrices.assetName}',
          'payee': '',
          'date': investmentWithPrices.purchaseDate.toIso8601String(),
          'postings': [
            {
              'account': 'Assets:investment:${investmentWithPrices.assetName}',
              'amount': investmentWithPrices.quantity,
              'commodity': investmentWithPrices.assetName,
            },
            {
              'account': 'Assets:cash',
              'amount': -investmentWithPrices.purchaseValue,
              'commodity': currencyStr,
            },
          ],
        });
      }

      // Rebuild Go journal from full SQLite data so ROI/IRR picks up the change
      await _rebuildJournal();

      clearCache();
      _changedController.add(null);
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
      return _dartFallbackReport();
    }

    try {
      final now = DateTime.now();
      // Use a wide window (50 years) to capture all investments regardless of purchase date
      final earliest = DateTime(now.year - 50, 1, 1);
      final requestJson = jsonEncode({
        'start': toCustomDate(earliest),
        'end': toCustomDate(now),
        'currency': currency ?? 'VND',
      });

      final result = _ffiService.getInvestmentReport(requestJson);
      final decoded = jsonDecode(result) as Map<String, dynamic>;

      if (decoded.containsKey('code')) {
        debugPrint('InvestmentService: Report error — ${decoded['message']}');
        return _dartFallbackReport();
      }

      return decoded;
    } catch (e) {
      debugPrint('InvestmentService: Failed to get investment report - $e');
      return _dartFallbackReport();
    }
  }

  /// Pure Dart ROI/IRR calculation as fallback when FFI is unavailable.
  Future<Map<String, dynamic>> _dartFallbackReport() async {
    try {
      final investments = await getInvestmentList();
      if (investments.isEmpty) return {'roi': 0.0, 'irr': 0.0};

      double totalCost = 0;
      double totalCurrentValue = 0;

      for (final inv in investments) {
        totalCost += inv.purchaseValue;
        totalCurrentValue += (inv.currentPrice ?? 0) * inv.quantity;
      }

      // ROI = (current - cost) / cost * 100
      final roi = totalCost > 0
          ? (totalCurrentValue - totalCost) / totalCost * 100
          : 0.0;

      // IRR approximation via Newton's method on cash flows
      final irr = _computeIrr(investments);

      return {'roi': roi, 'irr': irr};
    } catch (e) {
      debugPrint('InvestmentService: Dart fallback report failed - $e');
      return {'roi': 0.0, 'irr': 0.0};
    }
  }

  /// Approximate annualized IRR using Newton's method.
  double _computeIrr(List<InvestmentModel> investments) {
    final now = DateTime.now();
    // Build cash flow list: negative at purchase, positive at current value
    final List<(double amount, double years)> cashFlows = [];

    for (final inv in investments) {
      final yearsAgo = now.difference(inv.purchaseDate).inDays / 365.25;
      if (yearsAgo <= 0) continue;
      cashFlows.add((-inv.purchaseValue, yearsAgo));
      final currentValue = (inv.currentPrice ?? 0) * inv.quantity;
      cashFlows.add((currentValue, 0.0));
    }

    if (cashFlows.isEmpty) return 0.0;

    // Newton's method to find rate where NPV = 0
    double rate = 0.1; // initial guess 10%
    for (int i = 0; i < 100; i++) {
      double npv = 0;
      double dnpv = 0;
      for (final (amount, years) in cashFlows) {
        final base = (1 + rate).clamp(0.001, double.maxFinite);
        final factor = 1 / math.pow(base, years);
        npv += amount * factor;
        dnpv -= years * amount * factor / base;
      }
      if (dnpv.abs() < 1e-12) break;
      final newRate = rate - npv / dnpv;
      if ((newRate - rate).abs() < 1e-8) {
        rate = newRate;
        break;
      }
      rate = newRate.clamp(-0.99, 10.0); // keep in reasonable range
    }

    return rate * 100; // return as percentage
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

  /// Rebuild the Go journal from the full SQLite dataset.
  Future<void> _rebuildJournal() async {
    try {
      final journalInit = sl<JournalInitializer>();
      await journalInit.initialize();
    } catch (e) {
      debugPrint('InvestmentService: Journal rebuild failed — $e');
    }
  }
}
