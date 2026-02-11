import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/profile_widget.dart';
import '../widgets/glass_container.dart';

/// Profile Screen for displaying user profile
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final currentUser = authProvider.currentUser;

          if (currentUser == null) {
            return const Center(
              child: Text('No user logged in'),
            );
          }

          return SafeArea(
            child: GlassContainer(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(0),
              child: ProfileWidget(
                user: currentUser,
                defaultAvatarAsset: 'lib/assets/avatar/default-avatar.jpg',
                isCompact: false,
              ),
            ),
          );
        },
      ),
    );
  }
}
