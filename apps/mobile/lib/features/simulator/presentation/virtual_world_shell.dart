import 'package:flutter/material.dart';

import 'portfolio_tab.dart';
import 'time_machine_tab.dart';
import 'virtual_world_transition_screen.dart';
import 'watchlist_tab.dart';

class VirtualWorldShell extends StatefulWidget {
  const VirtualWorldShell({super.key});

  @override
  State<VirtualWorldShell> createState() => _VirtualWorldShellState();
}

class _VirtualWorldShellState extends State<VirtualWorldShell> {
  int _currentIndex = 0;

  final _tabs = const [
    WatchlistTab(),
    PortfolioTab(),
    TimeMachineTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'VIRTUAL TRADING',
          style: theme.textTheme.titleMedium?.copyWith(
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const VirtualWorldTransitionScreen(isExiting: true),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _tabs[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() {
            _currentIndex = idx;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: 'Trade',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Portfolio',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'Time Machine',
          ),
        ],
      ),
    );
  }
}
