import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/plutus_tokens.dart';

/// Calm empty state (spec §5): muted icon, title, optional caption, and
/// at most one gold CTA. Copy is passed in by the caller (localized at
/// the call-site via AppLocalizations).
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.layoutMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 40, color: t.textMuted),
            const SizedBox(height: AppSpacing.componentLg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleStyle.copyWith(color: t.text),
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: AppSpacing.componentSm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyStyle.copyWith(color: t.textSecondary),
              ),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: AppSpacing.componentXl),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
