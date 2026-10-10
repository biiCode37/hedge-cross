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

  testWidgets('CockpitMfdNavBar renders 4 tactical MFD buttons and switches tab', (tester) async {
    var selectedIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: hedgeTheme(Brightness.dark),
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            bottomNavigationBar: CockpitMfdNavBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (idx) {
                setState(() => selectedIndex = idx);
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('01'), findsOneWidget);
    expect(find.text('Jadwal'), findsOneWidget);
    expect(find.text('02'), findsOneWidget);
    expect(find.text('Armada'), findsOneWidget);
    expect(find.text('03'), findsOneWidget);
    expect(find.text('Urutan'), findsOneWidget);
    expect(find.text('04'), findsOneWidget);
    expect(find.text('Rute'), findsOneWidget);

    await tester.tap(find.text('Armada'));
    await tester.pumpAndSettle();
    expect(selectedIndex, 1);
  });

  testWidgets('AvionicsTopBar renders title, route, live clock, and triggers callbacks', (tester) async {
    var tvTapped = false;
    var settingsTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: hedgeTheme(Brightness.dark),
        home: Scaffold(
          appBar: AvionicsTopBar(
            activeRouteName: 'JAK.118',
            timeString: '07:15:30',
            onTvBoard: () => tvTapped = true,
            onSettings: () => settingsTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('DISPATCH CONTROL'), findsOneWidget);
    expect(find.text('MIKROTRANS UTARA · JAK.118'), findsOneWidget);
    expect(find.text('ONLINE · LOKAL'), findsOneWidget);
    expect(find.text('07:15:30'), findsOneWidget);

    await tester.tap(find.byTooltip('Papan keberangkatan'));
    expect(tvTapped, isTrue);

    await tester.tap(find.byTooltip('Pengaturan & backup'));
    expect(settingsTapped, isTrue);
  });
}
