import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/plutus_tokens.dart';

/// Top-of-screen banner shown while the dashboard is in edit mode.
///
/// Communicates the editing state explicitly and exposes the primary
/// actions (Add widget, Undo, Done). Slides into view from above; pair
/// with an [AnimatedSwitcher] / [AnimatedSize] in the parent to drive the
/// enter / exit transition.
class EditModeBanner extends StatelessWidget {
  final VoidCallback onDone;
  final VoidCallback? onUndo;

  const EditModeBanner({
    super.key,
    required this.onDone,
    this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    final l10n = AppLocalizations.of(context);

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Semantics(
          container: true,
          liveRegion: true,
          label: l10n.editModeBannerTitle,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: t.info.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: t.info.border),
            ),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, color: t.info.text, size: 20),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.editModeBannerTitle,
                        style: AppTextStyles.bodyStrongStyle.copyWith(
                          color: t.info.text,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.editModeBannerSubtitle,
                        style: AppTextStyles.captionStyle.copyWith(
                          color: t.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onUndo != null)
                  _BannerAction(
                    icon: Icons.undo_rounded,
                    label: l10n.editModeActionUndo,
                    color: t.textSecondary,
                    onPressed: onUndo!,
                  ),
                const SizedBox(width: AppSpacing.sm),
                _BannerAction(
                  icon: null,
                  label: l10n.editModeDone,
                  color: t.goldText,
                  onPressed: onDone,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerAction extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _BannerAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final buttonIcon = icon;
    final labelText = Text(
      label,
      style: AppTextStyles.labelStyle.copyWith(color: color),
    );
    final style = TextButton.styleFrom(
      foregroundColor: color,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      minimumSize: const Size(0, 44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.iconButton),
      ),
    );

    return Tooltip(
      message: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: buttonIcon != null
            ? TextButton.icon(
                onPressed: onPressed,
                style: style,
                icon: Icon(buttonIcon, size: 18),
                label: labelText,
              )
            : TextButton(
                onPressed: onPressed,
                style: style,
                child: labelText,
              ),
      ),
    );
  }
}
