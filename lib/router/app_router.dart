import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_notifier.dart';
import '../screens/login_screen.dart';
import '../screens/user_selection_screen.dart';
import '../screens/main_navigation_page.dart';
import '../screens/settings_screen.dart';
import '../screens/investment_list_screen.dart';
import '../screens/backup_history_screen.dart';
import '../screens/insights_screen.dart';
import '../screens/report_config_screen.dart';
import '../screens/report_preview_screen.dart';
import '../transaction_history_page.dart';
import '../import_transaction_page.dart';

// ---------------------------------------------------------------------------
// Route path constants
// ---------------------------------------------------------------------------

abstract class AppRoutes {
  static const String splash = '/';
  static const String userSelection = '/user-selection';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String history = '/dashboard/history';
  static const String import_ = '/dashboard/import';
  static const String settings = '/dashboard/settings';
  static const String investments = '/dashboard/investments';
  static const String backupHistory = '/dashboard/backup-history';
  static const String insights = '/dashboard/insights';
  static const String reportConfig = '/dashboard/report-config';
  static const String reportPreview = '/dashboard/report-preview';
}

// ---------------------------------------------------------------------------
// _RouterNotifier — bridges Riverpod auth state to GoRouter refresh
// ---------------------------------------------------------------------------

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      notifyListeners();
    });
  }
}

// ---------------------------------------------------------------------------
// Auth page paths (used in redirect logic)
// ---------------------------------------------------------------------------

const List<String> _authPaths = [
  AppRoutes.splash,
  AppRoutes.userSelection,
  AppRoutes.login,
];

// ---------------------------------------------------------------------------
// GoRouter provider
// ---------------------------------------------------------------------------

final appRouterProvider = Provider<GoRouter>((Ref ref) {
  final _RouterNotifier notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (BuildContext context, GoRouterState state) {
      final AuthState authState = ref.read(authNotifierProvider);
      final String currentPath = state.matchedLocation;
      final bool onAuthPage = _authPaths.contains(currentPath);

      // Still loading — stay on current page (or splash).
      if (authState is AuthLoading) {
        return null;
      }

      // Unauthenticated or error — redirect to user selection unless already
      // on an auth page.
      if (authState is AuthUnauthenticated || authState is AuthError) {
        if (onAuthPage) return null;
        return AppRoutes.userSelection;
      }

      // Authenticated — redirect away from auth pages to dashboard.
      if (authState is AuthAuthenticated && onAuthPage) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        builder: (BuildContext context, GoRouterState state) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),

      // User selection
      GoRoute(
        path: AppRoutes.userSelection,
        builder: (BuildContext context, GoRouterState state) {
          return const UserSelectionScreen();
        },
      ),

      // Login
      GoRoute(
        path: AppRoutes.login,
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        },
      ),

      // Dashboard shell with sub-routes
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (BuildContext context, GoRouterState state) {
          return const MainNavigationPage();
        },
        routes: [
          GoRoute(
            path: 'history',
            builder: (BuildContext context, GoRouterState state) {
              return const TransactionHistoryPage();
            },
          ),
          GoRoute(
            path: 'import',
            builder: (BuildContext context, GoRouterState state) {
              return const ImportTransactionPage();
            },
          ),
          GoRoute(
            path: 'settings',
            builder: (BuildContext context, GoRouterState state) {
              return const SettingsScreen();
            },
          ),
          GoRoute(
            path: 'investments',
            builder: (BuildContext context, GoRouterState state) {
              return const InvestmentListScreen();
            },
          ),
          GoRoute(
            path: 'backup-history',
            builder: (BuildContext context, GoRouterState state) {
              return const BackupHistoryScreen();
            },
          ),
          GoRoute(
            path: 'insights',
            builder: (BuildContext context, GoRouterState state) {
              return const InsightsScreen();
            },
          ),
          GoRoute(
            path: 'report-config',
            builder: (BuildContext context, GoRouterState state) {
              return const ReportConfigScreen();
            },
          ),
          GoRoute(
            path: 'report-preview',
            builder: (BuildContext context, GoRouterState state) {
              return const ReportPreviewScreen();
            },
          ),
        ],
      ),
    ],
  );
});
