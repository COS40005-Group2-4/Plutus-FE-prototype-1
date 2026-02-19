import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/models/investment_model.dart';

void main() {
  group('ValueHistoryModel', () {
    test('fromJson creates valid model with all fields', () {
      final json = {
        'date': 1704067200, // Unix timestamp
        'from_currency': 'NVDA',
        'to_currency': 'USD',
        'rate': 420.50,
      };

      final model = ValueHistoryModel.fromJson(json);

      expect(model.fromCurrency, 'NVDA');
      expect(model.toCurrency, 'USD');
      expect(model.rate, 420.50);
      expect(model.date.year, 2024);
    });

    test('fromJson throws on missing required fields', () {
      final json = {
        'date': 1704067200,
        'from_currency': 'NVDA',
        // Missing to_currency and rate
      };

      expect(
        () => ValueHistoryModel.fromJson(json),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromJson throws on future date', () {
      final futureDate =
          DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch ~/
              1000;
      final json = {
        'date': futureDate,
        'from_currency': 'NVDA',
        'to_currency': 'USD',
        'rate': 420.50,
      };

      expect(
        () => ValueHistoryModel.fromJson(json),
        throwsA(predicate((e) =>
            e is ArgumentError &&
            e.message.toString().contains('Date cannot be in the future'))),
      );
    });

    test('fromJson throws on zero exchange rate', () {
      final json = {
        'date': 1704067200,
        'from_currency': 'NVDA',
        'to_currency': 'USD',
        'rate': 0,
      };

      expect(
        () => ValueHistoryModel.fromJson(json),
        throwsA(predicate((e) =>
            e is ArgumentError &&
            e.message.toString().contains('Exchange rate must be a positive'))),
      );
    });

    test('fromJson throws on negative exchange rate', () {
      final json = {
        'date': 1704067200,
        'from_currency': 'NVDA',
        'to_currency': 'USD',
        'rate': -100.0,
      };

      expect(
        () => ValueHistoryModel.fromJson(json),
        throwsA(predicate((e) =>
            e is ArgumentError &&
            e.message.toString().contains('Exchange rate must be a positive'))),
      );
    });

    test('toJson serializes correctly', () {
      final model = ValueHistoryModel(
        date: DateTime.fromMillisecondsSinceEpoch(1704067200 * 1000),
        fromCurrency: 'NVDA',
        toCurrency: 'USD',
        rate: 420.50,
      );

      final json = model.toJson();

      expect(json['date'], 1704067200);
      expect(json['from_currency'], 'NVDA');
      expect(json['to_currency'], 'USD');
      expect(json['rate'], 420.50);
    });
  });

  group('InvestmentTransactionModel', () {
    test('fromJson creates valid model', () {
      final json = {
        'date': 1704067200,
        'amount': -2100.00,
        'type': 'buy',
        'quantity': 5.0,
      };

      final model = InvestmentTransactionModel.fromJson(json);

      expect(model.amount, -2100.00);
      expect(model.type, 'buy');
      expect(model.quantity, 5.0);
    });

    test('fromJson throws on missing required fields', () {
      final json = {
        'date': 1704067200,
        'amount': -2100.00,
        // Missing type and quantity
      };

      expect(
        () => InvestmentTransactionModel.fromJson(json),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toJson serializes correctly', () {
      final model = InvestmentTransactionModel(
        date: DateTime.fromMillisecondsSinceEpoch(1704067200 * 1000),
        amount: -2100.00,
        type: 'buy',
        quantity: 5.0,
      );

      final json = model.toJson();

      expect(json['date'], 1704067200);
      expect(json['amount'], -2100.00);
      expect(json['type'], 'buy');
      expect(json['quantity'], 5.0);
    });
  });

  group('InvestmentModel', () {
    test('fromJson creates valid model with all required fields', () {
      final json = {
        'commodity': 'NVDA',
        'name': 'NVIDIA Corporation',
        'quantity': 10.5,
        'current_value': 5250.00,
        'cost_basis': 4200.00,
        'gain_loss_percent': 25.0,
        'tracking_type': 'api',
      };

      final model = InvestmentModel.fromJson(json);

      expect(model.commodity, 'NVDA');
      expect(model.name, 'NVIDIA Corporation');
      expect(model.quantity, 10.5);
      expect(model.currentValue, 5250.00);
      expect(model.costBasis, 4200.00);
      expect(model.gainLossPercent, 25.0);
      expect(model.trackingType, TrackingType.api);
    });

    test('fromJson creates model with manual tracking type', () {
      final json = {
        'commodity': 'Property_A',
        'name': 'Real Estate Property',
        'quantity': 1.0,
        'current_value': 500000.00,
        'cost_basis': 450000.00,
        'gain_loss_percent': 11.11,
        'tracking_type': 'manual',
      };

      final model = InvestmentModel.fromJson(json);

      expect(model.trackingType, TrackingType.manual);
    });

    test('fromJson throws on missing required fields', () {
      final json = {
        'commodity': 'NVDA',
        'name': 'NVIDIA Corporation',
        // Missing other required fields
      };

      expect(
        () => InvestmentModel.fromJson(json),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromJson throws on invalid commodity symbol with special characters',
        () {
      final json = {
        'commodity': 'NV@DA!',
        'name': 'NVIDIA Corporation',
        'quantity': 10.5,
        'current_value': 5250.00,
        'cost_basis': 4200.00,
        'gain_loss_percent': 25.0,
        'tracking_type': 'api',
      };

      expect(
        () => InvestmentModel.fromJson(json),
        throwsA(predicate((e) =>
            e is ArgumentError &&
            e.message
                .toString()
                .contains('Commodity symbol can only contain'))),
      );
    });

    test('fromJson throws on invalid commodity symbol with spaces', () {
      final json = {
        'commodity': 'NV DA',
        'name': 'NVIDIA Corporation',
        'quantity': 10.5,
        'current_value': 5250.00,
        'cost_basis': 4200.00,
        'gain_loss_percent': 25.0,
        'tracking_type': 'api',
      };

      expect(
        () => InvestmentModel.fromJson(json),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromJson accepts valid commodity symbol with underscores', () {
      final json = {
        'commodity': 'Property_A_123',
        'name': 'Real Estate',
        'quantity': 1.0,
        'current_value': 500000.00,
        'cost_basis': 450000.00,
        'gain_loss_percent': 11.11,
        'tracking_type': 'manual',
      };

      final model = InvestmentModel.fromJson(json);

      expect(model.commodity, 'Property_A_123');
    });

    test('fromJson parses transactions when present', () {
      final json = {
        'commodity': 'NVDA',
        'name': 'NVIDIA Corporation',
        'quantity': 10.5,
        'current_value': 5250.00,
        'cost_basis': 4200.00,
        'gain_loss_percent': 25.0,
        'tracking_type': 'api',
        'transactions': [
          {
            'date': 1704067200,
            'amount': -2100.00,
            'type': 'buy',
            'quantity': 5.0,
          }
        ],
      };

      final model = InvestmentModel.fromJson(json);

      expect(model.transactions, isNotNull);
      expect(model.transactions!.length, 1);
      expect(model.transactions![0].amount, -2100.00);
    });

    test('fromJson parses value history when present', () {
      final json = {
        'commodity': 'NVDA',
        'name': 'NVIDIA Corporation',
        'quantity': 10.5,
        'current_value': 5250.00,
        'cost_basis': 4200.00,
        'gain_loss_percent': 25.0,
        'tracking_type': 'api',
        'value_history': [
          {
            'date': 1704067200,
            'from_currency': 'NVDA',
            'to_currency': 'USD',
            'rate': 420.00,
          }
        ],
      };

      final model = InvestmentModel.fromJson(json);

      expect(model.valueHistory, isNotNull);
      expect(model.valueHistory!.length, 1);
      expect(model.valueHistory![0].rate, 420.00);
    });

    test('getTotalValue returns current value', () {
      final model = InvestmentModel(
        commodity: 'NVDA',
        name: 'NVIDIA Corporation',
        quantity: 10.5,
        currentValue: 5250.00,
        costBasis: 4200.00,
        gainLossPercent: 25.0,
        trackingType: TrackingType.api,
      );

      expect(model.getTotalValue(), 5250.00);
    });

    test('getUnrealizedGainLoss calculates correctly for positive gain', () {
      final model = InvestmentModel(
        commodity: 'NVDA',
        name: 'NVIDIA Corporation',
        quantity: 10.5,
        currentValue: 5250.00,
        costBasis: 4200.00,
        gainLossPercent: 25.0,
        trackingType: TrackingType.api,
      );

      expect(model.getUnrealizedGainLoss(), 1050.00);
    });

    test('getUnrealizedGainLoss calculates correctly for negative loss', () {
      final model = InvestmentModel(
        commodity: 'NVDA',
        name: 'NVIDIA Corporation',
        quantity: 10.5,
        currentValue: 3500.00,
        costBasis: 4200.00,
        gainLossPercent: -16.67,
        trackingType: TrackingType.api,
      );

      expect(model.getUnrealizedGainLoss(), -700.00);
    });

    test('isPositiveReturn returns true for positive gain', () {
      final model = InvestmentModel(
        commodity: 'NVDA',
        name: 'NVIDIA Corporation',
        quantity: 10.5,
        currentValue: 5250.00,
        costBasis: 4200.00,
        gainLossPercent: 25.0,
        trackingType: TrackingType.api,
      );

      expect(model.isPositiveReturn(), true);
    });

    test('isPositiveReturn returns false for negative loss', () {
      final model = InvestmentModel(
        commodity: 'NVDA',
        name: 'NVIDIA Corporation',
        quantity: 10.5,
        currentValue: 3500.00,
        costBasis: 4200.00,
        gainLossPercent: -16.67,
        trackingType: TrackingType.api,
      );

      expect(model.isPositiveReturn(), false);
    });

    test('isPositiveReturn returns false for zero gain', () {
      final model = InvestmentModel(
        commodity: 'NVDA',
        name: 'NVIDIA Corporation',
        quantity: 10.5,
        currentValue: 4200.00,
        costBasis: 4200.00,
        gainLossPercent: 0.0,
        trackingType: TrackingType.api,
      );

      expect(model.isPositiveReturn(), false);
    });

    test('getFormattedGainLoss formats positive percentage with + sign', () {
      final model = InvestmentModel(
        commodity: 'NVDA',
        name: 'NVIDIA Corporation',
        quantity: 10.5,
        currentValue: 5250.00,
        costBasis: 4200.00,
        gainLossPercent: 25.0,
        trackingType: TrackingType.api,
      );

      expect(model.getFormattedGainLoss(), '+25.00%');
    });

    test('getFormattedGainLoss formats negative percentage with - sign', () {
      final model = InvestmentModel(
        commodity: 'NVDA',
        name: 'NVIDIA Corporation',
        quantity: 10.5,
        currentValue: 3500.00,
        costBasis: 4200.00,
        gainLossPercent: -16.67,
        trackingType: TrackingType.api,
      );

      expect(model.getFormattedGainLoss(), '-16.67%');
    });

    test('getFormattedGainLoss formats zero with + sign', () {
      final model = InvestmentModel(
        commodity: 'NVDA',
        name: 'NVIDIA Corporation',
        quantity: 10.5,
        currentValue: 4200.00,
        costBasis: 4200.00,
        gainLossPercent: 0.0,
        trackingType: TrackingType.api,
      );

      expect(model.getFormattedGainLoss(), '+0.00%');
    });

    test('isValidCommoditySymbol validates alphanumeric symbols', () {
      expect(InvestmentModel.isValidCommoditySymbol('NVDA'), true);
      expect(InvestmentModel.isValidCommoditySymbol('TSLA'), true);
      expect(InvestmentModel.isValidCommoditySymbol('Property_A'), true);
      expect(InvestmentModel.isValidCommoditySymbol('Asset_123'), true);
    });

    test('isValidCommoditySymbol rejects invalid symbols', () {
      expect(InvestmentModel.isValidCommoditySymbol('NV@DA'), false);
      expect(InvestmentModel.isValidCommoditySymbol('NV DA'), false);
      expect(InvestmentModel.isValidCommoditySymbol('NV-DA'), false);
      expect(InvestmentModel.isValidCommoditySymbol('NV.DA'), false);
      expect(InvestmentModel.isValidCommoditySymbol(''), false);
    });

    test('isValidExchangeRate validates positive rates', () {
      expect(InvestmentModel.isValidExchangeRate(420.50), true);
      expect(InvestmentModel.isValidExchangeRate(0.01), true);
      expect(InvestmentModel.isValidExchangeRate(1000000.0), true);
    });

    test('isValidExchangeRate rejects zero and negative rates', () {
      expect(InvestmentModel.isValidExchangeRate(0), false);
      expect(InvestmentModel.isValidExchangeRate(-100.0), false);
      expect(InvestmentModel.isValidExchangeRate(-0.01), false);
    });

    test('isValidDate validates past and present dates', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      final presentDate = DateTime.now();

      expect(InvestmentModel.isValidDate(pastDate), true);
      expect(InvestmentModel.isValidDate(presentDate), true);
    });

    test('isValidDate rejects future dates', () {
      final futureDate = DateTime.now().add(const Duration(days: 1));

      expect(InvestmentModel.isValidDate(futureDate), false);
    });

    test('toJson serializes complete model correctly', () {
      final model = InvestmentModel(
        commodity: 'NVDA',
        name: 'NVIDIA Corporation',
        quantity: 10.5,
        currentValue: 5250.00,
        costBasis: 4200.00,
        gainLossPercent: 25.0,
        trackingType: TrackingType.api,
      );

      final json = model.toJson();

      expect(json['commodity'], 'NVDA');
      expect(json['name'], 'NVIDIA Corporation');
      expect(json['quantity'], 10.5);
      expect(json['current_value'], 5250.00);
      expect(json['cost_basis'], 4200.00);
      expect(json['gain_loss_percent'], 25.0);
      expect(json['tracking_type'], 'api');
    });

    test('JSON round-trip preserves all data', () {
      final original = InvestmentModel(
        commodity: 'NVDA',
        name: 'NVIDIA Corporation',
        quantity: 10.5,
        currentValue: 5250.00,
        costBasis: 4200.00,
        gainLossPercent: 25.0,
        trackingType: TrackingType.api,
      );

      final json = original.toJson();
      final restored = InvestmentModel.fromJson(json);

      expect(restored.commodity, original.commodity);
      expect(restored.name, original.name);
      expect(restored.quantity, original.quantity);
      expect(restored.currentValue, original.currentValue);
      expect(restored.costBasis, original.costBasis);
      expect(restored.gainLossPercent, original.gainLossPercent);
      expect(restored.trackingType, original.trackingType);
    });
  });
}
