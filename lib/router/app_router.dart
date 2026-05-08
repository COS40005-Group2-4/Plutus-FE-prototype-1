import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_notifier.dart';
import '../screens/login_screen.dart';
import '../screens/user_selection_screen.dart';
import '../screens/main_navigation_page.dart';
import '../screens/settings_screen.dart';
import '../screens/investment_list_screen.dart';
import '../screens/investment_detail_screen.dart';
import '../screens/backup_history_screen.dart';
import '../screens/insights_screen.dart';
import '../screens/report_config_screen.dart';
import '../screens/report_preview_screen.dart';
import '../screens/transaction_history_page.dart';
import '../screens/import_transaction_page.dart';
import '../theme/app_elevation.dart';

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
// Fade-through page transition for all routes
// ---------------------------------------------------------------------------

CustomTransitionPage<T> _fadePage<T>(
    Widget child, GoRouterState state) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.medium,
    reverseTransitionDuration: AppMotion.medium,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Fade-through: outgoing fades out, incoming fades in.
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: AppMotion.emphasized,
          reverseCurve: AppMotion.standard,
        ),
        child: child,
      );
    },
  );
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

      if (authState is AuthLoading) {
        return null;
      }

      if (authState is AuthUnauthenticated || authState is AuthError) {
        if (onAuthPage) return null;
        return AppRoutes.userSelection;
      }

      if (authState is AuthAuthenticated && onAuthPage) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => _fadePage(
          const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          state,
        ),
      ),
      GoRoute(
        path: AppRoutes.userSelection,
        pageBuilder: (context, state) =>
            _fadePage(const UserSelectionScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _fadePage(const LoginScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        pageBuilder: (context, state) =>
            _fadePage(const MainNavigationPage(), state),
        routes: [
          GoRoute(
            path: 'history',
            pageBuilder: (context, state) =>
                _fadePage(const TransactionHistoryPage(), state),
          ),
          GoRoute(
            path: 'import',
            pageBuilder: (context, state) =>
                _fadePage(const ImportTransactionPage(), state),
          ),
          GoRoute(
            path: 'settings',
            pageBuilder: (context, state) =>
                _fadePage(const SettingsScreen(), state),
          ),
          GoRoute(
            path: 'investments',
            pageBuilder: (context, state) =>
                _fadePage(const InvestmentListScreen(), state),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => _fadePage(
                  InvestmentDetailScreen(
                    investmentId: state.pathParameters['id']!,
                  ),
                  state,
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'backup-history',
            pageBuilder: (context, state) =>
                _fadePage(const BackupHistoryScreen(), state),
          ),
          GoRoute(
            path: 'insights',
            pageBuilder: (context, state) =>
                _fadePage(const InsightsScreen(), state),
          ),
          GoRoute(
            path: 'report-config',
            pageBuilder: (context, state) =>
                _fadePage(const ReportConfigScreen(), state),
          ),
          GoRoute(
            path: 'report-preview',
            pageBuilder: (context, state) =>
                _fadePage(const ReportPreviewScreen(), state),
          ),
        ],
      ),
    ],
  );
});
