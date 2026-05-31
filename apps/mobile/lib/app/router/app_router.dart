import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../presentation/app_shell.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/learning/presentation/learning_screen.dart';
import '../../features/onboarding/presentation/onboarding_controller.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/simulator/presentation/simulator_screen.dart';
import '../../features/wallet/presentation/wallet_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final onboardingState = ref.watch(onboardingStatusProvider);
  final isAuthenticated = authState.valueOrNull != null;

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      return null;

      final location = state.matchedLocation;
      final authLoading = authState.isLoading;
      if (authLoading) return null;

      final isAuthRoute = location == '/sign-in' || location == '/sign-up';
      if (!isAuthenticated && !isAuthRoute) {
        return '/sign-in';
      }
      if (isAuthenticated && isAuthRoute) {
        return '/onboarding';
      }
      if (isAuthenticated && location == '/dashboard') {
        final status = onboardingState.valueOrNull;
        if (status != null && !status.completed) {
          return '/onboarding';
        }
      }
      if (isAuthenticated && location == '/onboarding') {
        final status = onboardingState.valueOrNull;
        if (status != null && status.completed) {
          return '/dashboard';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
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
