import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plutus_fe_prototype/models/investment_model.dart';
import 'package:plutus_fe_prototype/services/investment_service.dart';

import '../helpers/mock_services.mocks.dart';
import '../helpers/test_fixtures.dart';

void main() {
  late MockIBackendFfiService mockFfi;
  late MockIPriceApiService mockPrice;
  late MockIDatabaseService mockDb;
  late InvestmentService service;

  setUp(() {
    mockFfi = MockIBackendFfiService();
    mockPrice = MockIPriceApiService();
    mockDb = MockIDatabaseService();
    service = InvestmentService(
      ffiService: mockFfi,
      priceService: mockPrice,
      dbService: mockDb,
    );
  });

  Map<String, dynamic> investmentToFfiJson(InvestmentModel inv) {
    return {
      'id': inv.id,
      'asset_type': inv.assetType.name,
      'asset_name': inv.assetName,
      'quantity': inv.quantity,
      'purchase_value': inv.purchaseValue,
      'currency': inv.currency.name,
      'purchase_date': inv.purchaseDate.millisecondsSinceEpoch ~/ 1000,
      if (inv.currentPrice != null) 'current_price': inv.currentPrice,
    };
  }

  group('getTotalPortfolioValue', () {
    test('returns 0.0 for empty list', () {
      final result = service.getTotalPortfolioValue([]);

      expect(result, 0.0);
    });

    test('sums current values of multiple investments', () {
      final inv1 = createTestInvestment(
        id: 'inv_1',
        quantity: 10.0,
        currentPrice: 100.0,
        purchaseValue: 800.0,
      );
      final inv2 = createTestInvestment(
        id: 'inv_2',
        quantity: 5.0,
        currentPrice: 200.0,
        purchaseValue: 500.0,
      );

      // inv1: 10 * 100 = 1000, inv2: 5 * 200 = 1000 => total = 2000
      final result = service.getTotalPortfolioValue([inv1, inv2]);

      expect(result, 2000.0);
    });

    test('uses purchaseValue when currentPrice is null', () {
      final inv = createTestInvestment(
        id: 'inv_1',
        quantity: 10.0,
        currentPrice: null,
        purchaseValue: 500.0,
      );

      final result = service.getTotalPortfolioValue([inv]);

      expect(result, 500.0);
    });
  });

  group('getTotalGainLoss', () {
    test('returns 0.0 for empty list', () {
      final result = service.getTotalGainLoss([]);

      expect(result, 0.0);
    });

    test('calculates positive gain percentage', () {
      // purchaseValue = 1000, currentValue = 10 * 150 = 1500
      // gain = ((1500 - 1000) / 1000) * 100 = 50%
      final inv = createTestInvestment(
        id: 'inv_1',
        quantity: 10.0,
        purchaseValue: 1000.0,
        currentPrice: 150.0,
      );

      final result = service.getTotalGainLoss([inv]);

      expect(result, closeTo(50.0, 0.01));
    });

    test('calculates negative loss percentage', () {
      // purchaseValue = 1000, currentValue = 10 * 50 = 500
      // loss = ((500 - 1000) / 1000) * 100 = -50%
      final inv = createTestInvestment(
        id: 'inv_1',
        quantity: 10.0,
        purchaseValue: 1000.0,
        currentPrice: 50.0,
      );

      final result = service.getTotalGainLoss([inv]);

      expect(result, closeTo(-50.0, 0.01));
    });

    test('returns 0.0 when total cost is zero', () {
      final inv = createTestInvestment(
        id: 'inv_1',
        quantity: 10.0,
        purchaseValue: 0.0,
        currentPrice: 100.0,
      );

      final result = service.getTotalGainLoss([inv]);

      expect(result, 0.0);
    });
  });

  group('getInvestmentList', () {
    test('fetches from backend and caches result', () async {
      final inv = createTestInvestment();
      final ffiResponse = {
        'investments': [investmentToFfiJson(inv)],
      };

      when(mockFfi.getInvestmentList())
          .thenAnswer((_) async => ffiResponse);

      final result = await service.getInvestmentList();

      expect(result.length, 1);
      expect(result[0].assetName, 'AAPL');
      verify(mockFfi.getInvestmentList()).called(1);
    });

    test('returns cached data on second call within 5 minutes', () async {
      final inv = createTestInvestment();
      final ffiResponse = {
        'investments': [investmentToFfiJson(inv)],
      };

      when(mockFfi.getInvestmentList())
          .thenAnswer((_) async => ffiResponse);

      await service.getInvestmentList();
      final result = await service.getInvestmentList();

      expect(result.length, 1);
      // Should only call FFI once due to caching
      verify(mockFfi.getInvestmentList()).called(1);
    });

    test('bypasses cache when forceRefresh is true', () async {
      final inv = createTestInvestment();
      final ffiResponse = {
        'investments': [investmentToFfiJson(inv)],
      };

      when(mockFfi.getInvestmentList())
          .thenAnswer((_) async => ffiResponse);

      await service.getInvestmentList();
      await service.getInvestmentList(forceRefresh: true);

      verify(mockFfi.getInvestmentList()).called(2);
    });

    test('throws when response is missing investments key', () async {
      when(mockFfi.getInvestmentList())
          .thenAnswer((_) async => {'other': 'data'});

      expect(
        () => service.getInvestmentList(),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when backend fails', () async {
      when(mockFfi.getInvestmentList())
          .thenThrow(Exception('Backend unavailable'));

      expect(
        () => service.getInvestmentList(),
        throwsA(isA<Exception>()),
      );
    });

    test('persists investments to db when userId is set', () async {
      service.setUserId(1);
      final inv = createTestInvestment(id: 'inv_persist');
      final ffiResponse = {
        'investments': [investmentToFfiJson(inv)],
      };

      when(mockFfi.getInvestmentList())
          .thenAnswer((_) async => ffiResponse);
      when(mockDb.getInvestmentById('inv_persist'))
          .thenAnswer((_) async => null);
      when(mockDb.insertInvestment(1, any))
          .thenAnswer((_) async => 1);

      await service.getInvestmentList();

      verify(mockDb.insertInvestment(1, any)).called(1);
    });
  });

  group('deleteInvestment', () {
    test('deletes from backend and database and clears cache', () async {
      when(mockFfi.deleteInvestment('inv_del'))
          .thenAnswer((_) async {});
      when(mockDb.deleteInvestment('inv_del'))
          .thenAnswer((_) async {});

      await service.deleteInvestment('inv_del');

      verify(mockFfi.deleteInvestment('inv_del')).called(1);
      verify(mockDb.deleteInvestment('inv_del')).called(1);
    });

    test('throws on empty investment ID', () {
      expect(
        () => service.deleteInvestment(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when backend delete fails', () async {
      when(mockFfi.deleteInvestment('inv_fail'))
          .thenThrow(Exception('Backend error'));

      expect(
        () => service.deleteInvestment('inv_fail'),
        throwsA(isA<Exception>()),
      );
    });

    test('clears cache after deletion so next fetch hits backend', () async {
      final inv = createTestInvestment();
      final ffiResponse = {
        'investments': [investmentToFfiJson(inv)],
      };

      when(mockFfi.getInvestmentList())
          .thenAnswer((_) async => ffiResponse);
      when(mockFfi.deleteInvestment(any))
          .thenAnswer((_) async {});
      when(mockDb.deleteInvestment(any))
          .thenAnswer((_) async {});

      // Populate cache
      await service.getInvestmentList();
      // Delete clears cache
      await service.deleteInvestment('inv_001');
      // Next fetch should hit backend again
      await service.getInvestmentList();

      verify(mockFfi.getInvestmentList()).called(2);
    });
  });

  group('clearCache', () {
    test('forces next getInvestmentList to fetch from backend', () async {
      final inv = createTestInvestment();
      final ffiResponse = {
        'investments': [investmentToFfiJson(inv)],
      };

      when(mockFfi.getInvestmentList())
          .thenAnswer((_) async => ffiResponse);

      await service.getInvestmentList();
      service.clearCache();
      await service.getInvestmentList();

      verify(mockFfi.getInvestmentList()).called(2);
    });
  });

  group('getInvestmentDetail', () {
    test('returns investment detail from backend', () async {
      final inv = createTestInvestment(id: 'detail_1', assetName: 'BTC');
      when(mockFfi.getInvestmentDetail('BTC'))
          .thenAnswer((_) async => investmentToFfiJson(inv));

      final result = await service.getInvestmentDetail('BTC');

      expect(result.assetName, 'BTC');
      verify(mockFfi.getInvestmentDetail('BTC')).called(1);
    });

    test('throws on empty commodity', () {
      expect(
        () => service.getInvestmentDetail(''),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('saveInvestment', () {
    test('saves investment with price data for stock type', () async {
      final inv = createTestInvestment(
        id: '',
        assetType: AssetType.stock,
        assetName: 'TSLA',
        currentPrice: null,
      );

      when(mockPrice.getCurrentPrice('TSLA'))
          .thenAnswer((_) async => 250.0);
      when(mockPrice.getHistoricalPrices('TSLA', 30))
          .thenAnswer((_) async => null);
      when(mockFfi.saveInvestment(any))
          .thenAnswer((_) async => 'new_inv_id');

      final newId = await service.saveInvestment(inv);

      expect(newId, 'new_inv_id');
      verify(mockPrice.getCurrentPrice('TSLA')).called(1);
      verify(mockFfi.saveInvestment(any)).called(1);
    });

    test('saves investment without price fetch for bond type', () async {
      final inv = createTestInvestment(
        id: '',
        assetType: AssetType.bond,
        assetName: 'US-BOND',
        currentPrice: null,
      );

      when(mockFfi.saveInvestment(any))
          .thenAnswer((_) async => 'bond_id');

      final newId = await service.saveInvestment(inv);

      expect(newId, 'bond_id');
      verifyNever(mockPrice.getCurrentPrice(any));
    });
  });

  group('getRoiIrrData', () {
    test('returns formatted ROI and IRR data', () async {
      when(mockFfi.getRoiData())
          .thenAnswer((_) async => {'roi': '12.5', 'irr': '8.3'});

      final result = await service.getRoiIrrData();

      expect(result, isNotNull);
      expect(result!['roi'], '12.50%');
      expect(result['irr'], '8.30%');
    });

    test('returns null on error', () async {
      when(mockFfi.getRoiData())
          .thenThrow(Exception('Backend error'));

      final result = await service.getRoiIrrData();

      expect(result, isNull);
    });
  });
}
