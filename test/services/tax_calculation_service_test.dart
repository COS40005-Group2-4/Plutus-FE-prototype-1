import 'package:flutter_test/flutter_test.dart';
import 'package:plutus_fe_prototype/services/tax_calculation_service.dart';

void main() {
  group('TaxCalculationService.calculateAnnualTax', () {
    test('income fully covered by personal deduction yields zero tax', () {
      // 11M VND/month personal deduction = 132M/year. 100M < 132M.
      final result = TaxCalculationService.calculateAnnualTax(
        annualIncome: 100000000,
      );

      expect(result['annualTax'], 0);
      expect(result['monthlyTaxableIncome'], 0);
      expect(result['effectiveRate'], 0);
      expect(result['netIncome'], 100000000);
    });

    test('zero income returns zero tax and zero effective rate', () {
      final result = TaxCalculationService.calculateAnnualTax(
        annualIncome: 0,
      );

      expect(result['annualTax'], 0);
      expect(result['effectiveRate'], 0);
      expect(result['netIncome'], 0);
    });

    test('first bracket: 13M/month income (taxable=2M) taxed at 5%', () {
      // 13M*12 = 156M annual. Monthly taxable = 13M - 11M = 2M.
      // Bracket 1: 2M * 0.05 - 0 = 100k monthly = 1.2M annual.
      final result = TaxCalculationService.calculateAnnualTax(
        annualIncome: 156000000,
      );

      expect(result['monthlyTax'], 100000);
      expect(result['annualTax'], 1200000);
      expect(result['monthlyTaxableIncome'], 2000000);
    });

    test('dependents reduce taxable income', () {
      // Personal 11M + 2 dependents * 4.4M = 19.8M monthly deduction.
      // Income 13M/month - 19.8M = negative, clamped to 0 → no tax.
      final result = TaxCalculationService.calculateAnnualTax(
        annualIncome: 156000000,
        numberOfDependents: 2,
      );

      expect(result['annualTax'], 0);
      expect(result['monthlyTaxableIncome'], 0);
    });

    test('additional deductions reduce taxable income', () {
      // 13M/month income, +12M annual additional deduction = 1M/month extra.
      // Deduction 11M + 1M = 12M. Taxable = 1M. Tax = 50k/month = 600k/year.
      final result = TaxCalculationService.calculateAnnualTax(
        annualIncome: 156000000,
        additionalDeductions: 12000000,
      );

      expect(result['monthlyTax'], 50000);
      expect(result['annualTax'], 600000);
    });

    test('top bracket applies for very high income', () {
      // 200M/month income → 200M-11M = 189M taxable monthly. Top bracket
      // (>80M): 189M * 0.35 - 9.85M = 66.15M - 9.85M = 56.3M monthly tax.
      final result = TaxCalculationService.calculateAnnualTax(
        annualIncome: 200000000 * 12,
      );

      expect(result['monthlyTax'], closeTo(56300000, 0.01));
      expect(result['annualTax'], closeTo(56300000 * 12, 0.01));
    });

    test('annualDeductions reflects personal + dependents', () {
      final result = TaxCalculationService.calculateAnnualTax(
        annualIncome: 500000000,
        numberOfDependents: 1,
      );

      // (11M + 4.4M) * 12 = 184.8M
      expect(result['annualDeductions'], 184800000);
    });

    test('effective rate stays under marginal rate', () {
      final result = TaxCalculationService.calculateAnnualTax(
        annualIncome: 156000000,
      );

      // Effective should be small fraction of total income.
      expect(result['effectiveRate'], lessThan(5));
      expect(result['effectiveRate'], greaterThan(0));
    });
  });

  group('TaxCalculationService.getTaxBracket', () {
    test('returns null for income at exactly 0 (not greater than min)', () {
      expect(TaxCalculationService.getTaxBracket(0), isNull);
    });

    test('returns first bracket for income just above 0', () {
      final bracket = TaxCalculationService.getTaxBracket(1000);
      expect(bracket, isNotNull);
      expect(bracket!['rate'], 0.05);
    });

    test('returns second bracket for 7M monthly income', () {
      final bracket = TaxCalculationService.getTaxBracket(7000000);
      expect(bracket!['rate'], 0.10);
    });

    test('returns top bracket for very high income', () {
      final bracket = TaxCalculationService.getTaxBracket(100000000);
      expect(bracket!['rate'], 0.35);
    });
  });
}
