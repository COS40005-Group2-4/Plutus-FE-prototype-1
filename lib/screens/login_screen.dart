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
import '../theme/app_text_styles.dart';

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
    final brightness = Theme.of(context).brightness;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;
    final brand = AppColors.brand(brightness);

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: GlassContainer(
            margin: EdgeInsets.all(isSmall ? AppSpacing.lg : AppSpacing.xl),
            padding: EdgeInsets.all(isSmall ? AppSpacing.xxl : AppSpacing.xxxl),
            borderRadius: AppRadius.xl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: brand.withValues(alpha: 0.12),
                      borderRadius: AppRadius.borderLg,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 32,
                      color: brand,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Welcome to Plutus',
                  style: AppTextStyles.headingStyle.copyWith(
                    color: AppColors.textPrimary(brightness),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Track spending, budgets, and investments in one place.',
                  style: AppTextStyles.bodyStyle.copyWith(
                    color: AppColors.textSecondary(brightness),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxxl),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.10),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.4),
                      ),
                      borderRadius: AppRadius.borderMd,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 20, color: AppColors.error),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 5,
                            style: AppTextStyles.bodyStyle
                                .copyWith(color: AppColors.error),
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
                        setState(() => _errorMessage =
                            'Sign-in failed. Please check your Google account and try again.');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sign-in failed. Please try again.'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.login, size: 20),
                    label: const Text('Sign in with Google'),
                  ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () async {
                    if (context.mounted) {
                      context.go(AppRoutes.userSelection);
                    }
                  },
                  child: const Text('Continue as Guest'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
