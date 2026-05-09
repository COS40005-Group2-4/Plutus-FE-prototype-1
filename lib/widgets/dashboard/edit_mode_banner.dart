import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_elevation.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

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
    final brightness = Theme.of(context).brightness;
    final l10n = AppLocalizations.of(context);
    final accent = AppColors.editAccent(brightness);
    final softFill = AppColors.brandSoft(brightness);
    final onAccent = AppColors.editHandleForeground(brightness);
    final textPrimary = AppColors.textPrimary(brightness);
    final textSecondary = AppColors.textSecondary(brightness);

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
              color: softFill,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: accent.withValues(alpha: 0.30),
                width: 1,
              ),
              boxShadow: AppElevation.brandGlow(brightness),
            ),
            child: Row(
              children: [
                _BannerLeading(accent: accent, onAccent: onAccent),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.editModeBannerTitle,
                        style: AppTextStyles.bodyStrongStyle.copyWith(
                          color: textPrimary,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.editModeBannerSubtitle,
                        style: AppTextStyles.captionStyle.copyWith(
                          color: textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onUndo != null)
                  _SecondaryAction(
                    icon: Icons.undo_rounded,
                    label: l10n.editModeActionUndo,
                    color: accent,
                    onPressed: onUndo!,
                  ),
                const SizedBox(width: AppSpacing.sm),
                _DoneButton(
                  label: l10n.editModeDone,
                  background: accent,
                  foreground: onAccent,
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

class _BannerLeading extends StatelessWidget {
  final Color accent;
  final Color onAccent;
  const _BannerLeading({required this.accent, required this.onAccent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(AppRadius.iconButton),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.tune_rounded, size: 18, color: onAccent),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        child: TextButton.icon(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: color,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.iconButton),
            ),
          ),
          icon: Icon(icon, size: 18),
          label: Text(
            label,
            style: AppTextStyles.labelStyle.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}

class _DoneButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  const _DoneButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
