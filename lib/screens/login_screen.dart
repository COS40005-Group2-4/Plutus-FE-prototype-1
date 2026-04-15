import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/glass_container.dart';
import '../providers/auth_notifier.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: GlassContainer(
            margin: EdgeInsets.all(isSmall ? AppSpacing.lg : AppSpacing.xl),
            padding: EdgeInsets.all(isSmall ? AppSpacing.xl : AppSpacing.xxxl),
            borderRadius: AppRadius.xl,
            opacity: 0.1,
            blur: 15,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            Icon(
              Icons.account_balance_wallet,
              size: isSmall ? 72 : 100,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Welcome to Plutus',
              style: TextStyle(
                fontSize: isSmall ? 24 : 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Show error message if present
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    border: Border.all(color: AppColors.error),
                    borderRadius: AppRadius.borderSm,
                  ),
                  child: Text(
                    _errorMessage!,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 5,
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            // Use sign-in button widget on web, regular button on other platforms
            if (kIsWeb)
              authNotifier.authService.getSignInButton() ?? const SizedBox.shrink()
            else
              ElevatedButton.icon(
                onPressed: () async {
                  setState(() => _errorMessage = null);
                  final success = await authNotifier.signIn();
                  if (success && context.mounted) {
                    context.go(AppRoutes.dashboard);
                  } else if (context.mounted) {
                    setState(() => _errorMessage = 'Sign-in failed. Please check your Google account and try again.');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sign-in failed. Please try again.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxxl,
                    vertical: AppSpacing.lg,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            TextButton(
              onPressed: () async {
                // Navigate to user selection where they can create guest account
                if (context.mounted) {
                  context.go(AppRoutes.userSelection);
                }
              },
              child: Text(
                'Continue as Guest',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textOnLightTertiary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
