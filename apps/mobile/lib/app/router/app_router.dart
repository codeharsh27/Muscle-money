import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/app_shell.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dashboard/presentation/streak_screen.dart';
import '../../features/intro/presentation/intro_screen.dart';
import '../../features/learning/presentation/learning_screen.dart';
import '../../features/onboarding/presentation/onboarding_controller.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/personal_info_screen.dart';
import '../../features/profile/presentation/settings_screens.dart';
import '../../features/simulator/presentation/simulator_screen.dart';
import '../../features/wallet/presentation/wallet_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';

CustomTransitionPage<void> _fadeTransitionPage({required LocalKey key, required Widget child}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(authControllerProvider, (_, __) => notifyListeners());
    _ref.listen(onboardingStatusProvider, (_, __) => notifyListeners());
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) => RouterNotifier(ref));

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final onboardingState = ref.read(onboardingStatusProvider);
      final isAuthenticated = authState.valueOrNull != null;
      final location = state.matchedLocation;
      final authLoading = authState.isLoading;
      final onboardingLoading = onboardingState.isLoading;

      if (authLoading || (isAuthenticated && onboardingLoading)) {
        return null;
      }

      final isAuthRoute = location == '/sign-in' || location == '/sign-up';
      final isIntroRoute = location == '/intro';

      if (!isAuthenticated && !isAuthRoute && !isIntroRoute) {
        final box = Hive.box('settings');
        final hasSeenIntro = box.get('has_seen_intro', defaultValue: false) as bool;
        
        if (!hasSeenIntro) {
          return '/intro';
        }
        return '/sign-in';
      }

      if (isAuthenticated) {
        final status = onboardingState.valueOrNull;
        final isCompleted = status?.completed ?? false;

        if (!isCompleted && location != '/onboarding') {
          return '/onboarding';
        }

        if (isCompleted) {
          if (location == '/onboarding' || location == '/generating-plan') {
            return '/dashboard';
          }
          if (location == '/splash' || isAuthRoute) {
            return '/dashboard';
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _fadeTransitionPage(
          key: state.pageKey,
          child: const Scaffold(
            backgroundColor: Color(0xFF0F111A),
            body: Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
          ),
        ),
      ),
      GoRoute(
        path: '/intro',
        pageBuilder: (context, state) => _fadeTransitionPage(key: state.pageKey, child: const IntroScreen()),
      ),
      GoRoute(
        path: '/sign-in',
        pageBuilder: (context, state) => _fadeTransitionPage(key: state.pageKey, child: const SignInScreen()),
      ),
      GoRoute(
        path: '/sign-up',
        pageBuilder: (context, state) => _fadeTransitionPage(key: state.pageKey, child: const SignUpScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _fadeTransitionPage(key: state.pageKey, child: const OnboardingScreen()),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => _fadeTransitionPage(key: state.pageKey, child: const ProfileScreen()),
      ),
      GoRoute(
        path: '/profile/personal-info',
        pageBuilder: (context, state) => _fadeTransitionPage(key: state.pageKey, child: const PersonalInfoScreen()),
      ),
      GoRoute(
        path: '/streak',
        pageBuilder: (context, state) => _fadeTransitionPage(key: state.pageKey, child: const StreakScreen()),
      ),
      GoRoute(
        path: '/profile/notifications',
        pageBuilder: (context, state) => _fadeTransitionPage(key: state.pageKey, child: const NotificationsScreen()),
      ),
      GoRoute(
        path: '/profile/privacy',
        pageBuilder: (context, state) => _fadeTransitionPage(key: state.pageKey, child: const PrivacySecurityScreen()),
      ),
      GoRoute(
        path: '/profile/help',
        pageBuilder: (context, state) => _fadeTransitionPage(key: state.pageKey, child: const HelpAboutScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/learning',
                builder: (context, state) => const LearningScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wallet',
                builder: (context, state) => const WalletScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/simulator',
                builder: (context, state) => const SimulatorScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
