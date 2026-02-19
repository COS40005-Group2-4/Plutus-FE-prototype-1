import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/services/investment_service.dart';
import 'package:plutus_fe_prototype/models/investment_model.dart';

void main() {
  group('InvestmentService', () {
    late InvestmentService service;

    setUp(() {
      service = InvestmentService();
    });

    group('getTotalPortfolioValue', () {
      test('returns 0 for empty investment list', () {
        final result = service.getTotalPortfolioValue([]);
        expect(result, 0.0);
      });

      test('calculates total value for single investment', () {
        final investments = [
          InvestmentModel(
            commodity: 'NVDA',
            name: 'NVIDIA Corporation',
            quantity: 10.5,
            currentValue: 5250.00,
            costBasis: 4200.00,
            gainLossPercent: 25.0,
            trackingType: TrackingType.api,
          ),
        ];

        final result = service.getTotalPortfolioValue(investments);
        expect(result, 5250.00);
      });

      test('calculates total value for multiple investments', () {
        final investments = [
          InvestmentModel(
            commodity: 'NVDA',
            name: 'NVIDIA Corporation',
            quantity: 10.5,
            currentValue: 5250.00,
            costBasis: 4200.00,
            gainLossPercent: 25.0,
            trackingType: TrackingType.api,
          ),
          InvestmentModel(
            commodity: 'TSLA',
            name: 'Tesla Inc',
            quantity: 20.0,
            currentValue: 4000.00,
            costBasis: 3500.00,
            gainLossPercent: 14.29,
            trackingType: TrackingType.api,
          ),
          InvestmentModel(
            commodity: 'Property_A',
            name: 'Real Estate',
            quantity: 1.0,
            currentValue: 500000.00,
            costBasis: 450000.00,
            gainLossPercent: 11.11,
            trackingType: TrackingType.manual,
          ),
        ];

        final result = service.getTotalPortfolioValue(investments);
        expect(result, 509250.00);
      });
    });

    group('getTotalGainLoss', () {
      test('returns 0 for empty investment list', () {
        final result = service.getTotalGainLoss([]);
        expect(result, 0.0);
      });

      test('returns 0 when total cost basis is 0', () {
        final investments = [
          InvestmentModel(
            commodity: 'FREE',
            name: 'Free Asset',
            quantity: 1.0,
            currentValue: 1000.00,
            costBasis: 0.0,
            gainLossPercent: 0.0,
            trackingType: TrackingType.manual,
          ),
        ];

        final result = service.getTotalGainLoss(investments);
        expect(result, 0.0);
      });

      test('returns 0 when total cost basis is negative', () {
        final investments = [
          InvestmentModel(
            commodity: 'WEIRD',
            name: 'Weird Asset',
            quantity: 1.0,
            currentValue: 1000.00,
            costBasis: -100.0,
            gainLossPercent: 0.0,
            trackingType: TrackingType.manual,
          ),
        ];

        final result = service.getTotalGainLoss(investments);
        expect(result, 0.0);
      });

      test('calculates positive gain percentage correctly', () {
        final investments = [
          InvestmentModel(
            commodity: 'NVDA',
            name: 'NVIDIA Corporation',
            quantity: 10.5,
            currentValue: 5250.00,
            costBasis: 4200.00,
            gainLossPercent: 25.0,
            trackingType: TrackingType.api,
          ),
        ];

        final result = service.getTotalGainLoss(investments);
        expect(result, 25.0);
      });

      test('calculates negative loss percentage correctly', () {
        final investments = [
          InvestmentModel(
            commodity: 'NVDA',
            name: 'NVIDIA Corporation',
            quantity: 10.5,
            currentValue: 3500.00,
            costBasis: 4200.00,
            gainLossPercent: -16.67,
            trackingType: TrackingType.api,
          ),
        ];

        final result = service.getTotalGainLoss(investments);
        expect(result, closeTo(-16.67, 0.01));
      });

      test('calculates portfolio gain/loss across multiple investments', () {
        final investments = [
          InvestmentModel(
            commodity: 'NVDA',
            name: 'NVIDIA Corporation',
            quantity: 10.5,
            currentValue: 5250.00,
            costBasis: 4200.00,
            gainLossPercent: 25.0,
            trackingType: TrackingType.api,
          ),
          InvestmentModel(
            commodity: 'TSLA',
            name: 'Tesla Inc',
            quantity: 20.0,
            currentValue: 4000.00,
            costBasis: 3500.00,
            gainLossPercent: 14.29,
            trackingType: TrackingType.api,
          ),
        ];

        // Total value: 5250 + 4000 = 9250
        // Total cost: 4200 + 3500 = 7700
        // Gain: (9250 - 7700) / 7700 * 100 = 20.13%
        final result = service.getTotalGainLoss(investments);
        expect(result, closeTo(20.13, 0.01));
      });

      test('calculates zero gain when value equals cost', () {
        final investments = [
          InvestmentModel(
            commodity: 'STABLE',
            name: 'Stable Asset',
            quantity: 1.0,
            currentValue: 1000.00,
            costBasis: 1000.00,
            gainLossPercent: 0.0,
            trackingType: TrackingType.manual,
          ),
        ];

        final result = service.getTotalGainLoss(investments);
        expect(result, 0.0);
      });
    });

    group('clearCache', () {
      test('clears cached data', () {
        // This test verifies that clearCache doesn't throw
        // Actual cache behavior is tested through integration tests
        expect(() => service.clearCache(), returnsNormally);
      });
    });

    group('getInvestmentDetail', () {
      test('throws ArgumentError for empty commodity', () async {
        expect(
          () => service.getInvestmentDetail(''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws Exception when backend is unavailable', () async {
        // Backend FFI service will throw when not initialized
        expect(
          () => service.getInvestmentDetail('NVDA'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getInvestmentList', () {
      test('returns investment list from backend', () async {
        // Backend should return mock investment data
        final investments = await service.getInvestmentList();
        
        expect(investments, isNotEmpty);
        expect(investments.length, greaterThanOrEqualTo(1));
        expect(investments.first.commodity, isNotEmpty);
      });
    });
  });
}
