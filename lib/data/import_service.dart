import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../domain/models.dart';
import '../domain/scheduler.dart';

class ImportPreview {
  ImportPreview(this.workspace, this.warnings, this.fingerprint);
  final Workspace workspace;
  final List<String> warnings;
  final String fingerprint;
}

class ImportService {
  static ImportPreview preview(String raw, String date) {
    plannedInstant(date, 0);
    if (utf8.encode(raw).length > 20 * 1024 * 1024) {
      throw const FormatException('File melebihi batas 20 MB.');
    }
    final fingerprint = sha256.convert(utf8.encode(raw)).toString();
    var json = jsonMap(jsonDecode(raw));
    if (json['format'] == 'hedge-native-backup') {
      final workspace = Workspace.fromJson(json);
      _validate(workspace);
      return ImportPreview(
        workspace.copyWith(
          routes: workspace.routes
              .map((r) => r.copyWith(alarmEnabled: false))
              .toList(),
        ),
        ['Alarm impor dinonaktifkan. Periksa tanggal sebelum mengaktifkannya.'],
        fingerprint,
      );
    }
    for (final key in ['jadwalApp_multi_v5', 'jadwalApp_v4']) {
      if (json[key] != null) {
        final value = json[key];
        json = jsonMap(value is String ? jsonDecode(value) : value);
        break;
      }
    }
    final warnings = <String>[
      'Tanggal jadwal lama ditetapkan ke $date. Alarm impor dinonaktifkan.',
    ];
    final isMulti =
        json['routes'] is List &&
        (json['routes'] as List).any(
          (r) => r is Map && r.containsKey('masterUnits'),
        );
    final source = isMulti ? json['routes'] as List : [json];
    final routes = <HedgeRoute>[];
    for (var index = 0; index < source.length; index++) {
      final value = jsonMap(source[index]);
      final id = 'legacy:${fingerprint.substring(0, 16)}:$index';
      final name =
          '${value['name'] ?? value['activeRouteName'] ?? value['lastKodeRute'] ?? 'Rute ${index + 1}'}'
              .trim();
      final units = <FleetUnit>[];
      final lookup = <String, String>{};
      final numbers = <String>{};
      final oldIds = <String>{};
      final list = value['masterUnits'];
      if (list is! List) {
        throw FormatException(
          '$name: masterUnits tidak ditemukan. Ekspor data localStorage lengkap.',
        );
      }
      for (var i = 0; i < list.length; i++) {
        final item = list[i];
        final object = item is Map ? jsonMap(item) : null;
        final number =
            '${object == null ? item : object['number'] ?? object['num'] ?? ''}'
                .trim();
        final oldId = object?['id']?.toString();
        if (number.isEmpty ||
            !numbers.add(number) ||
            (oldId != null && !oldIds.add(oldId))) {
          throw FormatException(
            '$name: identitas/nomor unit ambigu pada baris ${i + 1}; data tidak diubah.',
          );
        }
        final unit = FleetUnit(
          id: '$id:unit:$i',
          number: number,
          active: object?['active'] != false,
        );
        units.add(unit);
        lookup[number] = unit.id;
        if (oldId != null) lookup[oldId] = unit.id;
      }
      final order = <String>[];
      for (final key in value['departureOrder'] as List? ?? []) {
        final unitId = lookup[key.toString()];
        if (unitId == null) {
          warnings.add('$name: referensi urutan $key tidak dikenal.');
          continue;
        }
        if (!order.contains(unitId)) order.add(unitId);
      }
      for (final u in units.where((u) => u.active)) {
        if (!order.contains(u.id)) order.add(u.id);
      }
      final config = PlanConfig(
        start: '${value['jamMulai'] ?? '05:00'}',
        end: '${value['jamSelesai'] ?? '22:00'}',
        rounds: _int(value['ritase'], 8),
        slowFirst: value['groupOrder'] == 'slow-first',
        peakEnabled: value['peakEnabled'] == true,
        peaks: [
          for (var p = 1; p <= 2; p++)
            PeakPeriod(
              start:
                  '${value['peak${p}Start'] ?? (p == 1 ? '05:00' : '17:00')}',
              end: '${value['peak${p}End'] ?? (p == 1 ? '08:00' : '19:00')}',
              interval: _int(value['peak${p}Interval'], p == 1 ? 2 : 3),
            ),
        ],
      );
      parseMinute(config.start);
      parseMinute(config.end);
      if (parseMinute(config.end) <= parseMinute(config.start) ||
          config.rounds < 1 ||
          config.rounds > 30) {
        throw FormatException('$name: jam operasional/ritase tidak valid.');
      }
      var route = HedgeRoute(
        id: id,
        name: name,
        color: _color(value['color']),
        units: units,
        order: order,
        config: config,
        participates: value['activeInSchedule'] != false,
        alarmEnabled: false,
      );
      final snapshot = value['committedSchedule'];
      if (snapshot is Map &&
          snapshot['rows'] is List &&
          (snapshot['rows'] as List).isNotEmpty) {
        try {
          final rows = <Departure>[];
          for (final item in snapshot['rows'] as List) {
            final row = jsonMap(item);
            final number = '${row['unit']}';
            var unitId = units.where((u) => u.number == number).firstOrNull?.id;
            if (unitId == null) {
              unitId = '$id:archived:${units.length}';
              units.add(FleetUnit(id: unitId, number: number, active: false));
              warnings.add(
                '$name: unit historis $number dipertahankan sebagai nonaktif.',
              );
            }
            final minute = parseMinute('${row['jam']}');
            if (rows.isNotEmpty && minute <= rows.last.minute) {
              throw const FormatException('Waktu tidak meningkat.');
            }
            rows.add(
              Departure(
                id: '$id:snapshot:${rows.length}',
                unitId: unitId,
                unitNumber: number,
                ordinal: rows.length + 1,
                round: _int(row['ritase'], 1),
                minute: minute,
                peak: row['isPeak'] == true,
              ),
            );
          }
          final revision = ScheduleRevision(
            id: '$id:snapshot',
            routeId: id,
            date: date,
            createdAt: DateTime.now().toUtc().toIso8601String(),
            inputFingerprint: 'legacy-unverified',
            config: config,
            engineVersion: 'legacy-import',
            reason: 'import-unverified',
            departures: List.generate(
              rows.length,
              (i) => rows[i].withGap(
                i + 1 < rows.length
                    ? rows[i + 1].minute - rows[i].minute
                    : null,
              ),
            ),
          );
          route = route.copyWith(units: units, schedule: revision);
          warnings.add(
            '$name: snapshot lama dipertahankan, konfigurasi perlu diverifikasi/buat ulang.',
          );
        } catch (error) {
          warnings.add(
            '$name: snapshot ditolak ($error). Armada dan pengaturan tetap bisa diimpor; file mentah dipertahankan.',
          );
        }
      }
      routes.add(route);
    }
    if (!isMulti && json['routes'] is List) {
      warnings.add(
        'Preset rute v4 tidak diaktifkan otomatis; tinjau file mentah untuk membuat rute tambahan.',
      );
    }
    final workspace = Workspace(
      routes: routes,
      activeRouteId: routes.firstOrNull?.id,
      date: date,
    );
    _validate(workspace);
    return ImportPreview(workspace, warnings, fingerprint);
  }

  static int _int(Object? value, int fallback) => value == null
      ? fallback
      : int.tryParse('$value') ??
            (throw const FormatException('Angka tidak valid.'));
  static int _color(Object? value) =>
      int.tryParse(
        '${value ?? '#FF9800'}'.replaceFirst('#', 'ff'),
        radix: 16,
      ) ??
      0xffff9800;

  static void _validate(Workspace workspace) {
    plannedInstant(workspace.date, 0);
    if (workspace.routes.isEmpty || workspace.routes.length > 100) {
      throw const FormatException('Backup harus memuat 1–100 rute.');
    }
    final unitIds = <String>{};
    final routeIds = <String>{};
    final revisions = <String, ScheduleRevision>{
      for (final r in workspace.history) r.id: r,
    };
    for (final route in workspace.routes) {
      if (route.name.trim().isEmpty || !routeIds.add(route.id)) {
        throw const FormatException('Nama/ID rute tidak valid.');
      }
      for (final u in route.units) {
        if (!unitIds.add(u.id)) {
          throw const FormatException('ID unit duplikat.');
        }
      }
      if (route.units.map((u) => u.number).toSet().length !=
              route.units.length ||
          route.order.toSet().length != route.order.length ||
          route.order.any((id) => !route.units.any((u) => u.id == id))) {
        throw const FormatException('Armada/urutan ambigu.');
      }
      if (route.activeUnits.isNotEmpty) const Scheduler().validateRoute(route);
      if (route.schedule != null) {
        if (route.schedule!.routeId != route.id) {
          throw const FormatException('Snapshot salah rute.');
        }
        revisions[route.schedule!.id] = route.schedule!;
      }
    }
    for (final revision in revisions.values) {
      plannedInstant(revision.date, 0);
      final ids = <String>{};
      for (var i = 0; i < revision.departures.length; i++) {
        final d = revision.departures[i];
        if (!ids.add(d.id) ||
            d.ordinal != i + 1 ||
            d.round < 1 ||
            d.minute < 0 ||
            d.minute > 1439 ||
            (i > 0 && d.minute <= revision.departures[i - 1].minute) ||
            d.nextGap !=
                (i + 1 < revision.departures.length
                    ? revision.departures[i + 1].minute - d.minute
                    : null)) {
          throw const FormatException('Snapshot backup tidak konsisten.');
        }
      }
    }
    final eventIds = <String>{};
    final semanticEvents = <String>{};
    for (final event in workspace.events) {
      if (!eventIds.add(event.id) ||
          !semanticEvents.add('${event.departureId}:${event.kind}') ||
          !['departed', 'alarmAck'].contains(event.kind) ||
          !(revisions[event.revisionId]?.departures.any(
                (d) => d.id == event.departureId,
              ) ??
              false)) {
        throw const FormatException('Ledger backup tidak konsisten.');
      }
      DateTime.parse(event.at);
    }
  }
}
