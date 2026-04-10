import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plutus_fe_prototype/models/investment_model.dart';
import 'package:plutus_fe_prototype/services/investment_service.dart';

import '../helpers/mock_services.mocks.dart';
import '../helpers/test_fixtures.dart';

// Note: After changing IBackendFfiService or IInvestmentService interfaces,
// regenerate mocks with: dart run build_runner build --delete-conflicting-outputs

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
    test('fetches from database and caches result', () async {
      service.setUserId(1);
      final inv = createTestInvestment();
      final dbRow = {
        'id': inv.id,
        'asset_type': inv.assetType.name,
        'asset_name': inv.assetName,
        'quantity': inv.quantity,
        'purchase_value': inv.purchaseValue,
        'currency': inv.currency.name,
        'purchase_date': inv.purchaseDate.millisecondsSinceEpoch ~/ 1000,
        'current_price': inv.currentPrice,
      };

      when(mockDb.getInvestmentsByUserId(1))
          .thenAnswer((_) async => [dbRow]);

      final result = await service.getInvestmentList();

      expect(result.length, 1);
      expect(result[0].assetName, 'AAPL');
      verify(mockDb.getInvestmentsByUserId(1)).called(1);
    });

    test('returns cached data on second call within 5 minutes', () async {
      service.setUserId(1);
      final inv = createTestInvestment();
      final dbRow = {
        'id': inv.id,
        'asset_type': inv.assetType.name,
        'asset_name': inv.assetName,
        'quantity': inv.quantity,
        'purchase_value': inv.purchaseValue,
        'currency': inv.currency.name,
        'purchase_date': inv.purchaseDate.millisecondsSinceEpoch ~/ 1000,
        'current_price': inv.currentPrice,
      };

      when(mockDb.getInvestmentsByUserId(1))
          .thenAnswer((_) async => [dbRow]);

      await service.getInvestmentList();
      final result = await service.getInvestmentList();

      expect(result.length, 1);
      // Should only call DB once due to caching
      verify(mockDb.getInvestmentsByUserId(1)).called(1);
    });

    test('bypasses cache when forceRefresh is true', () async {
      service.setUserId(1);
      final inv = createTestInvestment();
      final dbRow = {
        'id': inv.id,
        'asset_type': inv.assetType.name,
        'asset_name': inv.assetName,
        'quantity': inv.quantity,
        'purchase_value': inv.purchaseValue,
        'currency': inv.currency.name,
        'purchase_date': inv.purchaseDate.millisecondsSinceEpoch ~/ 1000,
        'current_price': inv.currentPrice,
      };

      when(mockDb.getInvestmentsByUserId(1))
          .thenAnswer((_) async => [dbRow]);

      await service.getInvestmentList();
      await service.getInvestmentList(forceRefresh: true);

      verify(mockDb.getInvestmentsByUserId(1)).called(2);
    });

    test('returns empty list when no userId is set', () async {
      final result = await service.getInvestmentList();

      expect(result, isEmpty);
    });
  });

  group('deleteInvestment', () {
    test('deletes from database and clears cache', () async {
      when(mockFfi.isAvailable).thenReturn(false);
      when(mockDb.getInvestmentById('inv_del'))
          .thenAnswer((_) async => null);
      when(mockDb.deleteInvestment('inv_del'))
          .thenAnswer((_) async {});

      await service.deleteInvestment('inv_del');

      verify(mockDb.deleteInvestment('inv_del')).called(1);
    });

    test('deletes transaction and investment from database', () async {
      when(mockFfi.isAvailable).thenReturn(false);
      when(mockDb.getInvestmentById('inv_del'))
          .thenAnswer((_) async => {
                'currency': 'VND',
                'purchase_value': 1000.0,
                'asset_name': 'AAPL',
                'quantity': 10.0,
              });
      when(mockDb.deleteTransactionById('inv_tx_inv_del'))
          .thenAnswer((_) async {});
      when(mockDb.deleteInvestment('inv_del'))
          .thenAnswer((_) async {});

      await service.deleteInvestment('inv_del');

      verify(mockDb.deleteTransactionById('inv_tx_inv_del')).called(1);
      verify(mockDb.deleteInvestment('inv_del')).called(1);
    });

    test('throws on empty investment ID', () {
      expect(
        () => service.deleteInvestment(''),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('clearCache', () {
    test('forces next getInvestmentList to fetch from database', () async {
      service.setUserId(1);
      final inv = createTestInvestment();
      final dbRow = {
        'id': inv.id,
        'asset_type': inv.assetType.name,
        'asset_name': inv.assetName,
        'quantity': inv.quantity,
        'purchase_value': inv.purchaseValue,
        'currency': inv.currency.name,
        'purchase_date': inv.purchaseDate.millisecondsSinceEpoch ~/ 1000,
        'current_price': inv.currentPrice,
      };

      when(mockDb.getInvestmentsByUserId(1))
          .thenAnswer((_) async => [dbRow]);

      await service.getInvestmentList();
      service.clearCache();
      await service.getInvestmentList();

      verify(mockDb.getInvestmentsByUserId(1)).called(2);
    });
  });

  group('getInvestmentDetail', () {
    test('returns matching investment by commodity name', () async {
      service.setUserId(1);
      final inv = createTestInvestment(id: 'detail_1', assetName: 'BTC');
      final dbRow = {
        'id': inv.id,
        'asset_type': inv.assetType.name,
        'asset_name': inv.assetName,
        'quantity': inv.quantity,
        'purchase_value': inv.purchaseValue,
        'currency': inv.currency.name,
        'purchase_date': inv.purchaseDate.millisecondsSinceEpoch ~/ 1000,
        'current_price': inv.currentPrice,
      };

      when(mockDb.getInvestmentsByUserId(1))
          .thenAnswer((_) async => [dbRow]);

      final result = await service.getInvestmentDetail('BTC');

      expect(result.assetName, 'BTC');
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
      service.setUserId(1);
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
      when(mockFfi.isAvailable).thenReturn(true);
      // ignore: argument_type_not_assignable (resolved after mock regeneration)
      when(mockFfi.addInvestment(argThat(isA<String>()))).thenReturn('{"code":200}');
      // ignore: argument_type_not_assignable (resolved after mock regeneration)
      when(mockDb.insertInvestment(1, argThat(isA<Map<String, dynamic>>())))
          .thenAnswer((_) async => 1);
      when(mockDb.insertTransaction(1, argThat(isA<Map<String, dynamic>>())))
          .thenAnswer((_) async => 1);

      final newId = await service.saveInvestment(inv);

      expect(newId, startsWith('inv_'));
      verify(mockPrice.getCurrentPrice('TSLA')).called(1);
      // ignore: argument_type_not_assignable (resolved after mock regeneration)
      verify(mockDb.insertInvestment(1, argThat(isA<Map<String, dynamic>>()))).called(1);
      verify(mockDb.insertTransaction(1, argThat(isA<Map<String, dynamic>>()))).called(1);
    });

    test('saves investment without price fetch for bond type', () async {
      service.setUserId(1);
      final inv = createTestInvestment(
        id: '',
        assetType: AssetType.bond,
        assetName: 'US-BOND',
        currentPrice: null,
      );

      when(mockFfi.isAvailable).thenReturn(true);
      // ignore: argument_type_not_assignable (resolved after mock regeneration)
      when(mockFfi.addInvestment(argThat(isA<String>()))).thenReturn('{"code":200}');
      // ignore: argument_type_not_assignable (resolved after mock regeneration)
      when(mockDb.insertInvestment(1, argThat(isA<Map<String, dynamic>>())))
          .thenAnswer((_) async => 1);
      when(mockDb.insertTransaction(1, argThat(isA<Map<String, dynamic>>())))
          .thenAnswer((_) async => 1);

      final newId = await service.saveInvestment(inv);

      expect(newId, startsWith('inv_'));
      // ignore: argument_type_not_assignable (resolved after mock regeneration)
      verifyNever(mockPrice.getCurrentPrice(argThat(isA<String>())));
    });
  });

  group('getInvestmentReport', () {
    test('returns report data from FFI', () async {
      when(mockFfi.isAvailable).thenReturn(true);
      // ignore: argument_type_not_assignable (resolved after mock regeneration)
      when(mockFfi.getInvestmentReport(argThat(isA<String>())))
          .thenReturn(jsonEncode({'roi': 12.5, 'irr': 8.3}));

      final result = await service.getInvestmentReport(currency: 'USD');

      expect(result['roi'], 12.5);
      expect(result['irr'], 8.3);
    });

    test('returns zeros when FFI is unavailable', () async {
      when(mockFfi.isAvailable).thenReturn(false);

      final result = await service.getInvestmentReport();

      expect(result['roi'], 0.0);
      expect(result['irr'], 0.0);
    });

    test('returns zeros on FFI error', () async {
      when(mockFfi.isAvailable).thenReturn(true);
      // ignore: argument_type_not_assignable (resolved after mock regeneration)
      when(mockFfi.getInvestmentReport(argThat(isA<String>())))
          .thenReturn(jsonEncode({'code': 500, 'message': 'error'}));

      final result = await service.getInvestmentReport();

      expect(result['roi'], 0.0);
      expect(result['irr'], 0.0);
    });
  });
}
