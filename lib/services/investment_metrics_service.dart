import 'dart:math' as math;

/// A dated cash flow from the investor's perspective:
/// negative = money out (purchase), positive = money in (sale or terminal value).
class CashFlow {
  final DateTime date;
  final double amount;

  const CashFlow(this.date, this.amount);
}

/// Result of an XIRR computation.
class XirrResult {
  /// Annualised internal rate of return as a decimal (0.12 == 12%).
  /// Null when the algorithm could not converge or inputs were degenerate.
  final double? rate;
  final bool converged;

  const XirrResult({this.rate, required this.converged});
}

/// Pure-function metrics for investment returns.
///
/// All methods are side-effect-free so they are trivially unit-testable
/// and can be reused from any layer (provider, FFI fallback, reports).
class InvestmentMetricsService {
  /// Minimum holding period before annualised IRR is meaningful.
  /// Below this, callers should display absolute ROI instead — annualising
  /// a sub-1-year return is misleading (Kubera convention).
  static const Duration minIrrHoldingPeriod = Duration(days: 365);

  /// Absolute ROI as a decimal: (currentValue - costBasis) / costBasis.
  /// Returns 0 when costBasis is non-positive.
  static double computeRoi({
    required double currentValue,
    required double costBasis,
  }) {
    if (costBasis <= 0) return 0;
    return (currentValue - costBasis) / costBasis;
  }

  /// True if the holding period is long enough that an annualised IRR is
  /// meaningful. Use this to decide whether to surface XIRR or fall back
  /// to absolute ROI in the UI.
  static bool isIrrMeaningful({
    required DateTime firstCashFlowDate,
    required DateTime asOf,
  }) {
    return asOf.difference(firstCashFlowDate) >= minIrrHoldingPeriod;
  }

  /// Compute XIRR (annualised money-weighted return for irregularly-dated
  /// cash flows) using Newton-Raphson with a bisection fallback.
  ///
  /// Convention: at least one negative and one positive cash flow are required.
  /// Returns [XirrResult] with [XirrResult.rate] = null and converged = false
  /// for degenerate or non-convergent inputs.
  static XirrResult computeXirr(
    List<CashFlow> flows, {
    double guess = 0.1,
    int maxIterations = 100,
    double tolerance = 1e-7,
  }) {
    if (flows.length < 2) {
      return const XirrResult(rate: null, converged: false);
    }
    final hasPositive = flows.any((f) => f.amount > 0);
    final hasNegative = flows.any((f) => f.amount < 0);
    if (!hasPositive || !hasNegative) {
      return const XirrResult(rate: null, converged: false);
    }

    // Anchor all flows to the earliest date so exponents are well-conditioned.
    final sorted = List<CashFlow>.from(flows)
      ..sort((a, b) => a.date.compareTo(b.date));
    final anchor = sorted.first.date;

    double npv(double rate) {
      double sum = 0;
      for (final cf in sorted) {
        final years = cf.date.difference(anchor).inDays / 365.25;
        // Guard the base — rate <= -1 produces NaN/inf for non-zero years.
        final base = (1 + rate);
        if (base <= 0) return double.nan;
        sum += cf.amount / math.pow(base, years);
      }
      return sum;
    }

    double dnpv(double rate) {
      double sum = 0;
      for (final cf in sorted) {
        final years = cf.date.difference(anchor).inDays / 365.25;
        final base = (1 + rate);
        if (base <= 0) return double.nan;
        sum -= years * cf.amount / math.pow(base, years + 1);
      }
      return sum;
    }

    // Newton-Raphson.
    double rate = guess;
    for (int i = 0; i < maxIterations; i++) {
      final f = npv(rate);
      if (f.isNaN || f.isInfinite) break;
      if (f.abs() < tolerance) {
        return XirrResult(rate: rate, converged: true);
      }
      final df = dnpv(rate);
      if (df.isNaN || df.isInfinite || df.abs() < 1e-12) break;
      final next = rate - f / df;
      if ((next - rate).abs() < tolerance) {
        return XirrResult(rate: next, converged: true);
      }
      // Keep the rate sane; XIRR can otherwise overshoot to absurd values.
      rate = next.clamp(-0.999, 1e6);
    }

    // Bisection fallback over a generous bracket.
    double lo = -0.9999;
    double hi = 10.0;
    double fLo = npv(lo);
    double fHi = npv(hi);
    if (fLo.isNaN || fHi.isNaN || fLo * fHi > 0) {
      return const XirrResult(rate: null, converged: false);
    }
    for (int i = 0; i < 200; i++) {
      final mid = (lo + hi) / 2;
      final fMid = npv(mid);
      if (fMid.isNaN) {
        return const XirrResult(rate: null, converged: false);
      }
      if (fMid.abs() < tolerance || (hi - lo) / 2 < tolerance) {
        return XirrResult(rate: mid, converged: true);
      }
      if (fMid * fLo < 0) {
        hi = mid;
        fHi = fMid;
      } else {
        lo = mid;
        fLo = fMid;
      }
    }
    return const XirrResult(rate: null, converged: false);
  }
}
