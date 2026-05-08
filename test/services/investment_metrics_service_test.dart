import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/services/investment_metrics_service.dart';

void main() {
  group('computeRoi', () {
    test('returns positive ROI when value exceeds basis', () {
      expect(
        InvestmentMetricsService.computeRoi(currentValue: 1500, costBasis: 1000),
        closeTo(0.5, 1e-9),
      );
    });

    test('returns negative ROI when value below basis', () {
      expect(
        InvestmentMetricsService.computeRoi(currentValue: 750, costBasis: 1000),
        closeTo(-0.25, 1e-9),
      );
    });

    test('returns 0 when cost basis is zero or negative', () {
      expect(
        InvestmentMetricsService.computeRoi(currentValue: 100, costBasis: 0),
        0,
      );
      expect(
        InvestmentMetricsService.computeRoi(currentValue: 100, costBasis: -50),
        0,
      );
    });
  });

  group('isIrrMeaningful', () {
    test('false when held under 365 days', () {
      final start = DateTime(2024, 1, 1);
      final asOf = start.add(const Duration(days: 364));
      expect(
        InvestmentMetricsService.isIrrMeaningful(
          firstCashFlowDate: start,
          asOf: asOf,
        ),
        isFalse,
      );
    });

    test('true at exactly 365 days', () {
      final start = DateTime(2024, 1, 1);
      final asOf = start.add(const Duration(days: 365));
      expect(
        InvestmentMetricsService.isIrrMeaningful(
          firstCashFlowDate: start,
          asOf: asOf,
        ),
        isTrue,
      );
    });
  });

  group('computeXirr', () {
    test('returns ~10% for a flat 1-year doubling-back-to-flat scenario', () {
      // -1000 today, +1100 in one year => 10% annualised
      final start = DateTime(2024, 1, 1);
      final flows = [
        CashFlow(start, -1000),
        CashFlow(start.add(const Duration(days: 365)), 1100),
      ];
      final result = InvestmentMetricsService.computeXirr(flows);
      expect(result.converged, isTrue);
      expect(result.rate, closeTo(0.10, 1e-3));
    });

    test('NPV is zero at the computed rate for irregular flows', () {
      // Self-consistency: if XIRR converges, NPV at that rate should be ~0.
      final flows = [
        CashFlow(DateTime(2020, 1, 1), -10000),
        CashFlow(DateTime(2020, 6, 1), -2500),
        CashFlow(DateTime(2021, 1, 15), 4000),
        CashFlow(DateTime(2022, 1, 1), 12000),
      ];
      final result = InvestmentMetricsService.computeXirr(flows);
      expect(result.converged, isTrue);
      expect(result.rate, isNotNull);

      final r = result.rate!;
      final anchor = flows.first.date;
      double npv = 0;
      for (final cf in flows) {
        final years = cf.date.difference(anchor).inDays / 365.25;
        npv += cf.amount / math.pow(1 + r, years);
      }
      expect(npv.abs(), lessThan(1e-3));
      // Sanity bracket: ~13–18% for these flows over ~2 years.
      expect(r, greaterThan(0.10));
      expect(r, lessThan(0.25));
    });

    test('returns negative rate for losing investment', () {
      final flows = [
        CashFlow(DateTime(2024, 1, 1), -1000),
        CashFlow(DateTime(2025, 1, 1), 800),
      ];
      final result = InvestmentMetricsService.computeXirr(flows);
      expect(result.converged, isTrue);
      expect(result.rate!, lessThan(0));
      expect(result.rate!, closeTo(-0.20, 1e-3));
    });

    test('does not converge when all flows have the same sign', () {
      final flows = [
        CashFlow(DateTime(2024, 1, 1), -1000),
        CashFlow(DateTime(2024, 6, 1), -500),
      ];
      final result = InvestmentMetricsService.computeXirr(flows);
      expect(result.converged, isFalse);
      expect(result.rate, isNull);
    });

    test('does not converge with fewer than two flows', () {
      final result = InvestmentMetricsService.computeXirr([
        CashFlow(DateTime(2024, 1, 1), -1000),
      ]);
      expect(result.converged, isFalse);
      expect(result.rate, isNull);
    });
  });
}
