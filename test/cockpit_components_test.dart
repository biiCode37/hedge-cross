import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/ui/cockpit_components.dart';
import 'package:hedge_flutter/ui/design_system.dart';

void main() {
  testWidgets('CockpitFrame renders child and title header badge', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: hedgeTheme(Brightness.dark),
        home: const Scaffold(
          body: CockpitFrame(
            title: 'DEPLOYED UNITS',
            child: Text('Unit Content'),
          ),
        ),
      ),
    );

    expect(find.text('DEPLOYED UNITS'), findsOneWidget);
    expect(find.text('Unit Content'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('CockpitStatusBadge renders status and LED indicator', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: hedgeTheme(Brightness.dark),
        home: const Scaffold(
          body: CockpitStatusBadge(
            label: 'READY · OK',
            isAmber: false,
          ),
        ),
      ),
    );

    expect(find.text('READY · OK'), findsOneWidget);
  });
}
