import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/application/workspace_controller.dart';
import 'package:hedge_flutter/data/workspace_repository.dart';
import 'package:hedge_flutter/domain/models.dart';
import 'package:hedge_flutter/ui/alarm_overlay.dart';
import 'package:hedge_flutter/ui/configuration.dart';
import 'package:hedge_flutter/ui/design_system.dart';

class TestWorkspaceRepository implements WorkspaceRepository {
  Workspace? stored;
  @override
  Future<Workspace?> load() async => stored;
  @override
  Future<void> save(Workspace workspace) async {
    stored = workspace;
  }
  @override
  Future<void> close() async {}
}

void main() {
  testWidgets('ConfigurationSheet renders TTS template cards, presets and {pramudi} chip', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final route = HedgeRoute(
      id: 'test-route',
      name: 'JAK.115',
      color: 0xFF00E5FF,
      units: const [FleetUnit(id: '1', number: '1865', active: true)],
      order: const ['1'],
      alarmEnabled: true,
      alerts: const AlarmPreferences(
        sound: true,
        prepTemplate: '{rute} unit {unit}, {detik} detik lagi.',
        dueTemplate: '{rute} unit {unit}, saatnya berangkat.',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: hedgeTheme(Brightness.dark),
        home: Scaffold(
          body: ConfigurationSheet(route: route),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to DISPATCH ALARM tab (index 2)
    final alarmTab = find.text('DISPATCH ALARM');
    expect(alarmTab, findsOneWidget);
    await tester.tap(alarmTab);
    await tester.pumpAndSettle();

    // Verify section header exists
    expect(find.text('FORMAT KALIMAT SUARA TTS'), findsOneWidget);

    // Verify chips exist including + {pramudi}
    expect(find.text('+ {rute}'), findsWidgets);
    expect(find.text('+ {unit}'), findsWidgets);
    expect(find.text('+ {pramudi}'), findsWidgets);
    expect(find.text('+ {detik}'), findsWidgets);

    // Tap chip + {pramudi} to insert tag into prepTemplate
    final pramudiChip = find.text('+ {pramudi}').first;
    await tester.tap(pramudiChip);
    await tester.pumpAndSettle();

    // Verify Uji Suara button exists
    expect(find.text('Uji Suara'), findsOneWidget);

    // Select preset 'super_singkat'
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Super Singkat (Pos Pantau Cepat)').last);
    await tester.pumpAndSettle();

    // Verify field updated
    expect(find.text('{rute} {unit}, {detik} detik.'), findsOneWidget);
  });

  testWidgets('ForegroundAlarmOverlay displays PRAMUDI: [CALLNAME] when alarm active', (tester) async {
    final repo = TestWorkspaceRepository();
    const departureTime = 7 * 60; // 07:00 (420 minutes)
    final triggerTime = plannedInstant('2026-10-18', departureTime);

    const departure = Departure(
      id: 'dep-1',
      unitId: 'u-1',
      unitNumber: '540',
      ordinal: 1,
      round: 1,
      minute: departureTime,
      peak: false,
      driverName: 'Bambang',
    );

    final schedule = ScheduleRevision(
      id: 'rev-1',
      routeId: 'r-1',
      date: '2026-10-18',
      createdAt: '2026-10-18T05:00:00Z',
      inputFingerprint: 'fp-1',
      config: const PlanConfig(),
      departures: const [departure],
    );

    final route = HedgeRoute(
      id: 'r-1',
      name: 'JAK.115',
      color: 0xFF00E5FF,
      units: const [FleetUnit(id: 'u-1', number: '540', active: true)],
      order: const ['u-1'],
      schedule: schedule,
      alarmEnabled: true,
      alerts: const AlarmPreferences(fullScreen: true, sound: true),
    );

    final workspace = Workspace(
      routes: [route],
      activeRouteId: 'r-1',
      date: '2026-10-18',
      theme: 'dark',
    );
    repo.stored = workspace;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          initialWorkspaceProvider.overrideWithValue(workspace),
          clockProvider.overrideWith((ref) => Stream.value(triggerTime)),
        ],
        child: MaterialApp(
          theme: hedgeTheme(Brightness.dark),
          home: const Scaffold(
            body: Stack(
              children: [
                ForegroundAlarmOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Verifikasi HUD menampilkan nama unit dan supir
    expect(find.text('540'), findsOneWidget);
    expect(find.text('PRAMUDI: BAMBANG'), findsOneWidget);
  });
}
