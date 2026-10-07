import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/domain/models.dart';
import 'package:hedge_flutter/ui/design_system.dart';
import 'package:hedge_flutter/ui/schedule_timeline.dart';

void main() {
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

  testWidgets('CyberTimelineTile renders unit, time, and round info', (
    tester,
  ) async {
    var recorded = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: hedgeTheme(Brightness.dark),
        home: Scaffold(
          body: CyberTimelineTile(
            departure: departure,
            done: false,
            focused: false,
            frozen: false,
            isFirst: true,
            isLast: false,
            onRecord: () => recorded = true,
          ),
        ),
      ),
    );

    expect(find.text('1865'), findsOneWidget);
    expect(find.text('07:00'), findsOneWidget);
    expect(find.text('R1 · 3m'), findsOneWidget);
    expect(find.text('PEAK'), findsOneWidget);

    await tester.tap(find.byTooltip('Catat keberangkatan aktual'));
    await tester.pump();
    expect(recorded, isTrue);
  });

  testWidgets('CyberTimelineTile shows AKTIF badge when focused', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: hedgeTheme(Brightness.dark),
        home: Scaffold(
          body: CyberTimelineTile(
            departure: departure,
            done: false,
            focused: true,
            frozen: false,
            isFirst: false,
            isLast: false,
            onRecord: () {},
          ),
        ),
      ),
    );

    expect(find.text('AKTIF'), findsOneWidget);
  });

  testWidgets('CyberTimelineTile shows checkmark semantics when departed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: hedgeTheme(Brightness.dark),
        home: Scaffold(
          body: CyberTimelineTile(
            departure: departure,
            done: true,
            focused: false,
            frozen: false,
            isFirst: false,
            isLast: true,
            onRecord: () {},
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Keberangkatan aktual tercatat'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('CyberTimelineList renders list of departures with transit rail', (
    tester,
  ) async {
    final departures = <Departure>[
      departure,
      Departure(
        id: 'dep-2',
        ordinal: 2,
        unitId: 'u-1870',
        unitNumber: '1870',
        minute: 423,
        round: 1,
        peak: true,
        nextGap: 3,
      ),
      Departure(
        id: 'dep-3',
        ordinal: 3,
        unitId: 'u-1875',
        unitNumber: '1875',
        minute: 426,
        round: 1,
        peak: true,
        nextGap: 3,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: hedgeTheme(Brightness.dark),
        home: Scaffold(
          body: CyberTimelineList(
            departures: departures,
            hasDeparted: (id) => id == 'dep-1',
            focusedDepartureId: 'dep-2',
            frozenCount: 0,
            onRecord: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('1865'), findsOneWidget);
    expect(find.text('1870'), findsOneWidget);
    expect(find.text('1875'), findsOneWidget);
    expect(find.text('AKTIF'), findsOneWidget);
  });
}
