import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_notifier.dart';
import '../widgets/profile_widget.dart';
import '../widgets/glass_container.dart';
import '../theme/app_spacing.dart';

/// Profile Screen for displaying user profile
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: currentUser == null
          ? const Center(child: Text('No user logged in'))
          : SafeArea(
              child: GlassContainer(
                margin: const EdgeInsets.all(AppSpacing.sm),
                padding: const EdgeInsets.all(0),
                child: ProfileWidget(
                  user: currentUser,
                  defaultAvatarAsset: 'lib/assets/avatar/default-avatar.jpg',
                  isCompact: false,
                ),
              ),
            ),
    );
  }
}
