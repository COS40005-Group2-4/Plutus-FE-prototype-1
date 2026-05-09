import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/glass_container.dart';
import '../widgets/profile_widget.dart';
import '../providers/auth_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../l10n/app_localizations.dart';

// Profile Display Widget for Dashboard
class ProfileDashboardWidget extends ConsumerWidget {
  const ProfileDashboardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState is AuthAuthenticated ? authState.user : null;
    final brightness = Theme.of(context).brightness;
    const accent = AppColors.profileAccent;
    final onAccent = AppColors.onAccentPrimary(accent, brightness);
    final onAccentTertiary = AppColors.onAccentTertiary(accent, brightness);

    if (currentUser == null) {
      return GlassContainer(
        color: accent,
        opacity: 0.2,
        borderRadius: AppRadius.card,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text(
            'No user logged in',
            style: TextStyle(color: onAccent, fontSize: 14),
          ),
        ),
      );
    }

    return GlassContainer(
      color: accent,
      opacity: 0.2,
      borderRadius: AppRadius.card,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppLocalizations.of(context).translate('widget_label_profile'),
                style: TextStyle(
                  color: onAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Tooltip(
                message: AppLocalizations.of(context).widgetHelpProfile,
                child: Icon(
                  Icons.help_outline,
                  size: 14,
                  color: onAccentTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: SingleChildScrollView(
              child: ProfileWidget(
                user: currentUser,
                defaultAvatarAsset: 'lib/assets/avatar/default-avatar.jpg',
                isCompact: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
