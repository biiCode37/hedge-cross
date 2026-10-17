import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/domain/models.dart';
import 'package:hedge_flutter/ui/configuration.dart';
import 'package:hedge_flutter/ui/design_system.dart';

void main() {
  testWidgets('ConfigurationSheet renders TTS template cards, presets and chips', (tester) async {
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

    // Verify chips exist
    expect(find.text('+ {rute}'), findsWidgets);
    expect(find.text('+ {unit}'), findsWidgets);
    expect(find.text('+ {detik}'), findsWidgets);

    // Tap chip + {ritase} to insert tag into prepTemplate
    final ritaseChip = find.text('+ {ritase}').first;
    await tester.tap(ritaseChip);
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
}
