import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/ui/design_system.dart';
import 'package:hedge_flutter/ui/telemetry_bar.dart';

void main() {
  testWidgets(
    'FleetTelemetryPillBar displays fleet, round, and headway metrics in dark and light mode',
    (tester) async {
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: hedgeTheme(brightness),
            home: const Scaffold(
              body: FleetTelemetryPillBar(
                activeUnits: 39,
                currentRound: 3,
                totalRounds: 8,
                headwayMinutes: 3,
              ),
            ),
          ),
        );
        expect(find.text('39 Unit Aktif'), findsOneWidget);
        expect(find.text('Ritase 3/8'), findsOneWidget);
        expect(find.text('Headway 3m'), findsOneWidget);
      }
    },
  );

  testWidgets(
    'FleetTelemetryPillBar renders horizontally on narrow screens without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: hedgeTheme(Brightness.dark),
          home: const Scaffold(
            body: FleetTelemetryPillBar(
              activeUnits: 39,
              currentRound: 3,
              totalRounds: 8,
              headwayMinutes: 3,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('39 Unit Aktif'), findsOneWidget);
    },
  );
}
