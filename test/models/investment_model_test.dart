import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/models/investment_model.dart';
import '../helpers/test_fixtures.dart';

void main() {
  group('PriceHistoryPoint', () {
    group('fromJson', () {
      test('parses date and price from JSON', () {
        final json = {'date': 1704067200, 'price': 150.0};
        final point = PriceHistoryPoint.fromJson(json);

        expect(point.date, DateTime.fromMillisecondsSinceEpoch(1704067200 * 1000));
        expect(point.price, 150.0);
      });

      test('parses string price', () {
        final json = {'date': 1704067200, 'price': '99.50'};
        final point = PriceHistoryPoint.fromJson(json);

        expect(point.price, 99.50);
      });
    });

    group('toJson', () {
      test('serializes to unix seconds', () {
        final point = PriceHistoryPoint(
          date: DateTime.fromMillisecondsSinceEpoch(1704067200 * 1000),
          price: 150.0,
        );
        final json = point.toJson();

        expect(json['date'], 1704067200);
        expect(json['price'], 150.0);
      });
    });

    group('Equatable', () {
      test('identical points are equal', () {
        final p1 = PriceHistoryPoint(date: DateTime.fromMillisecondsSinceEpoch(1704067200 * 1000), price: 100.0);
        final p2 = PriceHistoryPoint(date: DateTime.fromMillisecondsSinceEpoch(1704067200 * 1000), price: 100.0);

        expect(p1, p2);
      });

      test('different points are not equal', () {
        final p1 = PriceHistoryPoint(date: DateTime.fromMillisecondsSinceEpoch(1704067200 * 1000), price: 100.0);
        final p2 = PriceHistoryPoint(date: DateTime.fromMillisecondsSinceEpoch(1704067200 * 1000), price: 200.0);

        expect(p1, isNot(p2));
      });
    });
  });

  group('InvestmentModel', () {
    group('fromJson', () {
      test('parses all required fields', () {
        final json = {
          'id': 'inv_001',
          'asset_type': 'stock',
          'asset_name': 'AAPL',
          'quantity': 10,
          'purchase_value': 1500.0,
          'currency': 'usd',
          'purchase_date': 1704067200,
        };

        final inv = InvestmentModel.fromJson(json);

        expect(inv.id, 'inv_001');
        expect(inv.assetType, AssetType.stock);
        expect(inv.assetName, 'AAPL');
        expect(inv.quantity, 10.0);
        expect(inv.purchaseValue, 1500.0);
        expect(inv.currency, Currency.usd);
        expect(inv.purchaseDate, DateTime.fromMillisecondsSinceEpoch(1704067200 * 1000));
        expect(inv.currentPrice, isNull);
        expect(inv.priceHistory, isNull);
      });

      test('parses optional currentPrice', () {
        final json = {
          'id': 'inv_001',
          'asset_type': 'stock',
          'asset_name': 'AAPL',
          'quantity': 10,
          'purchase_value': 1500.0,
          'currency': 'usd',
          'purchase_date': 1704067200,
          'current_price': 175.0,
        };

        final inv = InvestmentModel.fromJson(json);
        expect(inv.currentPrice, 175.0);
      });

      test('parses optional priceHistory', () {
        final json = {
          'id': 'inv_001',
          'asset_type': 'crypto',
          'asset_name': 'BTC',
          'quantity': 0.5,
          'purchase_value': 20000.0,
          'currency': 'usd',
          'purchase_date': 1704067200,
          'price_history': [
            {'date': 1704067200, 'price': 40000.0},
            {'date': 1704153600, 'price': 41000.0},
          ],
        };

        final inv = InvestmentModel.fromJson(json);

        expect(inv.priceHistory, isNotNull);
        expect(inv.priceHistory!.length, 2);
        expect(inv.priceHistory!.first.price, 40000.0);
      });

      test('throws ArgumentError when required fields are missing', () {
        final json = {'id': 'inv_001', 'asset_type': 'stock'};

        expect(() => InvestmentModel.fromJson(json), throwsA(isA<ArgumentError>()));
      });

      test('parses all asset types', () {
        for (final type in AssetType.values) {
          final json = {
            'id': 'inv_001',
            'asset_type': type.name,
            'asset_name': 'Test',
            'quantity': 1,
            'purchase_value': 100,
            'currency': 'usd',
            'purchase_date': 1704067200,
          };

          final inv = InvestmentModel.fromJson(json);
          expect(inv.assetType, type);
        }
      });

      test('parses all currency types', () {
        for (final curr in Currency.values) {
          final json = {
            'id': 'inv_001',
            'asset_type': 'stock',
            'asset_name': 'Test',
            'quantity': 1,
            'purchase_value': 100,
            'currency': curr.name,
            'purchase_date': 1704067200,
          };

          final inv = InvestmentModel.fromJson(json);
          expect(inv.currency, curr);
        }
      });

      test('throws for invalid asset type', () {
        final json = {
          'id': 'inv_001',
          'asset_type': 'invalid',
          'asset_name': 'Test',
          'quantity': 1,
          'purchase_value': 100,
          'currency': 'usd',
          'purchase_date': 1704067200,
        };

        expect(() => InvestmentModel.fromJson(json), throwsA(isA<ArgumentError>()));
      });

      test('throws for invalid currency', () {
        final json = {
          'id': 'inv_001',
          'asset_type': 'stock',
          'asset_name': 'Test',
          'quantity': 1,
          'purchase_value': 100,
          'currency': 'gbp',
          'purchase_date': 1704067200,
        };

        expect(() => InvestmentModel.fromJson(json), throwsA(isA<ArgumentError>()));
      });

      test('parses quantity and purchaseValue from string', () {
        final json = {
          'id': 'inv_001',
          'asset_type': 'stock',
          'asset_name': 'AAPL',
          'quantity': '10.5',
          'purchase_value': '1575.00',
          'currency': 'usd',
          'purchase_date': 1704067200,
        };

        final inv = InvestmentModel.fromJson(json);
        expect(inv.quantity, 10.5);
        expect(inv.purchaseValue, 1575.0);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final inv = createTestInvestment();
        final json = inv.toJson();

        expect(json['id'], 'inv_001');
        expect(json['asset_type'], 'stock');
        expect(json['asset_name'], 'AAPL');
        expect(json['quantity'], 10.0);
        expect(json['purchase_value'], 1500.0);
        expect(json['currency'], 'usd');
        expect(json['purchase_date'], isA<int>());
        expect(json['current_price'], 175.0);
      });

      test('omits currentPrice when null', () {
        final inv = createTestInvestment(currentPrice: null);
        final json = inv.toJson();

        expect(json.containsKey('current_price'), false);
      });

      test('omits priceHistory when null', () {
        final inv = createTestInvestment(priceHistory: null);
        final json = inv.toJson();

        expect(json.containsKey('price_history'), false);
      });

      test('includes priceHistory when present', () {
        final inv = createTestInvestment(
          priceHistory: [
            PriceHistoryPoint(date: DateTime.fromMillisecondsSinceEpoch(1704067200 * 1000), price: 150.0),
          ],
        );
        final json = inv.toJson();

        expect(json.containsKey('price_history'), true);
        expect((json['price_history'] as List).length, 1);
      });
    });

    group('toJson/fromJson round-trip', () {
      test('preserves all data through serialization cycle', () {
        final original = createTestInvestment();
        final restored = InvestmentModel.fromJson(original.toJson());

        expect(restored, original);
      });

      test('preserves investment with null optional fields', () {
        final original = createTestInvestment(currentPrice: null, priceHistory: null);
        final restored = InvestmentModel.fromJson(original.toJson());

        expect(restored, original);
      });

      test('preserves investment with price history', () {
        final original = createTestInvestment(
          priceHistory: [
            PriceHistoryPoint(date: DateTime.fromMillisecondsSinceEpoch(1704067200 * 1000), price: 150.0),
            PriceHistoryPoint(date: DateTime.fromMillisecondsSinceEpoch(1704153600 * 1000), price: 155.0),
          ],
        );
        final restored = InvestmentModel.fromJson(original.toJson());

        expect(restored, original);
      });
    });

    group('getCurrentValue', () {
      test('returns quantity * currentPrice when currentPrice is set', () {
        final inv = createTestInvestment(quantity: 10.0, currentPrice: 175.0);

        expect(inv.getCurrentValue(), 1750.0);
      });

      test('returns purchaseValue when currentPrice is null', () {
        final inv = createTestInvestment(purchaseValue: 1500.0, currentPrice: null);

        expect(inv.getCurrentValue(), 1500.0);
      });
    });

    group('getGainLoss', () {
      test('returns positive gain', () {
        final inv = createTestInvestment(
          quantity: 10.0,
          purchaseValue: 1500.0,
          currentPrice: 175.0,
        );

        expect(inv.getGainLoss(), 250.0);
      });

      test('returns negative loss', () {
        final inv = createTestInvestment(
          quantity: 10.0,
          purchaseValue: 1500.0,
          currentPrice: 100.0,
        );

        expect(inv.getGainLoss(), -500.0);
      });

      test('returns zero when no change', () {
        final inv = createTestInvestment(
          quantity: 10.0,
          purchaseValue: 1500.0,
          currentPrice: 150.0,
        );

        expect(inv.getGainLoss(), 0.0);
      });
    });

    group('getGainLossPercent', () {
      test('calculates positive percentage', () {
        final inv = createTestInvestment(
          quantity: 10.0,
          purchaseValue: 1000.0,
          currentPrice: 150.0,
        );

        expect(inv.getGainLossPercent(), 50.0);
      });

      test('calculates negative percentage', () {
        final inv = createTestInvestment(
          quantity: 10.0,
          purchaseValue: 2000.0,
          currentPrice: 150.0,
        );

        expect(inv.getGainLossPercent(), -25.0);
      });

      test('returns 0 when purchaseValue is 0', () {
        final inv = createTestInvestment(
          quantity: 10.0,
          purchaseValue: 0.0,
          currentPrice: 150.0,
        );

        expect(inv.getGainLossPercent(), 0.0);
      });
    });

    group('isPositiveReturn', () {
      test('returns true for positive gain', () {
        final inv = createTestInvestment(
          quantity: 10.0,
          purchaseValue: 1000.0,
          currentPrice: 150.0,
        );

        expect(inv.isPositiveReturn(), true);
      });

      test('returns true for zero gain', () {
        final inv = createTestInvestment(
          quantity: 10.0,
          purchaseValue: 1500.0,
          currentPrice: 150.0,
        );

        expect(inv.isPositiveReturn(), true);
      });

      test('returns false for negative gain', () {
        final inv = createTestInvestment(
          quantity: 10.0,
          purchaseValue: 2000.0,
          currentPrice: 100.0,
        );

        expect(inv.isPositiveReturn(), false);
      });
    });

    group('getFormattedGainLoss', () {
      test('formats positive gain with + sign', () {
        final inv = createTestInvestment(
          quantity: 10.0,
          purchaseValue: 1000.0,
          currentPrice: 150.0,
        );

        expect(inv.getFormattedGainLoss(), '+50.00%');
      });

      test('formats negative loss with - sign', () {
        final inv = createTestInvestment(
          quantity: 10.0,
          purchaseValue: 2000.0,
          currentPrice: 150.0,
        );

        expect(inv.getFormattedGainLoss(), '-25.00%');
      });

      test('formats zero gain with + sign', () {
        final inv = createTestInvestment(
          quantity: 10.0,
          purchaseValue: 1500.0,
          currentPrice: 150.0,
        );

        expect(inv.getFormattedGainLoss(), '+0.00%');
      });
    });

    group('getCurrencySymbol', () {
      test('returns dong symbol for VND', () {
        final inv = createTestInvestment(currency: Currency.vnd);
        expect(inv.getCurrencySymbol(), '\u20ab');
      });

      test('returns dollar sign for USD', () {
        final inv = createTestInvestment(currency: Currency.usd);
        expect(inv.getCurrencySymbol(), '\$');
      });

      test('returns euro sign for EUR', () {
        final inv = createTestInvestment(currency: Currency.eur);
        expect(inv.getCurrencySymbol(), '\u20ac');
      });
    });

    group('Equatable', () {
      test('identical investments are equal', () {
        final inv1 = createTestInvestment();
        final inv2 = createTestInvestment();

        expect(inv1, inv2);
        expect(inv1.hashCode, inv2.hashCode);
      });

      test('investments with different ids are not equal', () {
        final inv1 = createTestInvestment(id: 'inv_001');
        final inv2 = createTestInvestment(id: 'inv_002');

        expect(inv1, isNot(inv2));
      });

      test('investments with different quantities are not equal', () {
        final inv1 = createTestInvestment(quantity: 10.0);
        final inv2 = createTestInvestment(quantity: 20.0);

        expect(inv1, isNot(inv2));
      });
    });
  });
}
