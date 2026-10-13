import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/ui/login_screen.dart';

void main() {
  testWidgets('LoginScreen displays HEDGE brand and Google Sign-In button', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onGoogleSignIn: () async {
            pressed = true;
          },
        ),
      ),
    );

    expect(find.text('HEDGE'), findsOneWidget);
    expect(find.text('Headway Generator'), findsOneWidget);
    expect(find.text('By Mikrotrans Utara'), findsOneWidget);
    expect(find.text('Masuk dengan Akun Google'), findsOneWidget);

    // Verify there is NO bypass button on fresh install
    expect(find.textContaining('Mode Darurat Offline'), findsNothing);

    await tester.tap(find.text('Masuk dengan Akun Google'));
    await tester.pump();
    expect(pressed, isTrue);
  });
}
