import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/plutus_tokens.dart';

/// Gain/loss indicator (spec §3.4): financial deltas keep the green/red
/// convention via the status quartets — gold is never an up/down signal.
/// An exact-zero delta renders as a signless neutral figure.
class MetricDelta extends StatelessWidget {
  final double percent;
  final int decimals;

  const MetricDelta({super.key, required this.percent, this.decimals = 1});

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    final String magnitude = '${percent.abs().toStringAsFixed(decimals)}%';
    final bool isZero = percent == 0;
    final bool rising = percent > 0;
    final Color color = isZero
        ? t.textSecondary
        : (rising ? t.success.text : t.error.text);
    final String text =
        isZero ? magnitude : '${rising ? '▲' : '▼'} $magnitude';

    return Text(
      text,
      style: AppTextStyles.numericStyle.copyWith(
        color: color,
        fontSize: AppTextStyles.label,
      ),
    );
  }
}
