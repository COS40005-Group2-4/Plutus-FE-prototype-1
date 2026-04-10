import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/glass_container.dart';
import '../widgets/profile_widget.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../l10n/app_localizations.dart';

// Profile Display Widget for Dashboard
class ProfileDashboardWidget extends StatefulWidget {
  const ProfileDashboardWidget({super.key});

  @override
  State<ProfileDashboardWidget> createState() => _ProfileDashboardWidgetState();
}

class _ProfileDashboardWidgetState extends State<ProfileDashboardWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final currentUser = authProvider.currentUser;

        if (currentUser == null) {
          return GlassContainer(
            color: AppColors.profileAccent,
            opacity: 0.2,
            borderRadius: AppRadius.lg,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: const Center(
              child: Text(
                'No user logged in',
                style: TextStyle(color: AppColors.textOnDark, fontSize: 14),
              ),
            ),
          );
        }

        return GlassContainer(
          color: AppColors.profileAccent,
          opacity: 0.2,
          borderRadius: AppRadius.lg,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context).translate('widget_label_profile'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: AppLocalizations.of(context).widgetHelpProfile,
                    child: Icon(
                      Icons.help_outline,
                      size: 14,
                      color: AppColors.textTertiary(Theme.of(context).brightness),
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
      },
    );
  }
}
