import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/glass_container.dart';
import '../widgets/profile_widget.dart';
import '../providers/auth_provider.dart';

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
            color: Colors.purple,
            opacity: 0.2,
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: const Center(
              child: Text(
                'No user logged in',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          );
        }

        return GlassContainer(
          color: Colors.purple,
          opacity: 0.2,
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
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
