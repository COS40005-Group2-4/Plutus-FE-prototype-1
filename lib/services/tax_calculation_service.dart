import 'dart:math';

/// Vietnamese Tax calculation
class TaxCalculationService {
  static const List<Map<String, dynamic>> _taxBrackets = [
    {'min': 0, 'max': 5000000, 'rate': 0.05, 'deduction': 0},
    {'min': 5000000, 'max': 10000000, 'rate': 0.10, 'deduction': 250000},
    {'min': 10000000, 'max': 18000000, 'rate': 0.15, 'deduction': 750000},
    {'min': 18000000, 'max': 32000000, 'rate': 0.20, 'deduction': 1650000},
    {'min': 32000000, 'max': 52000000, 'rate': 0.25, 'deduction': 3250000},
    {'min': 52000000, 'max': 80000000, 'rate': 0.30, 'deduction': 5850000},
    {'min': 80000000, 'max': double.infinity, 'rate': 0.35, 'deduction': 9850000},
  ];

  // Standard deductions (VND per month)
  static const double _personalDeduction = 11000000; // 11 million VND/month
  static const double _dependentDeduction = 4400000; // 4.4 million VND/month per dependent


  static Map<String, double> calculateAnnualTax({
    required double annualIncome,
    int numberOfDependents = 0,
    double additionalDeductions = 0,
  }) {
    // Convert annual to monthly for calculation
    final monthlyIncome = annualIncome / 12;
    
    // Calculate total monthly deductions
    final totalMonthlyDeduction = _personalDeduction + 
                                  (numberOfDependents * _dependentDeduction) +
                                  (additionalDeductions / 12);
    
    // Calculate taxable income
    final monthlyTaxableIncome = max(0.0, monthlyIncome - totalMonthlyDeduction);
    
    // Calculate monthly tax using progressive brackets
    double monthlyTax = 0;
    
    for (final bracket in _taxBrackets) {
      final min = (bracket['min'] as num).toDouble();
      final max = (bracket['max'] as num).toDouble();
      final rate = (bracket['rate'] as num).toDouble();
      final deduction = (bracket['deduction'] as num).toDouble();
      
      if (monthlyTaxableIncome > min) {
        if (monthlyTaxableIncome <= max) {
          // Income falls in this bracket
          monthlyTax = (monthlyTaxableIncome * rate) - deduction;
          break;
        }
      }
    }
    
    // Calculate annual values
    final annualTax = monthlyTax * 12;
    final annualDeductions = totalMonthlyDeduction * 12;
    final annualTaxableIncome = monthlyTaxableIncome * 12;
    final effectiveRate = annualIncome > 0 ? (annualTax / annualIncome) * 100 : 0;
    
    return {
      'annualIncome': annualIncome,
      'annualDeductions': annualDeductions,
      'annualTaxableIncome': annualTaxableIncome.toDouble(),
      'annualTax': annualTax,
      'netIncome': annualIncome - annualTax,
      'effectiveRate': effectiveRate.toDouble(),
      'monthlyTax': monthlyTax,
      'monthlyIncome': monthlyIncome,
      'monthlyTaxableIncome': monthlyTaxableIncome.toDouble(),
    };
  }

  /// Get tax bracket information for a given monthly income
  static Map<String, dynamic>? getTaxBracket(double monthlyIncome) {
    for (final bracket in _taxBrackets) {
      final min = (bracket['min'] as num).toDouble();
      final max = (bracket['max'] as num).toDouble();
      
      if (monthlyIncome > min && monthlyIncome <= max) {
        return bracket;
      }
    }
    return null;
  }
}