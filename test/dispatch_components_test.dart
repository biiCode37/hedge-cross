import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/application/workspace_controller.dart';
import 'package:hedge_flutter/ui/design_system.dart';
import 'package:hedge_flutter/ui/dispatch_components.dart';

void main() {
  final now = DateTime.utc(2026, 10, 7, 7, 0);
  final workspace = sampleWorkspace(DateTime.utc(2026, 10, 7));
  final route = workspace.activeRoute!;
  final revision = route.schedule!;
  final departure = revision.departures.first;

  testWidgets('DepartureFocusPanel renders Live Capsule HUD elements and button', (
    tester,
  ) async {
    var dispatched = 0;
    final focus = (
      route: route,
      revision: revision,
      departure: departure,
      due: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [clockProvider.overrideWith((ref) => Stream.value(now))],
        child: MaterialApp(
          theme: hedgeTheme(Brightness.dark),
          home: Scaffold(
            body: SingleChildScrollView(
              child: DepartureFocusPanel(
                focus: focus,
                onDispatch: () => dispatched++,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('focus-unit')), findsOneWidget);
    expect(find.byKey(const ValueKey('focus-countdown')), findsOneWidget);
    expect(find.text('KEBERANGKATAN BERIKUTNYA'), findsOneWidget);
    expect(find.text('SUDAH BERANGKAT'), findsOneWidget);

    await tester.tap(find.text('SUDAH BERANGKAT'));
    await tester.pump();
    expect(dispatched, 1);

    // Debounce tap within 500ms
    await tester.tap(find.text('SUDAH BERANGKAT'));
    await tester.pump();
    expect(dispatched, 1);
  });

  testWidgets('DepartureFocusPanel shows WAKTU BERANGKAT on due status', (
    tester,
  ) async {
    final focus = (
      route: route,
      revision: revision,
      departure: departure,
      due: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [clockProvider.overrideWith((ref) => Stream.value(now))],
        child: MaterialApp(
          theme: hedgeTheme(Brightness.dark),
          home: Scaffold(body: DepartureFocusPanel(focus: focus)),
        ),
      ),
    );

    expect(find.text('WAKTU BERANGKAT'), findsOneWidget);
  });
}
