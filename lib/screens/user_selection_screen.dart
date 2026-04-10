import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../widgets/glass_container.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class UserSelectionScreen extends StatefulWidget {
  const UserSelectionScreen({super.key});

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final users = await authProvider.getAllUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  Future<void> _selectUser(User user) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithLocalUser(user.username);
    
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  Future<void> _showCreateUserDialog() async {
    final usernameController = TextEditingController();
    final displayNameController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
        title: const Text('Create a Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Choose a username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                hintText: 'Your display name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final username = usernameController.text.trim();
      final displayName = displayNameController.text.trim();

      if (username.isEmpty || displayName.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill in all fields to continue')),
          );
        }
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.createLocalUser(username, displayName);

      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't create your account. That username may already be taken.")),
        );
      }
    }
  }

  Future<void> _createGuestUser() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final success = await authProvider.createLocalUser(
      'guest_$timestamp',
      'Guest',
      isGuest: true,
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Switch Profile'),
        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    "Who's using Plutus?",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  if (_users.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 80, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                            SizedBox(height: AppSpacing.xl),
                            Text(
                              'No profiles found',
                              style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                            ),
                            SizedBox(height: AppSpacing.sm),
                            Text(
                              'Create a profile to get started',
                              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: GlassContainer(
                              borderRadius: AppRadius.md,
                              opacity: 0.1,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xl,
                                  vertical: AppSpacing.sm,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: user.isGuest
                                      ? AppColors.textOnLightSecondary
                                      : user.hasOAuth
                                          ? AppColors.primary
                                          : AppColors.success,
                                  child: Text(
                                    user.displayName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.textOnDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  user.displayName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('@${user.username}', overflow: TextOverflow.ellipsis),
                                    if (user.email != null)
                                      Text(
                                        user.email!,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Row(
                                      children: [
                                        if (user.hasOAuth)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.sm,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withValues(alpha: 0.2),
                                              borderRadius: AppRadius.borderMd,
                                            ),
                                            child: const Text(
                                              'Google',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        if (user.isGuest)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.sm,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.textOnLightSecondary.withValues(alpha: 0.2),
                                              borderRadius: AppRadius.borderMd,
                                            ),
                                            child: const Text(
                                              'Guest',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.textOnLightSecondary,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () => _selectUser(user),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton.icon(
                    onPressed: _showCreateUserDialog,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Create a Profile'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: _createGuestUser,
                    icon: const Icon(Icons.person_outline),
                    label: const Text('Continue as Guest'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in with Google'),
                  ),
                ],
              ),
            ),
    );
  }
}
