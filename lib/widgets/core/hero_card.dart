import 'package:flutter/material.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/plutus_tokens.dart';

/// The one intentionally rich surface in the app (spec §5): flat navy,
/// 1px gold hairline, figure set in the classical serif. Used for the
/// dashboard net-worth hero; [value] arrives pre-formatted and localized.
class HeroCard extends StatelessWidget {
  final String label;
  final String value;
  final Widget? footer;

  const HeroCard({
    super.key,
    required this.label,
    required this.value,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.componentXl),
      decoration: BoxDecoration(
        color: t.heroSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: t.heroBorder),
        boxShadow: t.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: AppTextStyles.overlineStyle.copyWith(color: t.heroLabel),
          ),
          const SizedBox(height: AppSpacing.componentSm),
          Text(
            value,
            style: AppTextStyles.heroSerifStyle.copyWith(color: t.heroText),
          ),
          if (footer != null) ...<Widget>[
            const SizedBox(height: AppSpacing.componentMd),
            footer!,
          ],
        ],
      ),
    );
  }
}
