import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muscle_money/features/auth/data/auth_repository.dart';
import 'package:muscle_money/features/auth/presentation/auth_controller.dart';
import 'package:muscle_money/features/auth/presentation/sign_in_screen.dart';

class _FakeAuthController extends AuthController {
  @override
  Future<AuthUser?> build() async => null;
}

void main() {
  testWidgets('renders sign-in form and validates empty input', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FakeAuthController.new),
        ],
        child: const MaterialApp(
          home: SignInScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Muscle Money'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Password must be at least 10 characters'), findsOneWidget);
  });

}
