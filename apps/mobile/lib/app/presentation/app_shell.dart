import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../features/learning/presentation/ai_coach_screen.dart';
import '../../features/simulator/presentation/virtual_world_shell.dart';
import '../../features/simulator/presentation/virtual_world_transition_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index, BuildContext context) {
    if (index == 3) {
      // Intercept Simulator tap for Virtual World transition
      _enterVirtualWorld(context);
      return;
    }
    
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  void _enterVirtualWorld(BuildContext context) {
    // Push the full screen transition page which has the progress bar
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const VirtualWorldTransitionScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        heroTag: null,
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AiCoachScreen()));
          },
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          elevation: 8,
          shape: const CircleBorder(),
          child: ClipOval(
            child: Image.asset(
              'assets/images/nova_avatar.png',
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    label: 'Home',
                    isSelected: navigationShell.currentIndex == 0,
                    onTap: () => _goBranch(0, context),
                  ),
                  _NavItem(
                    icon: Icons.school_outlined,
                    activeIcon: Icons.school,
                    label: 'Learn',
                    isSelected: navigationShell.currentIndex == 1,
                    onTap: () => _goBranch(1, context),
                  ),
                  _NavItem(
                    icon: Icons.account_balance_wallet_outlined,
                    activeIcon: Icons.account_balance_wallet,
                    label: 'Wallet',
                    isSelected: navigationShell.currentIndex == 2,
                    onTap: () => _goBranch(2, context),
                  ),
                  _NavItem(
                    icon: Icons.show_chart_outlined,
                    activeIcon: Icons.show_chart,
                    label: 'Simulator',
                    isSelected: false, // It's a portal now, not a tab
                    onTap: () => _goBranch(3, context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Theme.of(context).colorScheme.primary : Colors.white60;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 24),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

