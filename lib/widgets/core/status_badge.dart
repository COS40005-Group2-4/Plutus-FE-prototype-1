import 'package:flutter/material.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/plutus_tokens.dart';

/// The four status families. Rendering always uses the full quartet
/// from [PlutusTokens] — never an ad-hoc red/green.
enum StatusKind { success, warning, info, error }

/// Canonical status indicator (spec §5): pill + filled dot + label,
/// colored by the matching [StatusColors] quartet.
class StatusBadge extends StatelessWidget {
  final StatusKind kind;
  final String label;

  const StatusBadge({super.key, required this.kind, required this.label});

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    final StatusColors s = switch (kind) {
      StatusKind.success => t.success,
      StatusKind.warning => t.warning,
      StatusKind.info => t.info,
      StatusKind.error => t.error,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.componentMd,
        vertical: AppSpacing.componentXs,
      ),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: AppRadius.borderPill,
        border: Border.all(color: s.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: s.dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.componentSm),
          Text(
            label,
            style: AppTextStyles.captionStyle.copyWith(color: s.text),
          ),
        ],
      ),
    );
  }
}
