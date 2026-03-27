import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart' as gsi;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:provider/provider.dart';
import '../widgets/glass_container.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _hasRedirected = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            // Listen to authentication state changes on web
            if (kIsWeb) {
              return StreamBuilder<dynamic>(
                stream: authProvider.authenticationState,
                builder: (context, snapshot) {
                  // If authenticated, navigate to dashboard
                  if (snapshot.hasData && snapshot.data != null && !_hasRedirected) {
                    _hasRedirected = true;
                    if (kDebugMode) {
                      print('Authentication state changed (snapshot has data) - navigating to dashboard');
                    }
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        Navigator.pushReplacementNamed(context, '/dashboard');
                      }
                    });
                  }
                  
                  if (authProvider.isLoading) {
                    return const CircularProgressIndicator();
                  }
                  
                  return _buildLoginUI(context, authProvider);
                },
              );
            }
            
            // For non-web platforms
            if (authProvider.isLoading) {
              return const CircularProgressIndicator();
            }
            
            return _buildLoginUI(context, authProvider);
          },
        ),
      ),
    );
  }
  
  Widget _buildLoginUI(BuildContext context, AuthProvider authProvider) {
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
              authProvider.getSignInButton() ?? const SizedBox.shrink()
            else
              ElevatedButton.icon(
                onPressed: () async {
                  setState(() => _errorMessage = null);
                  final success = await authProvider.signIn();
                  if (success && context.mounted) {
                    Navigator.pushReplacementNamed(context, '/dashboard');
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
                  Navigator.pushReplacementNamed(context, '/user_selection');
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
