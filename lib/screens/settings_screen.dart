import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF4285F4),
      ),
      body: authProvider.isAuthenticated 
        ? _buildAuthenticatedSettings(context, authProvider)
        : _buildGuestSettings(context, authProvider),
    );
  }

  Widget _buildAuthenticatedSettings(BuildContext context, AuthProvider authProvider) {
    return ListView(
      children: [
        const SizedBox(height: 20),
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.blue,
          child: Text(
            authProvider.userName.isNotEmpty 
                ? authProvider.userName[0].toUpperCase() 
                : 'U',
            style: const TextStyle(fontSize: 40, color: Colors.white),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            authProvider.userName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            authProvider.userEmail,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Session info
        FutureBuilder<Map<String, dynamic>>(
          future: authProvider.getSessionInfo(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              final sessionInfo = snapshot.data!;
              final daysUntilExpiry = sessionInfo['daysUntilExpiry'] as int?;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  color: Colors.blue.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.offline_bolt, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Text(
                              'Offline Session',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (daysUntilExpiry != null)
                          Text(
                            'Your session remains valid for $daysUntilExpiry more days while offline',
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        const SizedBox(height: 8),
                        const Text(
                          'You can use the app offline. Your session will be verified when you\'re back online.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(height: 20),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text(
            'Sign Out',
            style: TextStyle(color: Colors.red),
          ),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Sign Out'),
                content: const Text('Are you sure you want to sign out?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            );
            
            if (confirm == true && context.mounted) {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildGuestSettings(BuildContext context, AuthProvider authProvider) {
    return ListView(
      children: [
        const SizedBox(height: 40),
        const Center(
          child: Icon(
            Icons.account_circle_outlined,
            size: 100,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'Guest Mode',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Sign in to sync your data across devices and enable online backups.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            icon: const Icon(Icons.login),
            label: const Text('Sign In with Google'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              backgroundColor: const Color(0xFF4285F4),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
