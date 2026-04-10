import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/glass_container.dart';
import '../widgets/profile_widget.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

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
          child: SingleChildScrollView(
            child: ProfileWidget(
            user: currentUser,
            defaultAvatarAsset: 'lib/assets/avatar/default-avatar.jpg',
            isCompact: true,
          ),
          ),
        );
      },
    );
  }
}
