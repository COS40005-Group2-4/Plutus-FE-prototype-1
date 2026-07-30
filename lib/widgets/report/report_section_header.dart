import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/plutus_tokens.dart';
import '../core/meander_divider.dart';

class ReportSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;

  const ReportSectionHeader({
    super.key,
    required this.title,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const PlutusTokens doc = PlutusTokens.dark;
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xl,
        bottom: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const MeanderDivider(),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 20, color: doc.textMuted),
                const SizedBox(width: AppSpacing.componentSm),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title.toUpperCase(),
                    style: AppTextStyles.overlineStyle.copyWith(color: doc.textMuted),
                  ),
                  Text(
                    title,
                    style: AppTextStyles.titleStyle.copyWith(color: doc.text),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
