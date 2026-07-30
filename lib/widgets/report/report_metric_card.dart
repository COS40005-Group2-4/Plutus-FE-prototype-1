import 'package:flutter/material.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/plutus_tokens.dart';

class ReportMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? changeText;
  final Color? changeColor;
  final Color? accentColor;

  const ReportMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.changeText,
    this.changeColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    const PlutusTokens doc = PlutusTokens.dark;
    final Color accent = accentColor ?? doc.text;
    return Container(
      decoration: BoxDecoration(
        color: doc.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: doc.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: doc.textMuted,
              letterSpacing: 1,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          if (changeText != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              changeText!,
              style: TextStyle(
                fontSize: 11,
                color: changeColor ?? doc.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
