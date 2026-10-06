import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/application/notification_service.dart';
import 'package:hedge_flutter/application/workspace_controller.dart';
import 'package:hedge_flutter/data/workspace_repository.dart';
import 'package:hedge_flutter/data/export_service.dart';
import 'package:hedge_flutter/data/import_service.dart';
import 'package:hedge_flutter/domain/alarm_plan.dart';
import 'package:hedge_flutter/domain/models.dart';
import 'package:hedge_flutter/ui/app.dart';
import 'package:hedge_flutter/ui/configuration.dart';
import 'package:hedge_flutter/ui/design_system.dart';
import 'widget_test.dart' show MemoryRepository;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final workspace = sampleWorkspace(DateTime.utc(2026, 10, 5));
  final route = workspace.activeRoute!;
  final first = route.schedule!.departures.first;
  final due = plannedInstant(workspace.date, first.minute);
  test(
    'All future Android events, configurable preparation and independent stages',
    () {
      final all = buildAlarmPlan(
        workspace,
        due.subtract(const Duration(minutes: 1)),
      );
      expect(all.length, route.schedule!.departures.length * 2);
      expect(all.length, greaterThan(48));
      expect(all.first.stage, 'prep');
      expect(all.first.at, due.subtract(const Duration(seconds: 10)));
      final custom = route.copyWith(
        preparationSeconds: 35,
        alarmDuration: 25,
        alerts: const AlarmPreferences(
          banner: false,
          fullScreen: true,
          sound: false,
          vibration: false,
        ),
      );
      final plan = buildAlarmPlan(
        workspace.copyWith(routes: [custom]),
        due.subtract(const Duration(minutes: 1)),
      );
      expect(plan.first.at, due.subtract(const Duration(seconds: 35)));
      expect(plan.first.durationSeconds, 25);
      expect(plan.first.toJson()['sound'], false);
      expect(plan.first.toJson()['banner'], false);
      expect(custom.dirty, route.dirty);
      final justDue = custom.copyWith(
        alerts: const AlarmPreferences(preparation: false),
      );
      expect(
        buildAlarmPlan(
          workspace.copyWith(routes: [justDue]),
          due.subtract(const Duration(minutes: 1)),
        ).every((e) => e.stage == 'due'),
        true,
      );
      final justPrep = custom.copyWith(
        alerts: const AlarmPreferences(departure: false),
      );
      expect(
        buildAlarmPlan(
          workspace.copyWith(routes: [justPrep]),
          due.subtract(const Duration(minutes: 1)),
        ).every((e) => e.stage == 'prep'),
        true,
      );
    },
  );
  test('OFF, hidden routes and no selected presentation produce no alarms', () {
    for (final r in [
      route.copyWith(alarmEnabled: false),
      route.copyWith(participates: false),
      route.copyWith(
        alerts: const AlarmPreferences(banner: false, fullScreen: false),
      ),
    ]) {
      expect(
        buildAlarmPlan(
          workspace.copyWith(routes: [r]),
          due.subtract(const Duration(minutes: 1)),
        ),
        isEmpty,
      );
    }
  });
  test(
    'Actual suppresses prep and due; native actions are idempotent and validated',
    () {
      final action = NativeAlarmAction(
        id: 'native-event',
        routeId: route.id,
        kind: 'departed',
        departureId: first.id,
        revisionId: route.schedule!.id,
        at: due.toIso8601String(),
      );
      final changed = applyNativeAlarmActions(workspace, [action]);
      expect(changed.hasDeparted(first.id), true);
      expect(changed.hasAcknowledged(first.id), false);
      expect(applyNativeAlarmActions(changed, [action]).events.length, 1);
      expect(
        buildAlarmPlan(
          changed,
          due.subtract(const Duration(minutes: 1)),
        ).any((e) => e.departureId == first.id),
        false,
      );
      final unknown = NativeAlarmAction(
        id: 'unknown',
        routeId: route.id,
        kind: 'departed',
        departureId: 'missing',
        revisionId: 'missing',
        at: due.toIso8601String(),
      );
      expect(
        acceptedNativeAlarmActions(workspace, [
          action,
          unknown,
        ]).map((a) => a.id),
        ['native-event'],
      );
      final off = NativeAlarmAction(
        id: 'off',
        routeId: route.id,
        kind: 'disableAlarm',
        at: due.toIso8601String(),
      );
      expect(
        applyNativeAlarmActions(changed, [off]).activeRoute!.alarmEnabled,
        false,
      );
    },
  );
  test(
    'Route preference compatibility, SQLite reopen and native backup preserve settings',
    () async {
      final old = route.toJson()..remove('alerts');
      expect(HedgeRoute.fromJson(old).alerts.fullScreen, true);
      final custom = route.copyWith(
        preparationSeconds: 35,
        alarmDuration: 120,
        alerts: const AlarmPreferences(
          banner: false,
          fullScreen: true,
          preparation: false,
          sound: false,
          vibration: false,
        ),
      );
      final directory = await Directory.systemTemp.createTemp(
        'hedge-alarm-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/workspace.sqlite');
      var repo = LocalWorkspaceRepository(HedgeDatabase(NativeDatabase(file)));
      await repo.save(workspace.copyWith(routes: [custom]));
      await repo.close();
      repo = LocalWorkspaceRepository(HedgeDatabase(NativeDatabase(file)));
      final loaded = (await repo.load())!;
      expect(loaded.activeRoute!.alerts.toJson(), custom.alerts.toJson());
      expect(loaded.activeRoute!.alarmDuration, 120);
      final imported = ImportService.preview(
        utf8.decode(ExportService.backup(loaded)),
        loaded.date,
      ).workspace;
      expect(imported.activeRoute!.alerts.toJson(), custom.alerts.toJson());
      expect(imported.activeRoute!.alarmEnabled, false);
      await repo.close();
    },
  );
  test(
    'Android bridge transfers full queue and OFF even without notification permission',
    () async {
      String? payload;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(NotificationService.channel, (call) async {
            if (call.method == 'replace') payload = call.arguments as String;
            return {
              'notifications': false,
              'exact': true,
              'fullScreen': false,
              'pending': 624,
            };
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(NotificationService.channel, null),
      );
      final service = NotificationService(
        android: true,
        now: () => due.subtract(const Duration(minutes: 1)),
      )..ready = true;
      await service.reconcile(workspace);
      final data = jsonDecode(payload!) as Map;
      expect((data['events'] as List).length, greaterThan(48));
      expect(service.device.value.notifications, false);
      expect(service.status.value, contains('izin notifikasi'));
      await service.reconcile(
        workspace.copyWith(routes: [route.copyWith(alarmEnabled: false)]),
      );
      final off = jsonDecode(payload!) as Map;
      expect(off['events'], isEmpty);
      expect((off['routes'] as List).first['enabled'], false);
    },
  );
  testWidgets(
    'Alert timeout keeps feature enabled and does not record actual',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final clock = StreamController<DateTime>();
      addTearDown(clock.close);
      final repo = MemoryRepository();
      final custom = route.copyWith(
        alarmDuration: 3,
        alerts: const AlarmPreferences(preparation: false),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            repositoryProvider.overrideWithValue(repo),
            initialWorkspaceProvider.overrideWithValue(
              workspace.copyWith(routes: [custom]),
            ),
            clockProvider.overrideWith((ref) => clock.stream),
          ],
          child: const HedgeApp(),
        ),
      );
      clock.add(due);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('fullscreen-alarm')), findsOneWidget);
      expect(find.text('Sudah Berangkat'), findsOneWidget);
      clock.add(due.add(const Duration(seconds: 3)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('fullscreen-alarm')), findsNothing);
      final state = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      ).read(workspaceProvider).workspace;
      expect(state.activeRoute!.alarmEnabled, true);
      expect(state.events, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Sudah Berangkat records actual and closes both prep and due', (
    tester,
  ) async {
    final clock = StreamController<DateTime>();
    addTearDown(clock.close);
    final repo = MemoryRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          initialWorkspaceProvider.overrideWithValue(workspace),
          clockProvider.overrideWith((ref) => clock.stream),
        ],
        child: const HedgeApp(),
      ),
    );
    clock.add(due.subtract(const Duration(seconds: 10)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('fullscreen-alarm')), findsOneWidget);
    await tester.tap(find.text('Sudah Berangkat'));
    await tester.pumpAndSettle();
    expect(repo.value!.hasDeparted(first.id), true);
    clock.add(due);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('fullscreen-alarm')), findsNothing);
    expect(repo.value!.events.length, 1);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'Configuration saves alarm controls without rebuilding schedule',
    (tester) async {
      HedgeRoute? saved;
      await tester.pumpWidget(
        MaterialApp(
          theme: hedgeTheme(Brightness.dark),
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () async {
                  saved = await showModalBottomSheet<HedgeRoute>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => ConfigurationSheet(route: route),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final scroll = find
          .descendant(
            of: find.byType(ConfigurationSheet),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Tutup alert otomatis setelah (detik)'),
        250,
        scrollable: scroll,
      );
      await tester.enterText(
        find.ancestor(
          of: find.text('Tutup alert otomatis setelah (detik)'),
          matching: find.byType(TextFormField),
        ),
        '25',
      );
      await tester.scrollUntilVisible(
        find.text('Banner notifikasi'),
        -200,
        scrollable: scroll,
      );
      await tester.tap(
        find.widgetWithText(SwitchListTile, 'Banner notifikasi'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan pengaturan'));
      await tester.pumpAndSettle();
      expect(saved, isNotNull);
      expect(saved!.alarmDuration, 25);
      expect(saved!.alerts.banner, false);
      expect(saved!.schedule, same(route.schedule));
      expect(saved!.dirty, route.dirty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final theme in ['dark', 'light']) {
    testWidgets(
      'Full alert small screen, enlarged text, stage transition and OFF $theme',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final clock = StreamController<DateTime>();
        addTearDown(clock.close);
        final repo = MemoryRepository();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              repositoryProvider.overrideWithValue(repo),
              initialWorkspaceProvider.overrideWithValue(
                workspace.copyWith(
                  theme: theme,
                  routes: [route.copyWith(alarmDuration: 20)],
                ),
              ),
              clockProvider.overrideWith((ref) => clock.stream),
            ],
            child: const HedgeApp(),
          ),
        );
        clock.add(due.subtract(const Duration(seconds: 10)));
        await tester.pumpAndSettle();
        final alert = find.byKey(const ValueKey('fullscreen-alarm'));
        expect(alert, findsOneWidget);
        expect(tester.takeException(), isNull);
        clock.add(due);
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: alert, matching: find.text('Waktu berangkat')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Matikan alarm rute'));
        await tester.pumpAndSettle();
        expect(alert, findsNothing);
        expect(repo.value!.activeRoute!.alarmEnabled, false);
        expect(repo.value!.events, isEmpty);
        clock.add(
          plannedInstant(workspace.date, route.schedule!.departures[1].minute),
        );
        await tester.pumpAndSettle();
        expect(alert, findsNothing);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
