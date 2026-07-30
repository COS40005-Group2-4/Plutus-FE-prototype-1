import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/core/app_card.dart';
import '../providers/auth_notifier.dart';
import '../router/app_router.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/plutus_tokens.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _hasRedirected = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final authNotifier = ref.read(authNotifierProvider.notifier);

    return Scaffold(
      body: Center(
        child: Builder(
          builder: (context) {
            final authState = ref.watch(authNotifierProvider);

            // Listen to authentication state changes on web
            if (kIsWeb) {
              return StreamBuilder<dynamic>(
                stream: authNotifier.authenticationState,
                builder: (context, snapshot) {
                  // If authenticated, navigate to dashboard
                  if (snapshot.hasData && snapshot.data != null && !_hasRedirected) {
                    _hasRedirected = true;
                    if (kDebugMode) {
                      debugPrint('Authentication state changed (snapshot has data) - navigating to dashboard');
                    }
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        context.go(AppRoutes.dashboard);
                      }
                    });
                  }

                  if (authState is AuthLoading) {
                    return const CircularProgressIndicator();
                  }

                  return _buildLoginUI(context, authNotifier);
                },
              );
            }

            // For non-web platforms
            if (authState is AuthLoading) {
              return const CircularProgressIndicator();
            }

            return _buildLoginUI(context, authNotifier);
          },
        ),
      ),
    );
  }

  Widget _buildLoginUI(BuildContext context, AuthNotifier authNotifier) {
    final PlutusTokens t = context.tokens;
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: AppCard(
            margin: EdgeInsets.all(isSmall ? AppSpacing.lg : AppSpacing.xl),
            padding: EdgeInsets.all(isSmall ? AppSpacing.xxl : AppSpacing.xxxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: t.surfaceSubtle,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Image.asset(
                      'lib/assets/branding/plutus_icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  l10n.loginWelcome,
                  style: AppTextStyles.headingStyle.copyWith(color: t.text),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.loginSubtitle,
                  style: AppTextStyles.bodyStyle.copyWith(color: t.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.tagline,
                  style: AppTextStyles.heroSerifStyle.copyWith(color: t.goldText),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: t.error.surface,
                      borderRadius: BorderRadius.circular(AppRadius.input),
                      border: Border.all(color: t.error.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, size: 20, color: t.error.text),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 5,
                            style: AppTextStyles.bodyStyle.copyWith(color: t.error.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (kIsWeb)
                  authNotifier.authService.getSignInButton() ??
                      const SizedBox.shrink()
                else
                  FilledButton.icon(
                    onPressed: () async {
                      setState(() => _errorMessage = null);
                      final success = await authNotifier.signIn();
                      if (success && context.mounted) {
                        context.go(AppRoutes.dashboard);
                      } else if (context.mounted) {
                        setState(() => _errorMessage = l10n.loginFailedGoogle);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.loginFailed)),
                        );
                      }
                    },
                    icon: const Icon(Icons.login, size: 20),
                    label: Text(l10n.signInWithGoogle),
                  ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton(
                  onPressed: () async {
                    if (context.mounted) {
                      context.go(AppRoutes.userSelection);
                    }
                  },
                  child: Text(l10n.continueAsGuest),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
