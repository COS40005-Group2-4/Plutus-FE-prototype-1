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

  group('recordSale', () {
    Map<String, dynamic> rowFor(InvestmentModel inv) => {
          'id': inv.id,
          'asset_type': inv.assetType.name,
          'asset_name': inv.assetName,
          'quantity': inv.quantity,
          'purchase_value': inv.purchaseValue,
          'total_cost_basis': inv.totalCostBasis,
          'currency': inv.currency.name,
          'purchase_date': inv.purchaseDate.millisecondsSinceEpoch ~/ 1000,
          'current_price': inv.currentPrice,
          'status': inv.isClosed ? 'closed' : 'active',
        };

    setUp(() {
      service.setUserId(1);
      // Stub journal rebuild dependency — not exercised here.
      when(mockDb.getTransactionsByUserId(any))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);
      when(mockDb.getInvestmentsByUserId(any))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);
    });

    test('partial sale halves cost basis proportionally and stays active', () async {
      final inv = createTestInvestment(
        id: 'inv_1',
        quantity: 10.0,
        purchaseValue: 1000.0,
      );
      when(mockDb.getInvestmentById('inv_1'))
          .thenAnswer((_) async => rowFor(inv));
      when(mockDb.insertTransaction(any, any)).thenAnswer((_) async => 42);
      when(mockDb.insertInvestmentSale(any)).thenAnswer((_) async => 1);
      when(mockDb.updateInvestment(any, any)).thenAnswer((_) async {});

      final result = await service.recordSale(
        investmentId: 'inv_1',
        quantity: 5.0,
        pricePerUnit: 150.0,
        date: DateTime(2025, 6, 1),
        cashAccount: 'Assets:Cash:Bank',
      );

      // Avg cost = 100/unit, basis relieved = 500, proceeds = 750, gain = 250
      expect(result.sale.costBasisRelieved, closeTo(500.0, 1e-9));
      expect(result.sale.realizedGain, closeTo(250.0, 1e-9));
      expect(result.updatedInvestment.quantity, 5.0);
      expect(result.updatedInvestment.totalCostBasis, closeTo(500.0, 1e-9));
      expect(result.updatedInvestment.isClosed, isFalse);

      final captured = verify(mockDb.updateInvestment('inv_1', captureAny))
          .captured
          .single as Map<String, dynamic>;
      expect(captured['quantity'], 5.0);
      expect(captured['total_cost_basis'], closeTo(500.0, 1e-9));
      expect(captured['status'], 'active');
      expect(captured['closed_at'], isNull);
    });

    test('full sale flips status to closed and zeros quantity', () async {
      final inv = createTestInvestment(
        id: 'inv_2',
        quantity: 4.0,
        purchaseValue: 800.0,
      );
      when(mockDb.getInvestmentById('inv_2'))
          .thenAnswer((_) async => rowFor(inv));
      when(mockDb.insertTransaction(any, any)).thenAnswer((_) async => 99);
      when(mockDb.insertInvestmentSale(any)).thenAnswer((_) async => 1);
      when(mockDb.updateInvestment(any, any)).thenAnswer((_) async {});

      final result = await service.recordSale(
        investmentId: 'inv_2',
        quantity: 4.0,
        pricePerUnit: 250.0,
        date: DateTime(2025, 7, 1),
        cashAccount: 'Assets:Cash:Bank',
      );

      expect(result.updatedInvestment.quantity, 0.0);
      expect(result.updatedInvestment.totalCostBasis, 0.0);
      expect(result.updatedInvestment.isClosed, isTrue);

      final captured = verify(mockDb.updateInvestment('inv_2', captureAny))
          .captured
          .single as Map<String, dynamic>;
      expect(captured['status'], 'closed');
      expect(captured['closed_at'], isNotNull);
    });

    test('sale transaction uses three balanced postings', () async {
      final inv = createTestInvestment(
        id: 'inv_3',
        quantity: 10.0,
        purchaseValue: 1000.0,
        assetName: 'GOLD',
      );
      when(mockDb.getInvestmentById('inv_3'))
          .thenAnswer((_) async => rowFor(inv));
      when(mockDb.insertTransaction(any, any)).thenAnswer((_) async => 7);
      when(mockDb.insertInvestmentSale(any)).thenAnswer((_) async => 1);
      when(mockDb.updateInvestment(any, any)).thenAnswer((_) async {});

      await service.recordSale(
        investmentId: 'inv_3',
        quantity: 2.0,
        pricePerUnit: 130.0,
        date: DateTime(2025, 8, 1),
        cashAccount: 'Assets:Cash:USD',
      );

      final captured = verify(mockDb.insertTransaction(1, captureAny))
          .captured
          .single as Map<String, dynamic>;
      final postings = (captured['postings'] as List).cast<Map<String, dynamic>>();
      expect(postings.length, 3);
      // Cash leg (proceeds, +ve)
      expect(postings[0]['account'], 'Assets:Cash:USD');
      expect(postings[0]['amount'], closeTo(260.0, 1e-9));
      // Asset leg (qty out, -ve commodity)
      expect(postings[1]['account'], 'Assets:investment:GOLD');
      expect(postings[1]['amount'], closeTo(-2.0, 1e-9));
      expect(postings[1]['commodity'], 'GOLD');
      // Realised gain leg = -(260 - 200) = -60 (credit)
      expect(postings[2]['account'], 'Income:RealizedGains:GOLD');
      expect(postings[2]['amount'], closeTo(-60.0, 1e-9));
    });

    test('rejects oversell', () async {
      final inv = createTestInvestment(id: 'inv_4', quantity: 1.0);
      when(mockDb.getInvestmentById('inv_4'))
          .thenAnswer((_) async => rowFor(inv));

      expect(
        () => service.recordSale(
          investmentId: 'inv_4',
          quantity: 5.0,
          pricePerUnit: 100.0,
          date: DateTime(2025, 1, 1),
          cashAccount: 'Assets:Cash',
        ),
        throwsArgumentError,
      );
    });
  });

  group('addPricePoint', () {
    test('persists, mirrors latest price into investment, and notifies', () async {
      service.setUserId(1);
      when(mockDb.insertInvestmentPricePoint(any)).thenAnswer((_) async => 11);
      when(mockDb.getLatestInvestmentPricePoint('inv_1'))
          .thenAnswer((_) async => {
                'id': 11,
                'investment_id': 'inv_1',
                'date': DateTime(2025, 6, 1).millisecondsSinceEpoch ~/ 1000,
                'price': 199.5,
              });
      when(mockDb.updateInvestment(any, any)).thenAnswer((_) async {});

      final point = await service.addPricePoint(
        investmentId: 'inv_1',
        date: DateTime(2025, 6, 1),
        price: 199.5,
        note: 'manual',
      );

      expect(point.price, 199.5);
      verify(mockDb.updateInvestment('inv_1', argThat(predicate<Map<String, dynamic>>((m) => m['current_price'] == 199.5)))).called(1);
    });

    test('rejects non-positive prices', () {
      service.setUserId(1);
      expect(
        () => service.addPricePoint(
          investmentId: 'inv_1',
          date: DateTime(2025, 1, 1),
          price: 0,
        ),
        throwsArgumentError,
      );
    });
  });
}
