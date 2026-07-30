import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/profile_widget.dart';
import '../providers/auth_notifier.dart';
import '../theme/app_spacing.dart';
import '../theme/plutus_tokens.dart';
import '../l10n/app_localizations.dart';
import 'core/app_card.dart';

// Profile Display Widget for Dashboard
class ProfileDashboardWidget extends ConsumerWidget {
  const ProfileDashboardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState is AuthAuthenticated ? authState.user : null;
    final PlutusTokens t = context.tokens;

    if (currentUser == null) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text(
            'No user logged in',
            style: TextStyle(color: t.text, fontSize: 14),
          ),
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppLocalizations.of(context).translate('widget_label_profile'),
                style: TextStyle(
                  color: t.text,
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
                  color: t.textMuted,
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
