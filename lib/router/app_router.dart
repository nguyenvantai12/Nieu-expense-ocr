import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/expense_list/screens/expense_list_screen.dart';
import '../features/expense_list/screens/expense_detail_screen.dart';
import '../features/reports/screens/reports_screen.dart';
import '../features/scan_flow/screens/scan_flow_screen.dart';
import '../features/scan_flow/screens/review_screen.dart';
import '../features/settings/screens/settings_screen.dart';

/// Shell widget for bottom navigation.
class _ShellScaffold extends StatelessWidget {
  final Widget child;
  final StatefulNavigationShell navigationShell;

  const _ShellScaffold({required this.child, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/scan'),
        icon: const Icon(Icons.camera_alt),
        label: const Text('Quét'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long),
            label: 'Chi tiêu',
          ),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Báo cáo'),
        ],
      ),
    );
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/expenses',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return _ShellScaffold(
          navigationShell: navigationShell,
          child: navigationShell,
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/expenses',
              builder: (context, state) => const ExpenseListScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => ExpenseDetailScreen(
                    expenseId:
                        int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reports',
              builder: (context, state) => const ReportsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(path: '/scan', builder: (context, state) => const ScanFlowScreen()),
    GoRoute(
      path: '/scan/review',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const ReviewScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
