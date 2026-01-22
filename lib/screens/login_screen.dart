import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            // Listen to authentication state changes on web
            if (kIsWeb) {
              return StreamBuilder(
                stream: authProvider.authenticationState,
                builder: (context, snapshot) {
                  // If authenticated, navigate to dashboard
                  if (snapshot.hasData && snapshot.data != null) {
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
    return Column(
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
        // Use sign-in button widget on web, regular button on other platforms
        if (kIsWeb)
          authProvider.getSignInButton() ?? const SizedBox.shrink()
        else
          ElevatedButton.icon(
            onPressed: () async {
              final success = await authProvider.signIn();
              if (success && context.mounted) {
                Navigator.pushReplacementNamed(context, '/dashboard');
              } else if (context.mounted) {
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
      ],
    );
  }
}
