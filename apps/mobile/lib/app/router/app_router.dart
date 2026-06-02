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

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final onboardingState = ref.watch(onboardingStatusProvider);
  final isAuthenticated = authState.valueOrNull != null;

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final authLoading = authState.isLoading;
      final onboardingLoading = onboardingState.isLoading;

      if (authLoading || (isAuthenticated && onboardingLoading)) {
        return location == '/splash' ? null : '/splash';
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

        if (isCompleted && (location == '/splash' || location == '/onboarding' || isAuthRoute)) {
          return '/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const Scaffold(
          backgroundColor: Color(0xFF0F111A),
          body: Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
        ),
      ),
      GoRoute(
        path: '/intro',
        builder: (context, state) => const IntroScreen(),
      ),
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
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/personal-info',
        builder: (context, state) => const PersonalInfoScreen(),
      ),
      GoRoute(
        path: '/streak',
        builder: (context, state) => const StreakScreen(),
      ),
      GoRoute(
        path: '/profile/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/profile/privacy',
        builder: (context, state) => const PrivacySecurityScreen(),
      ),
      GoRoute(
        path: '/profile/help',
        builder: (context, state) => const HelpAboutScreen(),
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
