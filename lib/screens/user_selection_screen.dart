import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_notifier.dart';
import '../router/app_router.dart';
import '../models/user_model.dart';
import '../widgets/core/app_card.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/plutus_tokens.dart';

class UserSelectionScreen extends ConsumerStatefulWidget {
  const UserSelectionScreen({super.key});

  @override
  ConsumerState<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends ConsumerState<UserSelectionScreen> {
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final users = await authNotifier.getAllUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  Future<void> _selectUser(User user) async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final success = await authNotifier.signInWithLocalUser(user.username);

    if (success && mounted) {
      context.go(AppRoutes.dashboard);
    }
  }

  Future<void> _showCreateUserDialog() async {
    final l10n = AppLocalizations.of(context);
    final usernameController = TextEditingController();
    final displayNameController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
        title: Text(l10n.createProfile),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: l10n.usernameLabel,
                hintText: l10n.usernameHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: displayNameController,
              decoration: InputDecoration(
                labelText: l10n.displayNameLabel,
                hintText: l10n.displayNameHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.create),
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
            SnackBar(content: Text(l10n.fillAllFields)),
          );
        }
        return;
      }

      final authNotifier = ref.read(authNotifierProvider.notifier);
      final success = await authNotifier.createLocalUser(username, displayName);

      if (success && mounted) {
        context.go(AppRoutes.dashboard);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.usernameTaken)),
        );
      }
    }
  }

  Future<void> _createGuestUser() async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final success = await authNotifier.createLocalUser(
      'guest_$timestamp',
      'Guest',
      isGuest: true,
    );

    if (success && mounted) {
      context.go(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.switchProfile),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.whosUsingPlutus,
                    style: AppTextStyles.headingStyle.copyWith(color: t.text),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  if (_users.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 80, color: t.textMuted),
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              l10n.noProfilesFound,
                              style: TextStyle(fontSize: 18, color: t.textMuted),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              l10n.createProfileToStart,
                              style: TextStyle(fontSize: 14, color: t.textMuted),
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
                            child: AppCard(
                              padding: EdgeInsets.zero,
                              child: _UserRow(
                                user: user,
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
                    label: Text(l10n.createProfile),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: _createGuestUser,
                    icon: const Icon(Icons.person_outline),
                    label: Text(l10n.continueAsGuest),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton.icon(
                    onPressed: () {
                      context.go(AppRoutes.login);
                    },
                    icon: const Icon(Icons.login),
                    label: Text(l10n.signInWithGoogle),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Single profile row: avatar (gold ring on hover), name/username/email,
/// OAuth/Guest badges. Tap signs in immediately — hover is a visual-only
/// state, no selection is persisted (spec §7).
class _UserRow extends StatefulWidget {
  final User user;
  final VoidCallback onTap;

  const _UserRow({required this.user, required this.onTap});

  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final PlutusTokens t = context.tokens;
    final l10n = AppLocalizations.of(context);
    final user = widget.user;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onHover: (value) => setState(() => _hovered = value),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          leading: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _hovered ? t.gold : t.border,
                width: _hovered ? 2 : 1,
              ),
            ),
            child: CircleAvatar(
              backgroundColor: t.surfaceSubtle,
              child: Text(
                user.displayName[0].toUpperCase(),
                style: TextStyle(
                  color: t.brandNavy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          title: Text(
            user.displayName,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: t.text,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('@${user.username}', overflow: TextOverflow.ellipsis, style: TextStyle(color: t.textSecondary)),
              if (user.email != null)
                Text(
                  user.email!,
                  style: TextStyle(fontSize: 12, color: t.textSecondary),
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
                        color: t.surfaceSubtle,
                        borderRadius: AppRadius.borderPill,
                      ),
                      child: Text(
                        l10n.googleBadge,
                        style: TextStyle(
                          fontSize: 10,
                          color: t.textSecondary,
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
                        color: t.surfaceSubtle,
                        borderRadius: AppRadius.borderPill,
                      ),
                      child: Text(
                        l10n.guestBadge,
                        style: TextStyle(
                          fontSize: 10,
                          color: t.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          trailing: Icon(Icons.arrow_forward_ios, color: t.textSecondary),
        ),
      ),
    );
  }
}
