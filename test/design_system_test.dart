import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/application/dispatch_focus.dart';
import 'package:hedge_flutter/application/workspace_controller.dart';
import 'package:hedge_flutter/domain/models.dart';
import 'package:hedge_flutter/ui/app.dart';
import 'package:hedge_flutter/ui/design_system.dart';
import 'package:hedge_flutter/ui/dispatch_components.dart';
import 'widget_test.dart' show MemoryRepository;

double contrast(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  return ((l1 > l2 ? l1 : l2) + .05) / ((l1 > l2 ? l2 : l1) + .05);
}

Widget appFor(
  Workspace workspace,
  Stream<DateTime> clock, {
  double scale = 1,
}) => ProviderScope(
  overrides: [
    initialWorkspaceProvider.overrideWithValue(workspace),
    repositoryProvider.overrideWithValue(MemoryRepository()),
    clockProvider.overrideWith((ref) => clock),
  ],
  child: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: const HedgeApp(),
  ),
);
void main() {
  for (final p in [HedgePalette.dark, HedgePalette.light]) {
    test(
      'Readable design system ${p == HedgePalette.dark ? 'dark' : 'light'}',
      () {
        for (final pair in [
          (p.text, p.surface),
          (p.text, p.background),
          (p.muted, p.surface),
          (p.muted, p.raised),
          (p.cyanInk, p.surface),
          (p.cyanInk, p.focusSurface),
          (p.amberInk, p.surface),
          (p.amberInk, p.warningSurface),
          (p.success, p.surface),
          (p.danger, p.surface),
          (HedgeTokens.obsidian, HedgeTokens.amber),
        ]) {
          expect(
            contrast(pair.$1, pair.$2),
            greaterThanOrEqualTo(4.5),
            reason: '${pair.$1} on ${pair.$2}',
          );
        }
      },
    );
  }
  test(
    'Focus remains stable across ticks and uses due hold without implying actual',
    () {
      final workspace = sampleWorkspace(DateTime.utc(2026, 10, 5));
      final route = workspace.activeRoute!;
      final revision = route.schedule!;
      final row = revision.departures[1];
      final at = plannedInstant(revision.date, row.minute);
      final a = selectDispatchFocus(
        workspace,
        at.subtract(const Duration(seconds: 100)),
        routeId: route.id,
      )!;
      final b = selectDispatchFocus(
        workspace,
        at.subtract(const Duration(seconds: 99)),
        routeId: route.id,
      )!;
      expect(a, b);
      expect(a.departure.id, row.id);
      expect(a.due, false);
      final due = selectDispatchFocus(
        workspace,
        at.add(const Duration(seconds: 1)),
        routeId: route.id,
      )!;
      expect(due.departure.id, row.id);
      expect(due.due, true);
      expect(workspace.hasDeparted(row.id), false);
      final next = selectDispatchFocus(
        workspace,
        at.add(Duration(seconds: route.alarmDuration)),
        routeId: route.id,
      )!;
      expect(next.departure.id, revision.departures[2].id);
      final actual = workspace.copyWith(
        events: [
          DispatchEvent(
            id: 'actual',
            departureId: row.id,
            revisionId: revision.id,
            kind: 'departed',
            at: at.toIso8601String(),
          ),
        ],
      );
      expect(
        selectDispatchFocus(actual, at, routeId: route.id)!.departure.id,
        revision.departures[2].id,
      );
      final ack = workspace.copyWith(
        events: [
          DispatchEvent(
            id: 'ack',
            departureId: row.id,
            revisionId: revision.id,
            kind: 'alarmAck',
            at: at.toIso8601String(),
          ),
        ],
      );
      expect(
        selectDispatchFocus(ack, at, routeId: route.id)!.departure.id,
        row.id,
      );
    },
  );
  test(
    'Countdown preserves sub-second future, hour display and clamps overdue',
    () {
      expect(formatCountdown(const Duration(milliseconds: 500)), '00:01');
      expect(formatCountdown(const Duration(hours: 1, seconds: 5)), '01:00:05');
      expect(formatCountdown(const Duration(seconds: -2)), '00:00');
    },
  );
  testWidgets(
    'Unit first, countdown second, urgency and lightweight clock rebuilds',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final clock = StreamController<DateTime>();
      addTearDown(clock.close);
      final workspace = sampleWorkspace(DateTime.utc(2026, 10, 5));
      final row = workspace.activeRoute!.schedule!.departures[1];
      final at = plannedInstant(workspace.date, row.minute);
      await tester.pumpWidget(appFor(workspace, clock.stream));
      clock.add(at.subtract(const Duration(seconds: 100)));
      await tester.pumpAndSettle();
      final unit = tester.widget<Text>(
        find.descendant(
          of: find.byType(HomeScreen),
          matching: find.byKey(const ValueKey('focus-unit')),
        ),
      );
      final timer = tester.widget<Text>(
        find.descendant(
          of: find.byType(HomeScreen),
          matching: find.byKey(const ValueKey('focus-countdown')),
        ),
      );
      expect(unit.data, row.unitNumber);
      expect(unit.style!.fontSize, 44);
      expect(timer.style!.fontSize, 28);
      expect(timer.data, '01:40');
      expect(timer.style!.color, HedgePalette.dark.cyanInk);
      final tile = find.byType(ScheduleDepartureTile).first;
      final initialTile = tester.widget(tile);
      clock.add(at.subtract(const Duration(seconds: 99)));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: find.byType(HomeScreen),
                matching: find.byKey(const ValueKey('focus-countdown')),
              ),
            )
            .data,
        '01:39',
      );
      expect(
        identical(initialTile, tester.widget(tile)),
        true,
        reason: 'Timer tick must not rebuild the schedule list.',
      );
      clock.add(at.subtract(const Duration(seconds: 60)));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: find.byType(HomeScreen),
                matching: find.byKey(const ValueKey('focus-countdown')),
              ),
            )
            .style!
            .color,
        HedgePalette.dark.amberInk,
      );
      clock.add(at);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(HomeScreen),
          matching: find.text('Waktu berangkat'),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: find.byType(HomeScreen),
                matching: find.byKey(const ValueKey('focus-unit')),
              ),
            )
            .data,
        row.unitNumber,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final theme in ['dark', 'light']) {
    testWidgets('Small screen and enlarged text $theme remain navigable', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final workspace = sampleWorkspace(
        DateTime.utc(2026, 10, 5),
      ).copyWith(theme: theme);
      await tester.pumpWidget(
        appFor(
          workspace,
          Stream.value(DateTime.utc(2026, 10, 4, 23, 58, 20)),
          scale: 1.6,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(HomeScreen),
          matching: find.byKey(const ValueKey('focus-unit')),
        ),
        findsOneWidget,
      );
      expect(
        MediaQuery.textScalerOf(
          tester.element(
            find.descendant(
              of: find.byType(HomeScreen),
              matching: find.byKey(const ValueKey('focus-unit')),
            ),
          ),
        ).scale(14),
        closeTo(22.4, .01),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Armada'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Urutan'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Rute'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Papan keberangkatan'));
      await tester.pumpAndSettle();
      expect(find.text('Papan HEDGE'), findsOneWidget);
      final boardUnit = tester.widget<Text>(
        find.byKey(const ValueKey('focus-unit')),
      );
      final boardTimer = tester.widget<Text>(
        find.byKey(const ValueKey('focus-countdown')),
      );
      expect(
        boardUnit.style!.fontSize,
        greaterThan(boardTimer.style!.fontSize!),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
