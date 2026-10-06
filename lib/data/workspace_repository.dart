import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../domain/models.dart';

abstract interface class WorkspaceRepository {
  Future<Workspace?> load();
  Future<void> save(Workspace workspace);
  Future<void> close();
}

class HedgeDatabase extends GeneratedDatabase {
  HedgeDatabase(super.executor);
  @override
  int get schemaVersion => 1;
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      for (final statement in _schema) {
        await customStatement(statement);
      }
    },
    onUpgrade: (m, from, to) async =>
        throw StateError('Versi database $from → $to belum didukung.'),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
  static const _schema = [
    'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
    'CREATE TABLE routes (id TEXT PRIMARY KEY, position INTEGER NOT NULL, config TEXT NOT NULL, current_revision TEXT)',
    'CREATE TABLE units (id TEXT PRIMARY KEY, route_id TEXT NOT NULL REFERENCES routes(id) ON DELETE CASCADE, number TEXT NOT NULL, active INTEGER NOT NULL CHECK(active IN (0,1)), position INTEGER NOT NULL, UNIQUE(route_id, number))',
    'CREATE TABLE revisions (id TEXT PRIMARY KEY, route_id TEXT NOT NULL, service_date TEXT NOT NULL, metadata TEXT NOT NULL)',
    'CREATE TABLE departures (revision_id TEXT NOT NULL REFERENCES revisions(id), id TEXT NOT NULL, ordinal INTEGER NOT NULL, unit_id TEXT NOT NULL, number TEXT NOT NULL, minute INTEGER NOT NULL, round INTEGER NOT NULL, peak INTEGER NOT NULL, gap INTEGER, PRIMARY KEY(revision_id,id), UNIQUE(revision_id,ordinal))',
    'CREATE INDEX departures_time ON departures(revision_id,minute,ordinal)',
    'CREATE TABLE dispatch_events (id TEXT PRIMARY KEY, departure_id TEXT NOT NULL, revision_id TEXT NOT NULL REFERENCES revisions(id), kind TEXT NOT NULL CHECK(kind IN (\'departed\',\'alarmAck\')), occurred_at TEXT NOT NULL, UNIQUE(departure_id,kind))',
    'CREATE TABLE outbox (id INTEGER PRIMARY KEY AUTOINCREMENT, aggregate_id TEXT NOT NULL, kind TEXT NOT NULL, payload TEXT NOT NULL, created_at TEXT NOT NULL, status TEXT NOT NULL DEFAULT \'local-only\')',
    'CREATE TABLE import_runs (fingerprint TEXT PRIMARY KEY, imported_at TEXT NOT NULL)',
  ];
}

class LocalWorkspaceRepository implements WorkspaceRepository {
  LocalWorkspaceRepository(this.db);
  final HedgeDatabase db;
  static Future<LocalWorkspaceRepository> open() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    return LocalWorkspaceRepository(
      HedgeDatabase(
        NativeDatabase.createInBackground(
          File(p.join(directory.path, 'hedge_v2.sqlite')),
          setup: (database) => database.execute('PRAGMA journal_mode = WAL;'),
        ),
      ),
    );
  }

  @override
  Future<Workspace?> load() async {
    final settingRows = await db
        .customSelect('SELECT key,value FROM settings')
        .get();
    final settings = {
      for (final row in settingRows)
        row.read<String>('key'): row.read<String>('value'),
    };
    if (settings['initialized'] != '1') return null;
    final rows = await db
        .customSelect('SELECT * FROM routes ORDER BY position')
        .get();
    final routes = <HedgeRoute>[];
    for (final row in rows) {
      final id = row.read<String>('id');
      final json = jsonMap(jsonDecode(row.read<String>('config')));
      final unitRows = await db
          .customSelect(
            'SELECT * FROM units WHERE route_id=? ORDER BY position',
            variables: [Variable.withString(id)],
          )
          .get();
      json['units'] = unitRows
          .map(
            (u) => {
              'id': u.read<String>('id'),
              'number': u.read<String>('number'),
              'active': u.read<int>('active') == 1,
            },
          )
          .toList();
      final revisionId = row.readNullable<String>('current_revision');
      if (revisionId != null) {
        final rev = await db
            .customSelect(
              'SELECT metadata FROM revisions WHERE id=?',
              variables: [Variable.withString(revisionId)],
            )
            .getSingle();
        final snapshot = jsonMap(jsonDecode(rev.read<String>('metadata')));
        final departures = await db
            .customSelect(
              'SELECT * FROM departures WHERE revision_id=? ORDER BY ordinal',
              variables: [Variable.withString(revisionId)],
            )
            .get();
        snapshot['departures'] = departures
            .map(
              (d) => {
                'id': d.read<String>('id'),
                'unitId': d.read<String>('unit_id'),
                'unitNumber': d.read<String>('number'),
                'ordinal': d.read<int>('ordinal'),
                'round': d.read<int>('round'),
                'minute': d.read<int>('minute'),
                'peak': d.read<int>('peak') == 1,
                'nextGap': d.readNullable<int>('gap'),
              },
            )
            .toList();
        json['schedule'] = snapshot;
      }
      routes.add(HedgeRoute.fromJson(json));
    }
    final events = await db
        .customSelect('SELECT * FROM dispatch_events ORDER BY occurred_at,id')
        .get();
    final historical = await db
        .customSelect('SELECT id,metadata FROM revisions ORDER BY rowid')
        .get();
    final history = <ScheduleRevision>[];
    for (final revision in historical) {
      final json = jsonMap(jsonDecode(revision.read<String>('metadata')));
      final rows = await db
          .customSelect(
            'SELECT * FROM departures WHERE revision_id=? ORDER BY ordinal',
            variables: [Variable.withString(revision.read<String>('id'))],
          )
          .get();
      json['departures'] = rows
          .map(
            (d) => {
              'id': d.read<String>('id'),
              'unitId': d.read<String>('unit_id'),
              'unitNumber': d.read<String>('number'),
              'ordinal': d.read<int>('ordinal'),
              'round': d.read<int>('round'),
              'minute': d.read<int>('minute'),
              'peak': d.read<int>('peak') == 1,
              'nextGap': d.readNullable<int>('gap'),
            },
          )
          .toList();
      history.add(ScheduleRevision.fromJson(json));
    }
    return Workspace(
      routes: routes,
      history: history,
      activeRouteId: settings['activeRouteId'],
      date: settings['date'] ?? serviceDate(DateTime.now()),
      theme: settings['theme'] ?? 'dark',
      events: events
          .map(
            (e) => DispatchEvent(
              id: e.read<String>('id'),
              departureId: e.read<String>('departure_id'),
              revisionId: e.read<String>('revision_id'),
              kind: e.read<String>('kind'),
              at: e.read<String>('occurred_at'),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> save(Workspace workspace) => db.transaction(() async {
    final existing = await db.customSelect('SELECT id FROM routes').get();
    for (final row in existing) {
      final id = row.read<String>('id');
      if (!workspace.routes.any((r) => r.id == id)) {
        await db.customStatement('DELETE FROM routes WHERE id=?', [id]);
      }
    }
    for (var index = 0; index < workspace.routes.length; index++) {
      final route = workspace.routes[index];
      final config = route.toJson(includeSchedule: false)..remove('units');
      await db.customStatement(
        'INSERT INTO routes(id,position,config,current_revision) VALUES(?,?,?,?) ON CONFLICT(id) DO UPDATE SET position=excluded.position, config=excluded.config, current_revision=excluded.current_revision',
        [route.id, index, jsonEncode(config), route.schedule?.id],
      );
      await db.customStatement('DELETE FROM units WHERE route_id=?', [
        route.id,
      ]);
      for (var i = 0; i < route.units.length; i++) {
        final unit = route.units[i];
        await db.customStatement(
          'INSERT INTO units(id,route_id,number,active,position) VALUES(?,?,?,?,?)',
          [unit.id, route.id, unit.number, unit.active ? 1 : 0, i],
        );
      }
    }
    final revisions = {
      for (final r in workspace.history) r.id: r,
      for (final route in workspace.routes)
        if (route.schedule != null) route.schedule!.id: route.schedule!,
    };
    for (final revision in revisions.values) {
      {
        final exists = await db
            .customSelect(
              'SELECT id FROM revisions WHERE id=?',
              variables: [Variable.withString(revision.id)],
            )
            .get();
        if (exists.isEmpty) {
          await db.customStatement(
            'INSERT INTO revisions(id,route_id,service_date,metadata) VALUES(?,?,?,?)',
            [
              revision.id,
              revision.routeId,
              revision.date,
              jsonEncode(revision.toJson(includeRows: false)),
            ],
          );
          for (final d in revision.departures) {
            await db.customStatement(
              'INSERT INTO departures(revision_id,id,ordinal,unit_id,number,minute,round,peak,gap) VALUES(?,?,?,?,?,?,?,?,?)',
              [
                revision.id,
                d.id,
                d.ordinal,
                d.unitId,
                d.unitNumber,
                d.minute,
                d.round,
                d.peak ? 1 : 0,
                d.nextGap,
              ],
            );
          }
          await db.customStatement(
            'INSERT INTO outbox(aggregate_id,kind,payload,created_at) VALUES(?,?,?,?)',
            [
              revision.routeId,
              'scheduleRevision',
              jsonEncode(revision.toJson()),
              revision.createdAt,
            ],
          );
        }
      }
    }
    for (final event in workspace.events) {
      final exists = await db
          .customSelect(
            'SELECT id FROM dispatch_events WHERE departure_id=? AND kind=?',
            variables: [
              Variable.withString(event.departureId),
              Variable.withString(event.kind),
            ],
          )
          .get();
      if (exists.isEmpty) {
        await db.customStatement(
          'INSERT INTO dispatch_events(id,departure_id,revision_id,kind,occurred_at) VALUES(?,?,?,?,?)',
          [event.id, event.departureId, event.revisionId, event.kind, event.at],
        );
        await db.customStatement(
          'INSERT INTO outbox(aggregate_id,kind,payload,created_at) VALUES(?,?,?,?)',
          [event.departureId, event.kind, jsonEncode(event.toJson()), event.at],
        );
      }
    }
    final settings = {
      'initialized': '1',
      'activeRouteId': workspace.activeRouteId ?? '',
      'date': workspace.date,
      'theme': workspace.theme,
    };
    for (final entry in settings.entries) {
      await db.customStatement(
        'INSERT INTO settings(key,value) VALUES(?,?) ON CONFLICT(key) DO UPDATE SET value=excluded.value',
        [entry.key, entry.value],
      );
    }
  });

  @override
  Future<void> close() => db.close();
}
