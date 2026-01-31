import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart' as gsi;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:provider/provider.dart';
import '../widgets/glass_container.dart';
import '../providers/auth_provider.dart';

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
              return StreamBuilder<gsi.GoogleSignInCredentials?>(
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
    return SingleChildScrollView(
      child: Center(
        child: GlassContainer(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(30),
          borderRadius: 20,
          opacity: 0.1,
          blur: 15,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          const Icon(
            Icons.account_balance_wallet,
            size: 100,
            color: Colors.blue,
          ),
          const SizedBox(height: 20),
          const Text(
            'Welcome to Plutus',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          // Show error message if present
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red[900],
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
                  setState(() => _errorMessage = 'Login failed. Please check your Google credentials and try again.');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Login failed. Please try again.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
            ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () async {
              await authProvider.setGuestMode(true);
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/dashboard');
              }
            },
            child: const Text(
              'Continue as Guest',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}
