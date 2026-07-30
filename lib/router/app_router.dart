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
import '../theme/app_motion.dart';

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

// Outgoing finishes within the first 40% of the duration; incoming starts at
// 40% and resolves over the last 60%. Pages are never both at meaningful
// opacity at the same instant — at t = 0.4 both sit at 0 and the
// AppCanvas reads as a single continuous surface.
const Interval _kIncomingForward =
    Interval(0.4, 1.0, curve: AppMotion.emphasized);
const Interval _kIncomingReverse =
    Interval(0.6, 1.0, curve: AppMotion.standard);
const Interval _kOutgoingForward =
    Interval(0.0, 0.4, curve: AppMotion.emphasized);
const Interval _kOutgoingReverse =
    Interval(0.0, 0.6, curve: AppMotion.standard);

const double _kIncomingScaleStart = 1.04;
const double _kOutgoingScaleEnd = 0.96;

CustomTransitionPage<T> _fadePage<T>(
    Widget child, GoRouterState state) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.medium,
    reverseTransitionDuration: AppMotion.medium,
    transitionsBuilder: _stagedFadeThrough,
  );
}

Widget _stagedFadeThrough(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  if (MediaQuery.disableAnimationsOf(context)) {
    return child;
  }
  return _StagedFade(
    primary: animation,
    secondary: secondaryAnimation,
    child: child,
  );
}

class _StagedFade extends StatelessWidget {
  final Animation<double> primary;
  final Animation<double> secondary;
  final Widget child;

  const _StagedFade({
    required this.primary,
    required this.secondary,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[primary, secondary]),
      child: child,
      builder: (BuildContext context, Widget? child) {
        // Self layer: page is the one being pushed in (forward) or popped out
        // (reverse). The role flips with direction.
        final bool selfIsIncoming =
            primary.status != AnimationStatus.reverse;
        final Interval selfInterval =
            selfIsIncoming ? _kIncomingForward : _kIncomingReverse;
        final double selfT = selfInterval.transform(primary.value);

        // Cover layer: page is the one being covered (forward) or revealed
        // (reverse). Role also flips with direction.
        final bool coverIsOutgoing =
            secondary.status != AnimationStatus.reverse;
        final Interval coverInterval =
            coverIsOutgoing ? _kOutgoingForward : _kOutgoingReverse;
        final double coverT = coverInterval.transform(secondary.value);

        final double selfOpacity = selfT;
        final double coverOpacity = coverIsOutgoing ? 1.0 - coverT : 1.0 - coverT;
        final double opacity = (selfOpacity * coverOpacity).clamp(0.0, 1.0);

        // Self scale: incoming slides 1.04 → 1.0; outgoing (pop) shrinks
        // 1.0 → 0.96 over the first 40% of the reverse.
        final double selfScale = selfIsIncoming
            ? _kIncomingScaleStart + (1.0 - _kIncomingScaleStart) * selfT
            : _kOutgoingScaleEnd + (1.0 - _kOutgoingScaleEnd) * selfT;

        // Cover scale: covered shrinks 1.0 → 0.96; revealed re-enters
        // 1.04 → 1.0 over the last 60% of the reverse.
        final double coverScale = coverIsOutgoing
            ? 1.0 + (_kOutgoingScaleEnd - 1.0) * coverT
            : 1.0 + (_kIncomingScaleStart - 1.0) * coverT;

        final double scale = selfScale * coverScale;

        return IgnorePointer(
          ignoring: opacity < 0.5,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Auth page paths (used in redirect logic)
// ---------------------------------------------------------------------------

// Pages an unauthenticated user may rest on. The '/' splash is deliberately
// NOT here: it only hosts a spinner while AuthLoading resolves, and parking a
// resolved-but-unauthenticated user there strands them on an infinite loader.
const List<String> _authPaths = [
  AppRoutes.userSelection,
  AppRoutes.login,
];

/// Decides where the router should send the user for a given [authState] and
/// [currentPath]. Returns null to stay put. Exposed for unit testing.
@visibleForTesting
String? authRedirect(AuthState authState, String currentPath) {
  final bool onSplash = currentPath == AppRoutes.splash;
  final bool onAuthPage = _authPaths.contains(currentPath);

  if (authState is AuthLoading) {
    return null;
  }

  if (authState is AuthUnauthenticated || authState is AuthError) {
    if (onAuthPage) return null;
    return AppRoutes.userSelection;
  }

  if (authState is AuthAuthenticated && (onAuthPage || onSplash)) {
    return AppRoutes.dashboard;
  }

  return null;
}

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
      return authRedirect(authState, state.matchedLocation);
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
