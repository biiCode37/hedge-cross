import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/application/workspace_controller.dart';
import 'package:hedge_flutter/domain/models.dart';
import 'package:hedge_flutter/ui/app.dart';
import 'package:hedge_flutter/ui/design_system.dart';

void main() {
  final route = HedgeRoute(
    id: 'r-1',
    name: 'JAK.115',
    color: 0xFF00E5FF,
    units: const [],
    order: const [],
  );

  final departure = Departure(
    id: 'dep-1',
    ordinal: 1,
    unitId: 'u-1865',
    unitNumber: '1865',
    minute: 420, // 07:00
    round: 1,
    peak: true,
    nextGap: 3,
  );

  testWidgets('CyberBoardTimelineTile renders unit, route, round, and countdown', (
    tester,
  ) async {
    final targetTime = DateTime.utc(2026, 10, 7, 7, 5, 0);
    final clockController = StreamController<DateTime>();
    addTearDown(clockController.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockProvider.overrideWith((ref) => clockController.stream),
        ],
        child: MaterialApp(
          theme: hedgeTheme(Brightness.dark),
          home: Scaffold(
            body: CyberBoardTimelineTile(
              route: route,
              departure: departure,
              at: targetTime,
              isFocused: true,
              isFirst: true,
              isLast: false,
            ),
          ),
        ),
      ),
    );

    clockController.add(DateTime.utc(2026, 10, 7, 7, 3, 30)); // 1m30s remaining
    await tester.pumpAndSettle();

    expect(find.text('1865'), findsOneWidget);
    expect(find.text('07:00'), findsOneWidget);
    expect(find.text('JAK.115'), findsOneWidget);
    expect(find.text('R1'), findsOneWidget);
    expect(find.text('PEAK'), findsOneWidget);
    expect(find.text('AKTIF'), findsOneWidget);
    expect(find.text('01:30'), findsOneWidget);
  });

  testWidgets('CyberBoardTimelineTile adapts status between STANDBY, BERSIAP, and BOARDING', (
    tester,
  ) async {
    final targetTime = DateTime.utc(2026, 10, 7, 7, 5, 0);
    final clockController = StreamController<DateTime>();
    addTearDown(clockController.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockProvider.overrideWith((ref) => clockController.stream),
        ],
        child: MaterialApp(
          theme: hedgeTheme(Brightness.dark),
          home: Scaffold(
            body: CyberBoardTimelineTile(
              route: route,
              departure: departure,
              at: targetTime,
              isFocused: false,
              isFirst: false,
              isLast: true,
            ),
          ),
        ),
      ),
    );

    // 1. STANDBY (> 60s remaining)
    clockController.add(DateTime.utc(2026, 10, 7, 7, 3, 0)); // 2m remaining
    await tester.pumpAndSettle();
    expect(find.text('STANDBY'), findsOneWidget);

    // 2. BERSIAP (<= 60s remaining)
    clockController.add(DateTime.utc(2026, 10, 7, 7, 4, 30)); // 30s remaining
    await tester.pumpAndSettle();
    expect(find.text('BERSIAP'), findsOneWidget);

    // 3. BOARDING (<= 0s remaining)
    clockController.add(DateTime.utc(2026, 10, 7, 7, 5, 10)); // Overdue
    await tester.pumpAndSettle();
    expect(find.text('BOARDING'), findsOneWidget);
    expect(find.text('WAKTU TIBA'), findsOneWidget);
  });

  for (final brightness in [Brightness.dark, Brightness.light]) {
    testWidgets('CyberBoardTimelineTile renders on 320px narrow screen without overflow (${brightness.name})', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final clockController = StreamController<DateTime>();
      addTearDown(clockController.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clockProvider.overrideWith((ref) => clockController.stream),
          ],
          child: MaterialApp(
            theme: hedgeTheme(brightness),
            home: Scaffold(
              body: CyberBoardTimelineTile(
                route: route,
                departure: departure,
                at: DateTime.utc(2026, 10, 7, 7, 5, 0),
                isFocused: true,
                isFirst: true,
                isLast: true,
              ),
            ),
          ),
        ),
      );

      clockController.add(DateTime.utc(2026, 10, 7, 7, 4, 0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
