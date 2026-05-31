import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muscle_money/features/dashboard/presentation/dashboard_screen.dart';
import 'package:muscle_money/features/dashboard/data/dashboard_repository.dart';

void main() {
  testWidgets('Dashboard displays Action Cards', (WidgetTester tester) async {
    // Provide mock data
    final mockRepository = MockDashboardRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );

    // Initial loading state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Let the FutureProvider complete
    await tester.pumpAndSettle();

    // Verify Action Cards are present
    expect(find.text('Today\'s Mission'), findsOneWidget);
    expect(find.text('Wallet Action'), findsOneWidget);
    expect(find.text('Simulator Challenge'), findsOneWidget);
    expect(find.text('Your Progress'), findsOneWidget);
  });
}
