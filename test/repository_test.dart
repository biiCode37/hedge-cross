import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hedge_flutter/application/workspace_controller.dart';
import 'package:hedge_flutter/data/workspace_repository.dart';
import 'package:hedge_flutter/data/import_service.dart';
import 'package:hedge_flutter/data/export_service.dart';
import 'package:hedge_flutter/domain/models.dart';
import 'package:hedge_flutter/domain/scheduler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'SQLite survives close/reopen with revisions and actual ledger',
    () async {
      final directory = await Directory.systemTemp.createTemp('hedge-test-');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/workspace.sqlite');
      var repository = LocalWorkspaceRepository(
        HedgeDatabase(NativeDatabase(file)),
      );
      expect(await repository.load(), isNull);
      var workspace = sampleWorkspace(DateTime.utc(2026, 10, 5));
      final first = workspace.activeRoute!.schedule!;
      workspace = workspace.copyWith(
        events: [
          DispatchEvent(
            id: 'actual',
            departureId: first.departures.first.id,
            revisionId: first.id,
            kind: 'departed',
            at: DateTime.utc(2026, 10, 5).toIso8601String(),
          ),
        ],
      );
      await repository.save(workspace);
      final next = const Scheduler().generate(
        workspace.activeRoute!,
        date: workspace.date,
        revisionId: 'second',
        createdAt: DateTime.utc(2026, 10, 5),
      );
      workspace = workspace.copyWith(
        routes: [workspace.activeRoute!.copyWith(schedule: next)],
        history: [first],
      );
      await repository.save(workspace);
      await repository.save(workspace);
      await repository.close();
      repository = LocalWorkspaceRepository(
        HedgeDatabase(NativeDatabase(file)),
      );
      final restored = (await repository.load())!;
      expect(restored.activeRoute!.schedule!.id, 'second');
      expect(restored.history.length, 2);
      expect(restored.events.length, 1);
      expect(restored.hasDeparted(first.departures.first.id), true);
      final imported = ImportService.preview(
        utf8.decode(ExportService.backup(restored)),
        restored.date,
      );
      expect(imported.workspace.history.length, 2);
      expect(imported.workspace.events.length, 1);
      expect(imported.workspace.activeRoute!.alarmEnabled, false);
      await repository.close();
    },
  );
  test(
    'Failed transaction leaves previous roster and revision intact',
    () async {
      final repository = LocalWorkspaceRepository(
        HedgeDatabase(NativeDatabase.memory()),
      );
      addTearDown(repository.close);
      final original = sampleWorkspace(DateTime.utc(2026, 10, 5));
      await repository.save(original);
      final route = original.activeRoute!;
      final invalid = original.copyWith(
        routes: [
          route.copyWith(
            units: [
              ...route.units,
              const FleetUnit(id: 'duplicate', number: '1000'),
            ],
          ),
        ],
      );
      await expectLater(repository.save(invalid), throwsException);
      final restored = (await repository.load())!;
      expect(restored.activeRoute!.units.length, 39);
      expect(restored.activeRoute!.schedule!.id, route.schedule!.id);
      final outbox = await repository.db
          .customSelect('SELECT COUNT(*) AS count FROM outbox')
          .getSingle();
      expect(outbox.read<int>('count'), 1);
    },
  );
  test(
    'Import deterministic IDs, invalid snapshot quarantine and duplicate rejection',
    () {
      final raw = jsonEncode({
        'routes': [
          {
            'id': 'web-route',
            'name': 'R',
            'masterUnits': [
              {'id': 'u', 'number': '007', 'active': true},
            ],
            'departureOrder': ['u'],
            'jamMulai': '05:00',
            'jamSelesai': '05:20',
            'ritase': 2,
            'committedSchedule': {
              'rows': [
                {'unit': '007', 'jam': '05:10', 'ritase': 1},
                {'unit': '007', 'jam': '05:00', 'ritase': 2},
              ],
            },
          },
        ],
      });
      final a = ImportService.preview(raw, '2026-10-05');
      final b = ImportService.preview(raw, '2026-10-05');
      expect(a.workspace.activeRoute!.id, b.workspace.activeRoute!.id);
      expect(a.workspace.activeRoute!.units.single.number, '007');
      expect(a.workspace.activeRoute!.schedule, isNull);
      expect(a.warnings.any((w) => w.contains('snapshot ditolak')), true);
      expect(
        () => ImportService.preview('{bad', '2026-10-05'),
        throwsFormatException,
      );
      expect(
        () => ImportService.preview(
          jsonEncode({
            'masterUnits': [
              {'number': '7'},
              {'number': '7'},
            ],
          }),
          '2026-10-05',
        ),
        throwsFormatException,
      );
    },
  );
  test('Exports use committed rows and safe unique XLSX names', () async {
    final workspace = sampleWorkspace(DateTime.utc(2026, 10, 5));
    final r = workspace.activeRoute!;
    final draft = r.copyWith(
      config: const PlanConfig(start: '06:00', end: '20:00', rounds: 4),
    );
    final text = ExportService.text(draft, shift: '2 (Siang)', firstRound: 4);
    expect(text, contains('05:00 | Unit 1000 | R4'));
    expect(text, contains('Shift 2 (Siang)'));
    expect(text, contains('belum diterapkan'));
    final bytes = ExportService.xlsx([
      r.copyWith(name: 'A/B'),
      r.copyWith(name: 'A:B'),
    ]);
    expect(bytes.take(2), [80, 75]);
    final pdf = await ExportService.pdf(r);
    expect(utf8.decode(pdf.take(4).toList()), '%PDF');
  });
}
